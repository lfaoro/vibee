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
apt-get install -y \
  curl git ca-certificates ufw fail2ban unattended-upgrades \
  docker.io cloud-init zsh build-essential wget unzip

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

# Copy configuration files from this repository (adjust path if needed)
# If running manually, scp these files to /home/dev/.config/home-manager/ first.
cat > /home/dev/.config/home-manager/pkgs.nix << 'NIXEOF'
{ pkgs, ... }:
[
  # ═══════════════════════════════════════════════════════════════
  # Editors & IDEs
  # ═══════════════════════════════════════════════════════════════
  pkgs.helix           # Modal editor inspired by Kakoune
  pkgs.neovim          # Hyperextensible Vim-based editor
  pkgs.nano            # Simple terminal editor
  pkgs.vim             # Provides xxd and classic vi

  # ═══════════════════════════════════════════════════════════════
  # AI Coding Assistants ("Vibe Coding")
  # ═══════════════════════════════════════════════════════════════
  pkgs.opencode        # OpenCode AI coding assistant CLI
  pkgs.claude-code     # Anthropic Claude CLI (claude)
  pkgs.codex           # OpenAI Codex CLI (codex)

  # ═══════════════════════════════════════════════════════════════
  # Languages & Runtimes
  # ═══════════════════════════════════════════════════════════════
  pkgs.go              # Go compiler and toolchain
  pkgs.nodejs          # JavaScript runtime (required by most LSPs via Mason)
  pkgs.bun             # Fast JavaScript runtime and bundler
  pkgs.python3         # Python interpreter (universal scripting)
  pkgs.uv              # Ultra-fast Python package manager (pip replacement)
  pkgs.php             # PHP interpreter
  pkgs.rustup          # Rust toolchain installer

  # ═══════════════════════════════════════════════════════════════
  # Build & Compilation
  # ═══════════════════════════════════════════════════════════════
  pkgs.gcc             # GNU C compiler (treesitter, cgo, native deps)
  pkgs.gnumake         # GNU Make build tool
  pkgs.watchexec       # Run commands on file changes

  # ═══════════════════════════════════════════════════════════════
  # Git & Version Control
  # ═══════════════════════════════════════════════════════════════
  pkgs.git             # Distributed version control
  pkgs.lazygit         # Terminal UI for Git
  pkgs.delta           # Syntax-highlighted git diffs
  pkgs.gh              # GitHub CLI (pull requests, issues, actions)

  # ═══════════════════════════════════════════════════════════════
  # Terminal Multiplexer & Session Management
  # ═══════════════════════════════════════════════════════════════
  pkgs.tmux            # Terminal multiplexer (survives SSH disconnects)
  pkgs.screen          # Classic terminal multiplexer

  # ═══════════════════════════════════════════════════════════════
  # Shell Enhancements
  # ═══════════════════════════════════════════════════════════════
  pkgs.fzf             # Fuzzy finder for files, history, processes
  pkgs.zoxide          # Smarter cd command (z / zi)
  pkgs.starship        # Cross-shell prompt (configured in home.nix)
  pkgs.direnv          # Directory-specific environment variables

  # ═══════════════════════════════════════════════════════════════
  # Modern CLI Replacements
  # ═══════════════════════════════════════════════════════════════
  pkgs.eza             # Modern ls replacement with git integration
  pkgs.bat             # Cat clone with syntax highlighting
  pkgs.ripgrep         # Ultra-fast grep alternative (rg)
  pkgs.fd              # User-friendly find alternative
  pkgs.btop            # Resource monitor (CPU, memory, disk, network)
  pkgs.duf             # Disk usage viewer (better df)
  pkgs.dust            # Disk usage analyzer (better du)
  pkgs.ncdu            # Interactive disk usage analyzer (TUI)
  pkgs.tldr            # Community-driven man pages

  # ═══════════════════════════════════════════════════════════════
  # Data Processing & Querying
  # ═══════════════════════════════════════════════════════════════
  pkgs.jq              # Command-line JSON processor
  pkgs.yq              # Command-line YAML/XML/TOML processor
  pkgs.sqlite          # Lightweight SQL database engine (CLI)
  pkgs.fq              # jq for binary formats
  pkgs.htmlq           # jq for HTML

  # ═══════════════════════════════════════════════════════════════
  # System Utilities
  # ═══════════════════════════════════════════════════════════════
  pkgs.curl            # Transfer data with URLs
  pkgs.wget            # Network downloader
  pkgs.unzip           # Extract ZIP archives
  pkgs.p7zip           # 7-Zip archive tool
  pkgs.xz              # LZMA compression
  pkgs.tree            # Directory structure visualizer
  pkgs.htop            # Interactive process viewer
  pkgs.just            # Modern command runner (justfile)

  # ← Add your own packages here
]
NIXEOF

cat > /home/dev/.config/home-manager/flake.nix << 'NIXEOF'
{
  description = "Home Manager for dev";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations."dev" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
    };
  };
}
NIXEOF

cat > /home/dev/.config/home-manager/home.nix << 'NIXEOF'
{ config, pkgs, ... }:
{
  home.username = "dev";
  home.homeDirectory = "/home/dev";
  home.stateVersion = "26.05";

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  home.packages = import ./pkgs.nix { inherit pkgs; };

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh.shellAliases = {
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    cat = "bat";
    update = "home-manager switch --flake /home/dev/.config/home-manager";
  };
}
NIXEOF

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
        hide .git .env
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
# Remove the builder's SSH key so it doesn't leak into every customer VM
rm -f /root/.ssh/authorized_keys

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
