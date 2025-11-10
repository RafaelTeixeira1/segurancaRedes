#!/usr/bin/env bash
set -euo pipefail

# run_all_attacks.sh — Orquestrador robusto (PT-BR)
# - Não execute com `sudo ./run_all_attacks.sh`. Rode: `bash ./run_all_attacks.sh`
# - O script usa sudo somente onde necessário (tcpdump). Use tmux para resiliência.
# - Possui detecção automática de interface baseada no IP_VITIMA.

# -----------------------
# CONFIGURAÇÃO (edite se necessário)
# -----------------------
INTERFACE="${INTERFACE:-}"                 # Se vazio, será detectado automaticamente
IP_VITIMA="${IP_VITIMA:-192.168.56.101}"   # IP da vítima (ajuste se necessário)
USER_VITIMA="${USER_VITIMA:-linuxmint}"    # usuário alvo na vítima
WORDLIST="${WORDLIST:-wordlists/minhaLista.txt}"
EVID_ROOT="${EVID_ROOT:-evidencias}"
SLEEP_AFTER_STEP=${SLEEP_AFTER_STEP:-3}    # segundos entre etapas
REMOTE_RUN="${REMOTE_RUN:-false}"          # true|false para executar etapas 06/08 via SSH
VITIMA_PASS="${VITIMA_PASS:-linuxmint}"    # senha da vítima (só use em lab isolado)
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# -----------------------
# Ajuste do diretório de trabalho para a raiz do repositório
# -----------------------
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT" || { echo "Erro: não foi possível entrar em $REPO_ROOT"; exit 1; }

# -----------------------
# Timestamp e manifesto
# -----------------------
now() { date +%Y%m%d_%H%M%S; }
ts="$(now)"

# cria raiz de evidências com permissão restrita
mkdir -p "$EVID_ROOT"
chmod 700 "$EVID_ROOT"

manifest="$EVID_ROOT/MANIFEST_${ts}.txt"
{
  echo "Manifest for run at: $(date -u)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "IP_VITIMA=$IP_VITIMA"
  echo "USER_VITIMA=$USER_VITIMA"
  echo "WORDLIST=$WORDLIST"
  echo ""
} > "$manifest"

