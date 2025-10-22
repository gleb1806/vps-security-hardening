# vps-security-hardening
Interactive VPS/VDS security hardening script for Ubuntu/Debian
# VPS Security Hardening — Quick README

Interactive Bash script to quickly harden a VPS (Ubuntu/Debian). Designed for simple one‑click setup and common hardening tasks: create sudo user, SSH hardening, UFW firewall, Fail2ban, unattended‑upgrades and basic sysctl tweaks.

---

## Quickstart (one‑line)

Run installer and start interactive hardening (recommended with sudo):

```bash
# curl
sudo bash <(curl -sSL https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh)

# or wget
sudo bash <(wget -qO- https://raw.githubusercontent.com/gleb1806/vps-security-hardening/main/install.sh)
```

---

## Usage

Clone repository and run main script:

```bash
git clone https://github.com/gleb1806/vps-security-hardening.git
cd vps-security-hardening
sudo bash security-hardening.sh
```

Follow the interactive menu (Full Setup, Create User, Configure SSH, Firewall, Fail2ban, etc.).

---

## Key features

- Create non‑root sudo user (optional NOPASSWD)  
- SSH hardening: change port, disable root login, disable password auth  
- UFW firewall: default deny incoming, allow outgoing, add ports  
- Fail2ban with basic jails and a DDoS‑aware filter  
- Optional unattended‑upgrades for automatic security patches  
- Sysctl kernel hardening block  
- visudo syntax checks when writing /etc/sudoers.d entries  
- Settings saved to /root/.vps_security_config

---

## Requirements

- Ubuntu or Debian (tested)  
- Root privileges (sudo)  
- Internet access and apt package manager

---

## Revert (common commands)

Restore SSH config (if backup exists):
```bash
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart sshd
```

Open SSH port in UFW:
```bash
sudo ufw allow 22/tcp
sudo ufw reload
```

Remove NOPASSWD sudoers file:
```bash
sudo rm -f /etc/sudoers.d/<username>
sudo visudo -c
```

Reset UFW:
```bash
sudo ufw --force reset
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw enable
```

Disable Fail2ban and remove created configs:
```bash
sudo systemctl stop fail2ban
sudo systemctl disable fail2ban
sudo rm -f /etc/fail2ban/jail.local /etc/fail2ban/filter.d/sshd-ddos.conf
```

Remove saved config:
```bash
sudo rm -f /root/.vps_security_config
```

---

## Notes

- Test on a non‑production server first.  
- When disabling password auth, ensure SSH keys exist for at least one recovery user.  
- Script creates `/etc/ssh/sshd_config.backup` before modifying SSH config.  
- Replace examples and placeholders with your actual values.

---

## License

MIT — see LICENSE file.
