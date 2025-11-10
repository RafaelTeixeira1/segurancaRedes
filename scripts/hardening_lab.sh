#!/usr/bin/env bash
set -euo pipefail

# ============================================
#  Hardening de Servidor (Ubuntu/Mint/Debian)
#  - Executar como root: sudo bash hardening_lab.sh
#  - Idempotente, com backups e log
# ============================================

# --------- CONFIGURAÇÕES AJUSTÁVEIS ----------
SSH_PORT="${SSH_PORT:-22}"                         # Porta SSH (mude se desejar, ex.: 2222)
SSH_ALLOW_USERS="${SSH_ALLOW_USERS:-linuxmint}"    # Usuários permitidos em SSH (separe por espaço)
ADMIN_SUBNET="${ADMIN_SUBNET:-192.168.56.0/24}"    # Sub-rede administrativa que pode acessar SSH
DISABLE_PASSWORD_AUTH="${DISABLE_PASSWORD_AUTH:-yes}"   # yes/no -> desabilitar login por senha
ENABLE_UFW="${ENABLE_UFW:-yes}"                    # yes/no -> habilitar UFW
ENABLE_FAIL2BAN="${ENABLE_FAIL2BAN:-yes}"          # yes/no -> instalar/ativar fail2ban
HARDEN_SYSCTL="${HARDEN_SYSCTL:-yes}"              # yes/no -> tunáveis do kernel
HARDEN_PAM="${HARDEN_PAM:-yes}"                    # yes/no -> política de senha via PAM
ENABLE_UNATTENDED="${ENABLE_UNATTENDED:-yes}"      # yes/no -> atualizações automáticas
ENABLE_AUDITD="${ENABLE_AUDITD:-yes}"              # yes/no -> auditoria básica
SET_BANNERS="${SET_BANNERS:-yes}"                  # yes/no -> banners legais
TIGHTEN_PERMS="${TIGHTEN_PERMS:-yes}"              # yes/no -> permissões de arquivos sensíveis
HARDEN_FS="${HARDEN_FS:-yes}"                      # yes/no -> opções de montagem seguras
HISTORY_PRIVACY="${HISTORY_PRIVACY:-yes}"          # yes/no -> limitar histórico de shell (privacidade)

# --------- LOGS E BACKUP ----------
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="/root/hardening_backup_${TS}"
LOG_FILE="/var/log/hardening_${TS}.log"
mkdir -p "$BACKUP_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== HARDENING INICIADO EM $(date -u) (UTC) ==="
echo "Backup: $BACKUP_DIR"
echo "Log:    $LOG_FILE"

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa rodar como root. Use: sudo bash $0"
    exit 1
  fi
}
require_root

# Utilitário de backup idempotente: copia arquivo se existir e ainda não foi salvo
bkp() {
  local f="$1"
  if [ -f "$f" ]; then
    local rel="${f#/}"                    # caminho relativo sem barra inicial
    local dest="${BACKUP_DIR}/${rel}"
    mkdir -p "$(dirname "$dest")"
    cp -a "$f" "$dest"
  fi
}

# Adiciona/garante linha única em arquivo (sem duplicar)
ensure_line() {
  local line="$1" file="$2"
  grep -qsF -- "$line" "$file" || echo "$line" >> "$file"
}

# Substitui/insere chave=valor (sysctl-like)
set_kv() {
  local file="$1" key="$2" val="$3"
  if grep -qE "^\s*${key}\s*=" "$file"; then
    sed -i "s#^\s*${key}\s*=.*#${key} = ${val}#g" "$file"
  else
    echo "${key} = ${val}" >> "$file"
  fi
}

# ----------------- 1) Atualizações -----------------
echo "[1/12] Atualizações e pacotes essenciais"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get dist-upgrade -y
apt-get install -y vim-nox curl wget git jq unzip tar net-tools lsof \
                   ufw fail2ban auditd audispd-plugins needrestart \
                   unattended-upgrades apt-transport-https

# ----------------- 2) SSH -----------------
echo "[2/12] Endurecimento do SSH"
SSHD="/etc/ssh/sshd_config"
bkp "$SSHD"

