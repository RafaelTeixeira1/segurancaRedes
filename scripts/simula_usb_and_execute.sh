#!/usr/bin/env bash
# simula_usb_and_execute.sh - Simulação de inserção USB e execução automática de payload
# Projeto: Trabalho Final - Segurança da Informação

set -euo pipefail

OUTDIR="${1:-/home/linuxmint/Desktop/segurancaRedes/evidencias/06_USB_SIMULATION_$(date +%Y%m%d_%H%M%S)}"
USB_IMG="/home/linuxmint/usb.img"
MOUNT_POINT="/mnt/usbimg"
LOGFILE="${OUTDIR}/usb_simulation.log"

mkdir -p "$OUTDIR"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[*] Iniciando simulação USB em: $(date)"
echo "[*] Pasta de saída: $OUTDIR"

# --- Criação da imagem USB se não existir ---
if [ ! -f "$USB_IMG" ]; then
  echo "[*] Criando imagem USB em $USB_IMG (10MB)..."
  sudo dd if=/dev/zero of="$USB_IMG" bs=1M count=10 status=none
  sudo mkfs.vfat "$USB_IMG" >/dev/null
  sudo chmod 666 "$USB_IMG"
else
  echo "[*] Imagem USB já existe: $USB_IMG"
fi

# --- Preparar ponto de montagem ---
sudo mkdir -p "$MOUNT_POINT" || true
sudo umount "$MOUNT_POINT" 2>/dev/null || true

# --- Montagem com tentativa rw automática ---
echo "[*] Montando imagem USB em modo leitura/escrita..."
sudo mount -o loop,rw "$USB_IMG" "$MOUNT_POINT" || {
  echo "[!] Tentativa RW falhou, tentando read-only..."
  sudo mount -o loop,ro "$USB_IMG" "$MOUNT_POINT"
}

# Verifica se foi montado como RW
if grep -q "$MOUNT_POINT" /proc/mounts && grep -q "rw" /proc/mounts | grep "$MOUNT_POINT" >/dev/null 2>&1; then
  echo "[OK] Montado com permissão de escrita (rw)."
else
  echo "[WARN] Montado somente leitura (ro). Tentando remontar forçadamente..."
  sudo umount "$MOUNT_POINT" 2>/dev/null || true
  sudo mount -o loop,rw "$USB_IMG" "$MOUNT_POINT" || echo "[ERRO] Falha ao montar como rw."
fi

# --- Criar payload ---
PAYLOAD="$MOUNT_POINT/poc.sh"
echo "[*] Escrevendo payload em $PAYLOAD..."
sudo bash -c "cat > '$PAYLOAD' <<'EOF'
#!/bin/bash
echo 'POC executed by root at $(date)' > /tmp/poc_run.txt
EOF"

sudo chmod +x "$PAYLOAD"

# --- Executar simulação ---
echo "[*] Executando payload simulado..."
sudo bash "$PAYLOAD" || echo "[WARN] Execução falhou (possível modo RO)."

# --- Registrar evidência ---
if [ -f /tmp/poc_run.txt ]; then
  echo "[+] Palmeiras não tem mundial:"
  cat /tmp/poc_run.txt
  sudo cp /tmp/poc_run.txt "$OUTDIR/"
else
  echo "[!] POC não foi executada corretamente."
fi

# --- Calcular hash ---
echo "[*] Calculando SHA256..."
sha256sum "$OUTDIR"/* > "$OUTDIR/sha256sums.txt"

# --- Desmontagem segura ---
echo "[*] Desmontando USB..."
sudo umount "$MOUNT_POINT" || echo "[WARN] Falha ao desmontar."

echo "[✓] Simulação concluída. Logs e evidências em: $OUTDIR"

