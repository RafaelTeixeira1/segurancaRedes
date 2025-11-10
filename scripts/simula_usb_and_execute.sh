#!/usr/bin/env bash
set -euo pipefail
# scripts/simula_usb_and_execute.sh

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
echo "[*] Conteúdo /tmp/poc_run.txt:"
cat /tmp/poc_run.txt || true
sudo umount $MNT

