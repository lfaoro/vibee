#!/bin/bash
# Golden image setup script for Vibee VM snapshots.
# Run this as root on a fresh Ubuntu 24.04 server, then power off and snapshot.
set -euo pipefail

echo "=== Vibee Golden Image Setup ==="

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 1. Base system packages
# ---------------------------------------------------------------------------
apt-get update
apt-get upgrade -y
apt-get install -y software-properties-common
add-apt-repository -y universe
apt-get update
apt-get install -y \
  curl git ca-certificates ufw fail2ban unattended-upgrades \
  docker.io cloud-init zsh build-essential wget unzip mosh

# ---------------------------------------------------------------------------
# 2. Create dev user
# ---------------------------------------------------------------------------
useradd -m -s /bin/zsh -G sudo,docker dev

# Passwordless sudo for dev user (standard for single-user dev VMs)
echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
chmod 440 /etc/sudoers.d/dev

# ---------------------------------------------------------------------------
# 3. SSH hardening
# ---------------------------------------------------------------------------
cat > /etc/ssh/sshd_config.d/99-vibee.conf << 'SSHEOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
MaxAuthTries 5
ClientAliveInterval 300
ClientAliveCountMax 2
SSHEOF

# ---------------------------------------------------------------------------
# 4. Firewall
# ---------------------------------------------------------------------------
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 60000:61000/udp   # mosh
ufw --force enable

# ---------------------------------------------------------------------------
# 5. Intrusion prevention
# ---------------------------------------------------------------------------
systemctl enable fail2ban

# ---------------------------------------------------------------------------
# 6. Unattended security updates
# ---------------------------------------------------------------------------
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'APTEOF'
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
APTEOF

systemctl enable unattended-upgrades

# ---------------------------------------------------------------------------
# 7. Install Nix (multi-user, Determinate Systems installer)
# ---------------------------------------------------------------------------
curl --proto '=https' --tlsv1.2 -sSf -L --retry 3 --retry-delay 5 \
  https://install.determinate.systems/nix | sh -s -- install --no-confirm

# Source nix for the remainder of this script
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# ---------------------------------------------------------------------------
# 8. Home Manager configuration for dev user
# ---------------------------------------------------------------------------
mkdir -p /home/dev/.config/home-manager
chown -R dev:dev /home/dev/.config

# Copy configuration files (SCP'd to /tmp/ by build-golden.sh)
cp /tmp/pkgs.nix /home/dev/.config/home-manager/pkgs.nix
cp /tmp/home.nix /home/dev/.config/home-manager/home.nix
cp /tmp/flake.nix /home/dev/.config/home-manager/flake.nix
chown -R dev:dev /home/dev/.config

# ---------------------------------------------------------------------------
# 9. Activate Home Manager as dev user
# ---------------------------------------------------------------------------
su - dev -c '. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && nix run home-manager/master -- switch --flake /home/dev/.config/home-manager'

# Ensure default shell is zsh
usermod -s /bin/zsh dev

# ---------------------------------------------------------------------------
# 10. Install Caddy (auto-SSL web server)
# ---------------------------------------------------------------------------
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

# ---------------------------------------------------------------------------
# 11. Create web directory for dev user
# ---------------------------------------------------------------------------
mkdir -p /home/dev/web
chown dev:caddy /home/dev/web
chmod 2750 /home/dev/web    # SGID: new files inherit caddy group
chmod 755 /home/dev         # caddy needs +x to traverse into web/

cat > /home/dev/web/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>vibee.sh</title>
    <style>
        body { font-family: system-ui, -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #0a0a0f; color: #e2e8f0; }
        .container { text-align: center; }
        h1 { font-size: 2.5rem; margin-bottom: 0.5rem; color: #FF8C00; }
        p { font-size: 1.1rem; color: #64748b; }
        code { background: #1a1a2e; padding: 0.2rem 0.4rem; border-radius: 4px; font-family: 'JetBrains Mono', monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Created with vibee.sh</h1>
        <p>Drop your files in <code>~/web/</code> to serve them.</p>
    </div>
</body>
</html>
HTMLEOF
chown dev:caddy /home/dev/web/index.html
chmod 644 /home/dev/web/index.html

# Add dev to caddy group for log/config access
usermod -aG caddy dev

# ---------------------------------------------------------------------------
# 12. Configure Caddy
# ---------------------------------------------------------------------------
# :80 serves the raw IP address immediately.
# Phase 2 cloud-init will append a domain block with auto-SSL.
cat > /etc/caddy/Caddyfile << 'CADDYEOF'
:80 {
    root * /home/dev/web
    file_server {
        hide .git .env .env.* *.key *.pem *.p12 *.pfx *.crt *.cer
    }
    encode gzip zstd
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        Referrer-Policy strict-origin-when-cross-origin
    }
}
CADDYEOF

chown root:caddy /etc/caddy/Caddyfile
chmod 640 /etc/caddy/Caddyfile

systemctl enable caddy

# ---------------------------------------------------------------------------
# 13. Clean builder artifacts that must NOT be baked into customer snapshots
# ---------------------------------------------------------------------------
# Remove builder SSH keys (root and dev) so they don't leak into customer VMs
rm -f /root/.ssh/authorized_keys
rm -rf /home/dev/.ssh/

# Remove builder SSH host keys so each customer VM gets unique ones on first boot.
# cloud-init usually regenerates these, but we enforce it explicitly to avoid
# accidental key reuse if cloud-init config ever changes.
rm -f /etc/ssh/ssh_host_*

# ---------------------------------------------------------------------------
# 14. Prepare cloud-init for re-run on every derived server
# ---------------------------------------------------------------------------
# Remove instance-specific data (machine-id, seeds, logs) so cloud-init
# treats the next boot as a "first boot" and re-applies user-data.
cloud-init clean --logs --seed --machine-id

# Re-enable cloud-init services so they start on the next boot
systemctl enable cloud-init cloud-init-local cloud-config cloud-final

# ---------------------------------------------------------------------------
# 15. Clean up build artifacts and logs
# ---------------------------------------------------------------------------
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
find /var/log -type f -exec truncate -s 0 {} \;
rm -f /home/dev/.zsh_history /home/dev/.bash_history /root/.bash_history
history -c

echo ""
echo "=== Golden image setup COMPLETE ==="
echo ""
echo "Next steps:"
echo "  1. Power off this server via your cloud provider's CLI or dashboard."
echo ""
echo "  2. Create a snapshot image from the powered-off server."
echo "     Note the Image ID from the output."
echo ""
echo "  3. (Optional) Delete the builder server after the snapshot finishes."
echo ""
echo "Then wire the Image ID into your provisioning system."