# Garantir chaves básicas
ensure_line "Protocol 2" "$SSHD"
set_kv "$SSHD" "Port" "$SSH_PORT"
ensure_line "PermitRootLogin no" "$SSHD"
ensure_line "PermitEmptyPasswords no" "$SSHD"
ensure_line "PasswordAuthentication $( [ "$DISABLE_PASSWORD_AUTH" = "yes" ] && echo no || echo yes )" "$SSHD"
ensure_line "ChallengeResponseAuthentication no" "$SSHD"
ensure_line "UsePAM yes" "$SSHD"
ensure_line "X11Forwarding no" "$SSHD"
ensure_line "AllowTcpForwarding no" "$SSHD"
ensure_line "ClientAliveInterval 300" "$SSHD"
ensure_line "ClientAliveCountMax 2" "$SSHD"
ensure_line "LoginGraceTime 20" "$SSHD"
# Restringir usuários
if [ -n "$SSH_ALLOW_USERS" ]; then
  # remove linhas anteriores AllowUsers e adiciona a nova
  sed -i '/^AllowUsers\b/d' "$SSHD"
  echo "AllowUsers $SSH_ALLOW_USERS" >> "$SSHD"
fi

systemctl reload ssh || systemctl restart ssh || true

# ----------------- 3) UFW (Firewall) -----------------
if [ "$ENABLE_UFW" = "yes" ]; then
  echo "[3/12] Firewall UFW"
  bkp "/etc/ufw/ufw.conf"
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  # liberar SSH somente da sub-rede administrativa
  ufw allow from "$ADMIN_SUBNET" to any port "$SSH_PORT" proto tcp
  ufw --force enable
  ufw status verbose
else
  echo "[3/12] UFW desabilitado por configuração."
fi

# ----------------- 4) Fail2ban -----------------
if [ "$ENABLE_FAIL2BAN" = "yes" ]; then
  echo "[4/12] Fail2ban"
  JAILD="/etc/fail2ban/jail.local"
  bkp "$JAILD"
  cat > "$JAILD" <<EOF
[DEFAULT]
bantime = 15m
findtime = 10m
maxretry = 5
backend = systemd
ignoreip = 127.0.0.1/8 ::1 ${ADMIN_SUBNET}

[sshd]
enabled = true
port    = ${SSH_PORT}
logpath = %(sshd_log)s
EOF
  systemctl enable --now fail2ban
  fail2ban-client status || true
fi

# ----------------- 5) Sysctl (rede/kernel) -----------------
if [ "$HARDEN_SYSCTL" = "yes" ]; then
  echo "[5/12] Sysctl (rede e kernel)"
  SYSCTL="/etc/sysctl.d/99-hardening.conf"
  bkp "$SYSCTL"
  cat > "$SYSCTL" <<'EOF'
# Desabilita IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Proteções contra spoofing e redirects
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# TCP hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_timestamps = 0

# Desabilita source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Protege sysrq
kernel.sysrq = 0
EOF
  sysctl --system
fi

# ----------------- 6) Política de senha (PAM) -----------------
if [ "$HARDEN_PAM" = "yes" ]; then
  echo "[6/12] Política de senhas (PAM)"
  PWQUALITY="/etc/security/pwquality.conf"
  bkp "$PWQUALITY"
  # Políticas razoáveis para lab (ajuste se necessário)
  sed -i 's/^#\?minlen.*/minlen = 10/' "$PWQUALITY" || echo "minlen = 10" >> "$PWQUALITY"
  sed -i 's/^#\?dcredit.*/dcredit = -1/' "$PWQUALITY" || echo "dcredit = -1" >> "$PWQUALITY"
  sed -i 's/^#\?ucredit.*/ucredit = -1/' "$PWQUALITY" || echo "ucredit = -1" >> "$PWQUALITY"
  sed -i 's/^#\?lcredit.*/lcredit = -1/' "$PWQUALITY" || echo "lcredit = -1" >> "$PWQUALITY"
  sed -i 's/^#\?ocredit.*/ocredit = -1/' "$PWQUALITY" || echo "ocredit = -1" >> "$PWQUALITY"

  # Expiração e histórico (login.defs)
  LOGINDEFS="/etc/login.defs"
  bkp "$LOGINDEFS"
  sed -i 's/^#\?PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' "$LOGINDEFS"
  sed -i 's/^#\?PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' "$LOGINDEFS"
  sed -i 's/^#\?PASS_WARN_AGE.*/PASS_WARN_AGE   14/' "$LOGINDEFS"

  # Bloqueio temporário após falhas (pam_tally2 ou pam_faillock em distros mais novas)
  PAM_AUTH="/etc/pam.d/common-auth"
  bkp "$PAM_AUTH"
  if ! grep -q "pam_faillock.so" "$PAM_AUTH" 2>/dev/null; then
    ensure_line "auth required pam_tally2.so onerr=fail deny=5 unlock_time=600" "$PAM_AUTH"
  fi
