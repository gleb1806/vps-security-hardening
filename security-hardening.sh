#!/usr/bin/env bash
# security-hardening.sh
# Interactive VPS hardening helper for Debian/Ubuntu
# Usage: sudo bash security-hardening.sh
set -euo pipefail

# === Configuration / constants ===
CONFIG_SAVE="/root/.vps_security_config"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_BACKUP="/etc/ssh/sshd_config.backup"
SUDOERS_DIR="/etc/sudoers.d"
SYSCTL_CONF="/etc/sysctl.conf"
SYSCTL_MARKER_BEGIN="# --- vps_security_hardening BEGIN ---"
SYSCTL_MARKER_END="# --- vps_security_hardening END ---"
DEFAULT_SSH_PORT=22

# === Helpers ===
log() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }
confirm() {
  # usage: confirm "Message"
  local msg="${1:-Are you sure?}"
  local ans
  read -r -p "$msg [y/N]: " ans
  case "$ans" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    err "This script must be run as root. Use sudo."
    exit 1
  fi
}

backup_file() {
  local src="$1"
  if [ -f "$src" ]; then
    cp -a "$src" "${src}.backup-$(date +%Y%m%d%H%M%S)" || true
  fi
}

save_config_kv() {
  local key="$1"
  local val="$2"
  mkdir -p "$(dirname "$CONFIG_SAVE")"
  # Remove old key if exists and append new
  grep -v -x -F "${key}=" "$CONFIG_SAVE" 2>/dev/null || true > /tmp/.vps_cfg_tmp || true
  if [ -f /tmp/.vps_cfg_tmp ]; then
    mv /tmp/.vps_cfg_tmp "$CONFIG_SAVE"
  fi
  printf '%s=%s\n' "$key" "$val" >> "$CONFIG_SAVE"
}

restart_sshd() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl restart sshd || systemctl restart ssh || true
  else
    service ssh restart || service sshd restart || true
  fi
}

# === Tasks ===
create_user() {
  local username password use_ssh_key add_to_sudo nopasswd
  read -r -p "Enter new username: " username
  if id "$username" >/dev/null 2>&1; then
    log "User '$username' already exists."
  else
    read -r -p "Create home directory? (default: yes) [Y/n]: " tmp
    if [[ "$tmp" =~ ^[Nn]$ ]]; then
      useradd -M -s /bin/bash "$username"
    else
      useradd -m -s /bin/bash "$username"
    fi
    log "User $username created (without password)."
  fi

  # Set password
  if confirm "Set (or reset) password for $username?"; then
    passwd "$username"
  else
    log "Password not changed for $username."
  fi

  # SSH key
  if confirm "Add SSH public key for $username?"; then
    read -r -p "Paste public key (single line) and press Enter: " pubkey
    mkdir -p "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    printf '%s\n' "$pubkey" >> "/home/$username/.ssh/authorized_keys"
    chmod 600 "/home/$username/.ssh/authorized_keys"
    chown -R "$username:$username" "/home/$username/.ssh"
    log "SSH key installed for $username."
    save_config_kv "USERNAME" "$username"
  fi

  # Sudo
  if confirm "Add $username to sudo (wheel) group?"; then
    usermod -aG sudo "$username" || usermod -aG wheel "$username" || true
    if confirm "Make sudo for $username NOPASSWD (allow sudo without password)?"; then
      mkdir -p "$SUDOERS_DIR"
      chmod 755 "$SUDOERS_DIR"
      local sudofile="$SUDOERS_DIR/$username"
      printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$username" > "$sudofile"
      chown root:root "$sudofile"
      chmod 440 "$sudofile"
      if visudo -cf "$sudofile" >/dev/null 2>&1; then
        log "NOPASSWD sudo added for $username."
      else
        err "visudo check failed for $sudofile. Removing."
        rm -f "$sudofile"
      fi
    fi
  fi
}

configure_ssh() {
  # Make backup
  if [ -f "$SSHD_CONFIG" ]; then
    cp -a "$SSHD_CONFIG" "$SSHD_BACKUP"
    log "Backed up $SSHD_CONFIG to $SSHD_BACKUP"
  fi

  # Prompt for changes
  read -r -p "Enter desired SSH port (current default $DEFAULT_SSH_PORT): " new_port
  new_port="${new_port:-$DEFAULT_SSH_PORT}"

  if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
    err "Invalid port. Aborting SSH configuration."
    return 1
  fi

  # edit or add directives
  _sshd_set() {
    local key="$1" val="$2"
    if grep -q -E "^[#[:space:]]*${key}[[:space:]]+" "$SSHD_CONFIG" 2>/dev/null; then
      sed -i "s#^[#[:space:]]*${key}[[:space:]]\+.*#${key} ${val}#" "$SSHD_CONFIG"
    else
      printf '\n%s %s\n' "$key" "$val" >> "$SSHD_CONFIG"
    fi
  }

  _sshd_set Port "$new_port"
  _sshd_set PermitRootLogin no

  if confirm "Disable SSH password authentication (enable only keys)? Make sure you have a working SSH key for recovery."; then
    _sshd_set PasswordAuthentication no
  else
    _sshd_set PasswordAuthentication yes
  fi

  # Optionally restrict AllowUsers
  if confirm "Restrict SSH to specific users (add AllowUsers)?"; then
    read -r -p "List users (space separated): " users
    # convert spaces to single space and write as single line
    users="$(echo "$users" | xargs)"
    _sshd_set AllowUsers "$users"
    save_config_kv "SSH_ALLOWED_USERS" "$users"
  fi

  # Restart sshd carefully
  log "Attempting to restart SSH daemon..."
  restart_sshd
  log "SSHD restarted. Make sure you can still connect on port $new_port."
  save_config_kv "SSH_PORT" "$new_port"
}

