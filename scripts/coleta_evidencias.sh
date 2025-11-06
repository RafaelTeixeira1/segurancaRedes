#!/usr/bin/env bash
set -euo pipefail
OUTDIR=/home/linuxmint/evidencias_$(date +%F_%H%M%S)
mkdir -p "$OUTDIR"
sudo cp /var/log/auth.log "$OUTDIR"/auth.log 2>/dev/null || true
sudo cp /var/log/syslog "$OUTDIR"/syslog 2>/dev/null || true
ps aux > "$OUTDIR"/ps_aux.txt
ls -la /etc/sudoers.d > "$OUTDIR"/sudoersd.txt
sudo find / -xdev -type d -perm -0002 -print > "$OUTDIR"/world_writable_dirs.txt || true
tar czf /home/linuxmint/evidencias.tar.gz -C /home/linuxmint $(basename "$OUTDIR") || true
echo "[*] Evidências agrupadas: /home/linuxmint/evidencias.tar.gz"