# -----------------------
# Detectar interface automaticamente (se INTERFACE não fornecida)
# -----------------------
if [ -z "${INTERFACE}" ]; then
  # extrai prefixo /24 do IP_VITIMA
  vip_prefix=$(printf "%s" "$IP_VITIMA" | awk -F. '{print $1"."$2"."$3}')
  # procura a interface cuja IPv4 pertença ao mesmo /24
  IFACE_DET=$(ip -o -4 addr show | awk -v pref="$vip_prefix" '
    { split($4, a, "/"); split(a[1], b, "."); prefix=b[1]"."b[2]"."b[3];
      if (prefix==pref) { print $2; exit } }
  ')
  # fallback: primeira interface não-loopback com IPv4
  if [ -z "$IFACE_DET" ]; then
    IFACE_DET=$(ip -o -4 addr show | awk '$2!~/lo/ {print $2; exit}')
  fi
  INTERFACE="${IFACE_DET:-eth0}"
  echo "[auto-detect] INTERFACE='$INTERFACE'" >> "$manifest" 2>/dev/null || true
fi

echo "[00] Início da execução. Timestamp: $ts"
echo "[00] Usando INTERFACE='$INTERFACE' IP_VITIMA='$IP_VITIMA' USER_VITIMA='$USER_VITIMA'"

# auxiliar para gravar sha256 e nota
sha256_and_note() {
  local desc="$1"; shift
  for f in "$@"; do
    if [ -e "$f" ]; then
      sha256sum "$f"
      sha256sum "$f" >> "$manifest"
      echo "FILE: $f" >> "$manifest"
      echo "DESCRIPTION: $desc" >> "$manifest"
      echo "----" >> "$manifest"
    fi
  done
}

# --------------------------
# 01 - Enumeração Nmap
# --------------------------
step1_dir="$EVID_ROOT/01_NMAP_${ts}"
mkdir -p "$step1_dir"
echo "[01/08] Executando enumeração Nmap -> $step1_dir"
if [ -x "./scripts/nmap_enum.sh" ]; then
  ./scripts/nmap_enum.sh "$IP_VITIMA" "$step1_dir" || true
else
  echo "Aviso: scripts/nmap_enum.sh não encontrado/executável" | tee -a "$manifest"
fi
sleep "$SLEEP_AFTER_STEP"
# registra arquivos do NMAP no manifesto
find "$step1_dir" -type f -maxdepth 1 -print >> "$manifest" 2>/dev/null || true
echo "" >> "$manifest"

# --------------------------
# 02 - Captura pré-ataque (pcap)
# --------------------------
pcap_pre="$EVID_ROOT/02_PRE_CAPTURE_${ts}.pcap"
echo "[02/08] Captura pré-ataque (30s) -> $pcap_pre"
if ip link show "$INTERFACE" >/dev/null 2>&1; then
  sudo timeout 30 tcpdump -i "$INTERFACE" -w "$pcap_pre" || true
  sleep "$SLEEP_AFTER_STEP"
  sha256_and_note "pre-attack capture (30s)" "$pcap_pre" >/dev/null
else
  echo "Erro: interface '$INTERFACE' não existe. Pule 02_PRE_CAPTURE." | tee -a "$manifest"
fi

# --------------------------
# 03 - SSH bruteforce (Hydra / script)
# --------------------------
step3_dir="$EVID_ROOT/03_SSH_BRUTEFORCE_${ts}"
mkdir -p "$step3_dir"
echo "[03/08] Ataque SSH (bruteforce) -> $step3_dir"
if [ -x "./scripts/ssh_bruteforce.sh" ]; then
  ./scripts/ssh_bruteforce.sh "$IP_VITIMA" "$USER_VITIMA" "$WORDLIST" "$step3_dir" 4 || true
else
  echo "Aviso: scripts/ssh_bruteforce.sh não encontrado/executável" | tee -a "$manifest"
fi
sleep "$SLEEP_AFTER_STEP"

# --------------------------
# 04 - SSH sequencial (registro detalhado)
# --------------------------
step4_dir="$EVID_ROOT/04_SSH_SEQUENTIAL_${ts}"
mkdir -p "$step4_dir"
echo "[04/08] Tentativas SSH sequenciais -> $step4_dir"
if [ -x "./scripts/ssh_try_sequential.sh" ]; then
  ./scripts/ssh_try_sequential.sh "$IP_VITIMA" "$USER_VITIMA" "$WORDLIST" "$step4_dir" 5 || true
else
  echo "Aviso: scripts/ssh_try_sequential.sh não encontrado/executável" | tee -a "$manifest"
fi
sleep "$SLEEP_AFTER_STEP"

# --------------------------
# 05 - Captura pós-ataque (pcap)
# --------------------------
pcap_post="$EVID_ROOT/05_POST_CAPTURE_${ts}.pcap"
echo "[05/08] Captura pós-ataque (30s) -> $pcap_post"
if ip link show "$INTERFACE" >/dev/null 2>&1; then
  sudo timeout 30 tcpdump -i "$INTERFACE" -w "$pcap_post" || true
  sleep "$SLEEP_AFTER_STEP"
  sha256_and_note "post-attack capture (30s)" "$pcap_post" >/dev/null
else
  echo "Erro: interface '$INTERFACE' não existe. Pule 05_POST_CAPTURE." | tee -a "$manifest"
fi

# --------------------------
# 06 - Simulação USB
# --------------------------
step6_dir="$EVID_ROOT/06_USB_SIMULATION_${ts}"
mkdir -p "$step6_dir"
echo "[06/08] Simulação USB -> $step6_dir"
if [ "$REMOTE_RUN" = "true" ]; then
  if command -v sshpass >/dev/null 2>&1; then
    echo "[06] Executando simulação USB via SSH remoto..." | tee -a "$manifest"
    sshpass -p "$VITIMA_PASS" ssh $SSH_OPTS "${USER_VITIMA}@${IP_VITIMA}" "sudo ${REPO_ROOT}/scripts/simula_usb_and_execute.sh $step6_dir" || true
  else
    echo "sshpass não instalado; execute simulação manualmente na vítima." | tee -a "$manifest"
  fi
else
  if [ -x "./scripts/simula_usb_and_execute.sh" ]; then
    ./scripts/simula_usb_and_execute.sh "$step6_dir" || true
  else
    echo "Aviso: scripts/simula_usb_and_execute.sh não encontrado/executável" | tee -a "$manifest"
  fi
fi
sleep "$SLEEP_AFTER_STEP"

# --------------------------
# 07 - Demo Web sem filtro
# --------------------------
step7_dir="$EVID_ROOT/07_WEB_UNFILTERED_${ts}"
mkdir -p "$step7_dir"
echo "[07/08] Demo web unfiltered -> $step7_dir"
if [ -x "./scripts/demo_web_unfiltered.sh" ]; then
  ./scripts/demo_web_unfiltered.sh http://example.com 30 "$step7_dir" || true
else
  echo "Aviso: scripts/demo_web_unfiltered.sh não encontrado/executável" | tee -a "$manifest"
fi
sleep "$SLEEP_AFTER_STEP"

# --------------------------
# 08 - Coleta padronizada de evidências
# --------------------------
step8_dir="$EVID_ROOT/08_COLETA_EVIDENCIAS_${ts}"
mkdir -p "$step8_dir"
echo "[08/08] Coleta padronizada de evidências -> $step8_dir"
if [ "$REMOTE_RUN" = "true" ]; then
  if command -v sshpass >/dev/null 2>&1; then
    echo "[08] Executando coleta de evidências via SSH remoto..." | tee -a "$manifest"
    sshpass -p "$VITIMA_PASS" ssh $SSH_OPTS "${USER_VITIMA}@${IP_VITIMA}" "sudo ${REPO_ROOT}/scripts/coleta_evidencias.sh $step8_dir" || true
  else
    echo "sshpass não instalado; execute coleta manualmente na vítima." | tee -a "$manifest"
  fi
else
  if [ -x "./scripts/coleta_evidencias.sh" ]; then
    ./scripts/coleta_evidencias.sh "$step8_dir" || true
  else
    echo "Aviso: scripts/coleta_evidencias.sh não encontrado/executável" | tee -a "$manifest"
  fi
fi
sleep "$SLEEP_AFTER_STEP"

# --------------------------
# Final: gerar SHA256 recursivo para todos os arquivos (exceto MANIFESTs)
# --------------------------
{
  echo ""
  echo "=== SHA256 FOR ALL EVIDENCE FILES (recursive) ==="
  find "$EVID_ROOT" -type f -not -name "MANIFEST_*" -print0 | sort -z | xargs -0 sha256sum || true
} >> "$manifest" 2>/dev/null || true

echo "Execução completa. Manifesto em: $manifest"
