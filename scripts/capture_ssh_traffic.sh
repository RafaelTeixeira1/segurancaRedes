#!/usr/bin/env bash
set -euo pipefail
# scripts/capture_ssh_traffic.sh

IFACE=${1:-eth1}
OUT=${2:-/home/$(whoami)/evidencias/ssh_bruteforce.pcap}
mkdir -p "$(dirname "$OUT")"
echo "[*] Capturando tráfego na interface $IFACE (filtro port 22). Ctrl+C para parar."
sudo tcpdump -i "$IFACE" port 22 -w "$OUT"

