#!/usr/bin/env bash
set -euo pipefail
# provisioning/attacker_provision.sh

echo "[*] Provisionamento ATACANTE - iniciando"
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y hydra nmap tcpdump netcat-openbsd sshpass john
# pequena wordlist
cat > /home/$(whoami)/passwords_small.txt <<'EOF'
linuxmint
password
123456
admin
qwerty
EOF
chmod 600 /home/$(whoami)/passwords_small.txt
echo "[*] Provisionamento ATACANTE - concluído"

