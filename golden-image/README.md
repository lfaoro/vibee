# Vibee Golden Image

Reusable golden snapshot configuration for Vibee VMs.

## Files

| File | Description |
|------|-------------|
| `setup.sh` | Full setup script to run as root on a fresh Ubuntu 24.04 server |
| `pkgs.nix` | Categorized Nix package list for the `dev` user |
| `home.nix` | Home Manager configuration (zsh, starship, fzf, zoxide, aliases) |
| `flake.nix` | Flake inputs/outputs for Home Manager |

## Workflow

1. **Create a builder server** — any cloud provider, Ubuntu 24.04, smallest instance type
2. **Copy and run the setup script**
   ```bash
   scp golden-image/setup.sh root@<builder-ip>:/tmp/
   ssh root@<builder-ip> 'bash /tmp/setup.sh'
   ```
3. **Power off and create a snapshot image** via your provider's CLI or dashboard
4. **Note the Image ID** from the output and wire it into your provisioning system

## What's Pre-installed

- **Editors:** Helix, Neovim, Nano, Vim
- **AI assistants:** OpenCode, Claude Code, Codex
- **Languages:** Go, Node.js, Bun, Python 3, UV, PHP, Rustup
- **Build tools:** GCC, GNU Make, Watchexec
- **Git:** Git, Lazygit, Delta, GitHub CLI
- **Shell:** Zsh + Starship + Fzf + Zoxide + Direnv
- **CLI replacements:** Eza, Bat, Ripgrep, Fd, Btop, Duf, Dust, Ncdu, Tldr
- **Data tools:** Jq, Yq, SQLite, Fq, Htmlq
- **System:** Tmux, Screen, Just, Curl, Wget, Unzip, P7zip, Xz, Tree, Htop
- **Security:** UFW, Fail2ban, Unattended upgrades
- **Container runtime:** Docker (dev user in docker group)
- **Web server:** Caddy with auto-SSL, serving `~/web/` on `:80` (raw IP) and the domain (Phase 2 adds auto-SSL)

## Web Server

Every VM comes with Caddy pre-installed and configured:

- **Drop files in `~/web/`** and they are served immediately
- **Raw IP access:** `http://<server-ip>/` works out of the box
- **Domain access:** Phase 2 adds `https://<name>.vibee.sh/` with automatic Let's Encrypt SSL
- **Default page:** A branded "Created with vibee.sh" landing page until you add your own `index.html`
- **Security headers:** `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy` are set by default
- **Gzip + Zstd compression** enabled automatically

## Customizing

Edit `pkgs.nix` to add/remove packages, then re-run step 2.
