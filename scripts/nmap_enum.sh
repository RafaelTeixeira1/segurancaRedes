cat > /home/kalilinux/Desktop/segurancaRedes/scripts/nmap_enum.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# scripts/nmap_enum.sh (melhorada)
#
# Uso:
#   nmap_enum.sh <TARGET> [OUTDIR] [SAFE]
#   SAFE=1 -> usa scripts "default" (mais seguro)
#   SAFE=0 -> usa -A (mais agressivo)

TARGET=${1:-192.168.56.101}
OUTDIR=${2:-/home/$(whoami)/Desktop/segurancaRedes/evidencias}
SAFE=${3:-1}   # 1 = usa --script "default" (mais seguro); 0 = usa -A original

mkdir -p "$OUTDIR"
TS=$(date +%F_%H%M%S)
OUTBASE="$OUTDIR/nmap_full_${TARGET}_$TS"
echo "[*] Nmap scan on $TARGET -> $OUTBASE.* (SAFE=$SAFE)"

# checagem básica
command -v nmap >/dev/null 2>&1 || { echo "ERR: nmap não encontrado. Instale: sudo apt-get install -y nmap"; exit 2; }

if [ "$SAFE" -eq 1 ]; then
  # Detecção de versão + scripts default (menos intrusivo)
  sudo nmap -sS -p- -sV -T4 --script "default" -oA "$OUTBASE" "$TARGET"
else
  # Modo agressivo (-A) para varredura mais completa (use somente se autorizado)
  sudo nmap -sS -p- -A -T4 -oA "$OUTBASE" "$TARGET"
fi

echo "[*] Scan finalizado. Resultados: $OUTBASE.nmap  $OUTBASE.xml  $OUTBASE.gnmap"
EOF

chmod +x /home/kalilinux/Desktop/segurancaRedes/scripts/nmap_enum.sh

# (opcional) commitar a mudança no repo
cd /home/kalilinux/Desktop/segurancaRedes || true
git add scripts/nmap_enum.sh
git commit -m "Melhora nmap_enum.sh: timestamp, modo safe (default NSE), opção para -A; evita sobrescrita de resultados" || true

echo "Arquivo atualizado e marcado como executável: /home/kalilinux/Desktop/segurancaRedes/scripts/nmap_enum.sh"