fi

# ----------------- 7) Unattended upgrades -----------------
if [ "$ENABLE_UNATTENDED" = "yes" ]; then
  echo "[7/12] Unattended upgrades"
  dpkg-reconfigure -f noninteractive unattended-upgrades || true
  NEEDRESTART_S="$([ -f /etc/needrestart/needrestart.conf ] && echo /etc/needrestart/needrestart.conf || echo "")"
  if [ -n "$NEEDRESTART_S" ]; then
    bkp "$NEEDRESTART_S"
    sed -i 's/^#\?$nrconf{restart}.*/$nrconf{restart} = '"'"'a'"'"';/' "$NEEDRESTART_S" || true
  fi
fi

# ----------------- 8) Auditd básico -----------------
if [ "$ENABLE_AUDITD" = "yes" ]; then
  echo "[8/12] Auditd regras básicas"
  AUDITD_RULES="/etc/audit/rules.d/hardening.rules"
  bkp "$AUDITD_RULES"
  cat > "$AUDITD_RULES" <<'EOF'
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /var/log/auth.log -p wa -k authlog
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b32 -S execve -k exec
EOF
  systemctl enable --now auditd
  augenrules --load || true
  systemctl restart auditd || true
fi

# ----------------- 9) Banners legais -----------------
if [ "$SET_BANNERS" = "yes" ]; then
  echo "[9/12] Banners legais"
  for f in /etc/issue /etc/issue.net /etc/motd; do
    bkp "$f"
    cat > "$f" <<'EOF'
Acesso restrito. Uso autorizado apenas para fins educacionais e laboratoriais.
Atividades podem ser monitoradas e registradas. Desconecte se não tiver autorização.
EOF
  done
fi

# ----------------- 10) Permissões sensíveis -----------------
if [ "$TIGHTEN_PERMS" = "yes" ]; then
  echo "[10/12] Permissões de arquivos sensíveis"
  chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
  chmod 644 /etc/passwd /etc/group
  chmod 640 /etc/shadow /etc/gshadow || true
  [ -f /etc/ssh/ssh_config ] && chmod 644 /etc/ssh/ssh_config
  [ -f /etc/ssh/sshd_config ] && chmod 600 /etc/ssh/sshd_config
  find /root -type f -maxdepth 1 -name ".*history" -exec chmod 600 {} \; 2>/dev/null || true
fi

# ----------------- 11) Montagem/FS seguros -----------------
if [ "$HARDEN_FS" = "yes" ]; then
  echo "[11/12] Opções seguras de montagem (tmp, shm, var_tmp)"
  FSTAB="/etc/fstab"
  bkp "$FSTAB"
  # /tmp e /var/tmp com nosuid,nodev,noexec (se tiver partição separada; se não, criar tmpfs opcional)
  if ! grep -qE '^\s*tmpfs\s+/tmp' "$FSTAB"; then
    echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777,nosuid,nodev,noexec 0 0" >> "$FSTAB"
  fi
  if ! grep -qE '^\s*tmpfs\s+/var/tmp' "$FSTAB"; then
    echo "tmpfs /var/tmp tmpfs defaults,noatime,mode=1777,nosuid,nodev,noexec 0 0" >> "$FSTAB"
  fi
  if ! grep -qE '^\s*tmpfs\s+/dev/shm' "$FSTAB"; then
    echo "tmpfs /dev/shm tmpfs defaults,noatime,nosuid,nodev,noexec 0 0" >> "$FSTAB"
  fi
  mount -a || true
fi

# ----------------- 12) Privacidade do histórico -----------------
if [ "$HISTORY_PRIVACY" = "yes" ]; then
  echo "[12/12] Privacidade de histórico de shell"
  for f in /etc/profile /etc/bash.bashrc; do
    bkp "$f"
    ensure_line 'export HISTSIZE=1000' "$f"
    ensure_line 'export HISTFILESIZE=2000' "$f"
    ensure_line 'export HISTCONTROL=ignoredups:ignorespace' "$f"
    ensure_line 'export HISTIGNORE="ls:cd:pwd:exit:clear:history"' "$f"
    ensure_line 'export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"' "$f"
  done
fi

echo "=== HARDENING CONCLUÍDO EM $(date -u) (UTC) ==="
echo "Backups em: $BACKUP_DIR"
echo "Log em: $LOG_FILE"
echo "LEMBRETE: teste a sessão SSH atual antes de desconectar!"
