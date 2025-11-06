#!/usr/bin/env bash
set -euo pipefail
# scripts/nmap_enum.sh

TARGET=${1:-192.168.56.101}
OUTDIR=${2:-/home/$(whoami)/evidencias}
mkdir -p "$OUTDIR"
echo "[*] Nmap full TCP scan on $TARGET"
nmap -sS -p- -A -T4 -oA "$OUTDIR/nmap_full_${TARGET}" "$TARGET"
echo "[*] Resultado em $OUTDIR/nmap_full_${TARGET}.nmap"

