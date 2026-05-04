# vibee

> Rent a server from your terminal. No signup, no password, no web dashboard.

**[vibee.sh](https://vibee.sh)**

```bash
ssh vibee.sh
```

Vibee is a terminal-native server provisioning service. Open your terminal, type `ssh vibee.sh`, and you get a hardened Ubuntu 24.04 server with a pre-configured dev environment. Your SSH public key is your account. No forms, no passwords, no friction.

## What Problem Does It Solve?

Traditional cloud providers require:
- Account creation with email and password
- Credit card up front
- Navigating complex web dashboards
- Picking regions, images, SSH keys through a GUI
- Understanding cloud-specific concepts (instances, volumes, security groups)

Vibee collapses all that into a single command. It targets the developer who lives in the terminal and wants a box to hack on without ceremony.

## Key Features

- **SSH-Native Authentication** — No email, no password. SSH in and your public key creates your account.
- **Terminal UI (TUI)** — Full interactive interface inside your terminal. Browse servers, create/delete, manage billing, view details.
- **SSH Command Aliases** — Designed for agents:
  - `ssh vibee.sh list` — list your servers
  - `ssh vibee.sh new` — list available products
  - `ssh vibee.sh new <name>` — create a server
  - `ssh vibee.sh delete <n|name>` — delete a server
  - `ssh vibee.sh help` — show help
- **Six Server Tiers** — From 2 shared vCPU / 4 GB to 16 dedicated vCPU / 32 GB. Provisioned in the region closest to your IP.
- **Free Trial via Proof-of-Work** — Solve a browser-based SHA-256 puzzle to spin up a 55-minute trial server. No credit card required.
- **Hardened System Image** — Every server boots SSH-hardened, UFW-locked, fail2ban-protected, with Docker, Caddy, and a curated dev toolset preinstalled.
- **Automatic DNS** — `<server-name>.vibee.sh` works out of the box.
- **Privacy-First** — No cookies, no trackers, no marketing emails. Connection logs are anonymous and retained for 90 days for abuse prevention only.

## Open Source

This repository contains the **golden image** — the reproducible server setup that powers every Vibee VM. It is a production-ready bootstrap for Ubuntu 24.04 that hardens SSH, configures UFW and fail2ban, installs Nix + Home Manager, and sets up a complete dev environment with modern tools.

See [`golden-image/`](golden-image/) for the setup scripts and Nix configuration.

## License

[MIT](LICENSE)