setup_ufw() {
  if ! command -v ufw >/dev/null 2>&1; then
    log "Installing ufw..."
    apt-get update -y
    apt-get install -y ufw
  fi

  local ssh_port
  ssh_port="$(awk -F= '/^SSH_PORT=/{print $2}' "$CONFIG_SAVE" 2>/dev/null || echo "$DEFAULT_SSH_PORT")"

  # Basic rules
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow "$ssh_port"/tcp
  log "Allowed SSH port $ssh_port in UFW."

  # Optionally allow common services
  if confirm "Open HTTP/HTTPS (80/443)?"; then
    ufw allow 80/tcp
    ufw allow 443/tcp
  fi

  if ! ufw status | grep -qi active; then
    ufw --force enable
  else
    ufw reload
  fi

  log "UFW configured."
}

install_fail2ban() {
  if ! command -v fail2ban-server >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y fail2ban
  fi

  # Create basic jail.local
  local jail_local="/etc/fail2ban/jail.local"
  cat > "$jail_local" <<'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF

  # Example ddos-aware filter (optional); only add if not present
  local ddos_filter="/etc/fail2ban/filter.d/sshd-ddos.conf"
  if [ ! -f "$ddos_filter" ]; then
    cat > "$ddos_filter" <<'EOF'
# Example filter to catch repeated connection attempts patterns (adjust as needed)
[Definition]
failregex = ^%(__prefix_line)s(?:error: PAM: )?Authentication failure for .* from <HOST>\s*$
ignoreregex =
EOF
  fi

  systemctl enable --now fail2ban || service fail2ban start || true
  log "Fail2ban installed and started."
}

enable_unattended_upgrades() {
  if ! dpkg -s unattended-upgrades >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y unattended-upgrades apt-listchanges
  fi

  # Enable automatic upgrades
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

  # Minimal unattended-upgrades config (ensure security updates)
  dpkg-reconfigure -plow unattended-upgrades || true
  log "unattended-upgrades enabled."
  save_config_kv "UNATTENDED_UPGRADES" "yes"
}

apply_sysctl_hardening() {
  # Append block between markers; if exists, replace
  if grep -qF "$SYSCTL_MARKER_BEGIN" "$SYSCTL_CONF" 2>/dev/null; then
    # Remove old block
    awk -v b="$SYSCTL_MARKER_BEGIN" -v e="$SYSCTL_MARKER_END" '{
      if ($0==b) {f=1; next}
      if ($0==e) {f=0; next}
      if (!f) print $0
    }' "$SYSCTL_CONF" > "${SYSCTL_CONF}.tmp" && mv "${SYSCTL_CONF}.tmp" "$SYSCTL_CONF"
  fi

  cat >> "$SYSCTL_CONF" <<EOF

$SYSCTL_MARKER_BEGIN
# Basic network hardening
net.ipv4.ip_forward = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1

# Reduce netfilter memory DoS vector
net.netfilter.nf_conntrack_max = 131072

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Restrict ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Disable IPv6 router solicit/redirect acceptance (optional)
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
$SYSCTL_MARKER_END
EOF

  sysctl -p || true
  log "Applied sysctl hardening block."
  save_config_kv "SYSCTL_HARDENED" "yes"
}

show_status() {
  log "=== Current saved configuration (if any) ==="
  if [ -f "$CONFIG_SAVE" ]; then
    cat "$CONFIG_SAVE"
  else
    log "No config saved yet ($CONFIG_SAVE not found)."
  fi
  log "==========================================="
}

# === Interactive menu ===
main_menu() {
  while true; do
    cat <<'MENU'

VPS Security Hardening — Menu
1) Full setup (recommended for new servers)
2) Create user (sudo, SSH key)
3) Configure SSH (port, root login, password auth)
4) Setup UFW (firewall)
5) Install and configure Fail2ban
6) Enable unattended-upgrades
7) Apply sysctl kernel hardening
8) Show saved settings
9) Exit
MENU
    read -r -p "Choose an option [1-9]: " opt
    case "$opt" in
      1)
        if confirm "This will run several changes (create user, configure SSH, UFW, fail2ban, sysctl, unattended-upgrades). Continue?"; then
          create_user
          configure_ssh
          setup_ufw
          install_fail2ban
          enable_unattended_upgrades
          apply_sysctl_hardening
          log "Full setup completed. Review changes and test SSH access."
        else
          log "Full setup cancelled."
        fi
        ;;
      2) create_user ;;
      3) configure_ssh ;;
      4) setup_ufw ;;
      5) install_fail2ban ;;
      6) enable_unattended_upgrades ;;
      7) apply_sysctl_hardening ;;
      8) show_status ;;
      9) log "Exiting." ; break ;;
      *) log "Invalid option." ;;
    esac
  done
}

# === Entrypoint ===
require_root

# Ensure apt exists on system
if ! command -v apt-get >/dev/null 2>&1; then
  err "apt-get not found. This script targets Debian/Ubuntu systems. Exiting."
  exit 1
fi

# Create config file if missing
if [ ! -f "$CONFIG_SAVE" ]; then
  touch "$CONFIG_SAVE"
  chmod 600 "$CONFIG_SAVE"
fi

main_menu

exit 0
