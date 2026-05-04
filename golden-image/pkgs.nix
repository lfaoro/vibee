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
