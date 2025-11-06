#!/usr/bin/env bash
set -euo pipefail
# provisioning/victim_provision.sh
# Provisiona a VM 'vitima' com vulnerabilidades intencionais.
# Observação: assume que o usuário 'linuxmint' já existe (senha: linuxmint)
# Execute como um usuário com sudo (ex.: linuxmint).

echo "[*] Provisionamento VÍTIMA - iniciando"

sudo apt update -y

# 1) instala OpenSSH e habilita PasswordAuthentication
echo "[*] Instalando OpenSSH e habilitando PasswordAuthentication"
sudo DEBIAN_FRONTEND=noninteractive apt install -y openssh-server
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config || true
sudo systemctl restart ssh

# 2) configura sudo NOPASSWD para linuxmint (intencional)
echo "[*] Criando sudo NOPASSWD para linuxmint (intencional)"
echo 'linuxmint ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/90-linuxmint-nopasswd >/dev/null
sudo chmod 440 /etc/sudoers.d/90-linuxmint-nopasswd

# 3) cria diretório world-writable
echo "[*] Criando /opt/public_exec com permissão 0777"
sudo mkdir -p /opt/public_exec
sudo chmod 0777 /opt/public_exec

# 4) criar usb.img (simulação de pendrive) e script de montagem/exeução
echo "[*] Criando usb.img e script de simulação"
if [ ! -f /home/linuxmint/usb.img ]; then
  sudo dd if=/dev/zero of=/home/linuxmint/usb.img bs=1M count=16 status=none
  sudo mkfs.vfat /home/linuxmint/usb.img
  sudo chown linuxmint:linuxmint /home/linuxmint/usb.img
fi

mkdir -p /home/linuxmint/scripts
cat > /home/linuxmint/scripts/simula_usb_and_execute.sh <<'EOF'
#!/bin/bash
set -e
IMG=/home/linuxmint/usb.img
MNT=/mnt/usbimg
sudo mkdir -p $MNT
sudo mount -o loop $IMG $MNT
sudo bash -c 'cat > '"$MNT"'/poc.sh <<POC
#!/bin/bash
echo "POC executed by $(whoami) at $(date)" >> /tmp/poc_run.txt
POC'
sudo chmod +x $MNT/poc.sh
cp $MNT/poc.sh /tmp/
chmod +x /tmp/poc.sh
/tmp/poc.sh || true
echo "[*] /tmp/poc_run.txt:"
cat /tmp/poc_run.txt || true
sudo umount $MNT
EOF
sudo chown linuxmint:linuxmint -R /home/linuxmint/scripts
sudo chmod +x /home/linuxmint/scripts/simula_usb_and_execute.sh

# 5) script de coleta de evidencias
cat > /home/linuxmint/scripts/coleta_evidencias.sh <<'EOF'
#!/bin/bash
set -e
OUTDIR=/home/linuxmint/evidencias_$(date +%F_%H%M%S)
mkdir -p "$OUTDIR"
sudo cp /var/log/auth.log "$OUTDIR"/auth.log 2>/dev/null || true
sudo cp /var/log/syslog "$OUTDIR"/syslog 2>/dev/null || true
ps aux > "$OUTDIR"/ps_aux.txt
ls -la /etc/sudoers.d > "$OUTDIR"/sudoersd.txt
sudo find / -xdev -type d -perm -0002 -print > "$OUTDIR"/world_writable_dirs.txt || true
tar czf /home/linuxmint/evidencias.tar.gz -C /home/linuxmint $(basename "$OUTDIR") || true
echo "[*] Evidências geradas: /home/linuxmint/evidencias.tar.gz"
EOF
sudo chown linuxmint:linuxmint /home/linuxmint/scripts/coleta_evidencias.sh
sudo chmod +x /home/linuxmint/scripts/coleta_evidencias.sh

echo "[*] Provisionamento VÍTIMA - concluído"

