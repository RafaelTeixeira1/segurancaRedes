#!/usr/bin/env bash
# Simula tráfego web sem filtragem (para evidenciar ausência de proxy/firewall)
set -euo pipefail

URL="${1:-http://example.com}"
DUR="${2:-30}"
OUTDIR="${3:-evidencias/07_WEB_UNFILTERED_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUTDIR"

echo "[*] Iniciando demo web não filtrada: $URL por $DUR segundos"
tcpdump -i eth0 -w "$OUTDIR/web_traffic_$(date +%Y%m%d_%H%M%S).pcap" &
PID=$!
timeout "$DUR" curl -s "$URL" -o "$OUTDIR/page.html" || true
sleep 2
kill $PID || true

echo "[*] Captura salva em $OUTDIR"
