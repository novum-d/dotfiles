# Project Guide

## Project Overview

This repository manages macOS developer environment settings with Nix flakes, nix-darwin, Home Manager, and nix-homebrew.

Key technologies:

- Nix flakes for reproducible system configuration.
- nix-darwin for macOS-level configuration.
- Home Manager for user-level packages and dotfiles.
- nix-homebrew for Homebrew integration.
- Homebrew casks for GUI applications.
- Ollama for local model serving.

High-level architecture:

- `flake.nix` is the entry point and defines the available Darwin host configurations.
- `hosts/<host>/default.nix` contains machine-specific settings such as username, home directory, host platform, and per-user Home Manager imports.
- `home/darwin/default.nix` contains macOS-wide settings, system packages, Homebrew packages, casks, and launchd agents.
- `home/base/default.nix` imports shared Home Manager modules and declares common CLI packages.
- `home/base/programs/*/default.nix` contains program-specific user configuration.

## Getting Started

Prerequisites:

- macOS.
- Xcode Command Line Tools.
- Nix with flakes enabled. The README recommends Determinate Nix.
- nix-darwin.
- Git access to this repository.

Initial setup:

```sh
./boot-strap.sh
```

The bootstrap script checks for Xcode Command Line Tools and starts installation if they are missing.

Clone and apply the configuration:

```sh
mkdir -p ~/repos
cd ~/repos
git clone git@github.com:novum-d/dotfiles.git
cd dotfiles
sudo darwin-rebuild switch --flake .
```

The configured host in this repository is currently:

```sh
sudo darwin-rebuild switch --flake .#novumdnoMac-mini
```

After the shell aliases are active, `u` is an alias for:

```sh
sudo darwin-rebuild switch --flake .
```

Running checks:

```sh
nix flake check
nixfmt <file>.nix
git diff --check
```

There is no dedicated automated test suite in this repository yet. Treat `nix flake check`, `darwin-rebuild switch --flake .`, and focused Nix evaluation as the main validation path.

## Project Structure

```text
.
├── flake.nix
├── flake.lock
├── README.md
├── boot-strap.sh
├── hosts
│   ├── Mac-mini/default.nix
│   └── hosts.nix.sample
└── home
    ├── darwin/default.nix
    └── base
        ├── default.nix
        └── programs
            ├── alacritty/default.nix
            ├── continue/default.nix
            ├── git/default.nix
            ├── karabiner/default.nix
            ├── lazyvim/default.nix
            ├── tmux/default.nix
            └── zsh/default.nix
```

Key files:

- `flake.nix`: Defines inputs and the `darwinConfigurations."novumdnoMac-mini"` output.
- `flake.lock`: Pins dependency revisions. Commit this file when inputs are intentionally updated.
- `hosts/Mac-mini/default.nix`: Host-specific configuration for the current Mac mini.
- `hosts/hosts.nix.sample`: Template for adding another machine.
- `home/darwin/default.nix`: macOS common configuration, Homebrew packages, casks, and the Ollama launchd agent.
- `home/base/default.nix`: Shared Home Manager imports and common CLI packages.
- `home/base/programs/zsh/default.nix`: Zsh, oh-my-zsh, Powerlevel10k, aliases, history, zoxide, and ghq/fzf integration.
- `home/base/programs/git/default.nix`: Git, Git LFS, aliases, commit template, and ghq root.
- `home/base/programs/lazyvim/default.nix`: Neovim with LazyVim and language extras.
- `home/base/programs/karabiner/default.nix`: Karabiner JSON generated through Nix.
- `home/base/programs/continue/default.nix`: Continue config generated at `~/.continue/config.yaml`.

## Development Workflow

Use small Nix modules for each program. Program-specific settings should usually live under `home/base/programs/<name>/default.nix`, then be imported from `home/base/default.nix`.

Use host modules only for settings that differ per machine:

- username
- email
- home directory
- host platform
- machine-specific imports or overrides

Use `home/darwin/default.nix` for macOS-wide concerns:

- system packages
- Homebrew brews and casks
- launchd agents
- nix-darwin settings

Formatting and style:

- Prefer `nixfmt` for Nix files.
- Keep module boundaries clear and avoid placing program-specific config in `flake.nix`.
- Keep `flake.lock` committed.
- Avoid committing generated local files such as `.DS_Store`, logs, editor state, or Nix build outputs.

Build and deployment:

```sh
sudo darwin-rebuild switch --flake .
```

For a specific host:

```sh
sudo darwin-rebuild switch --flake .#novumdnoMac-mini
```

Contribution checklist:

- Format touched Nix files.
- Review `git diff` before switching.
- Run `nix flake check` when practical.
- Apply with `darwin-rebuild switch --flake .`.
- Open a new shell session when changing shell, PATH, or Home Manager settings.

## Key Concepts

Flake:

The top-level reproducible Nix configuration. Inputs are pinned by `flake.lock`, outputs define system configurations.

nix-darwin:

The macOS system configuration layer. It applies system settings and integrates with Home Manager and nix-homebrew.

Home Manager:

The user environment configuration layer. It manages CLI packages, shell config, application config files, and user-level programs.

Host module:

A machine-specific Nix module under `hosts/`. Add one per machine when hardware, username, or local identity differs.

Program module:

A focused Home Manager module under `home/base/programs/`. Each module owns one tool or application.

Activation:

The process of applying the flake to the machine with `darwin-rebuild switch`.

## Common Tasks

Add a new CLI package:

1. Open `home/base/default.nix`.
2. Add the package to `home.packages = with pkgs; [ ... ];`.
3. Run `nixfmt home/base/default.nix`.
4. Run `sudo darwin-rebuild switch --flake .`.

Add a Homebrew cask:

1. Open `home/darwin/default.nix`.
2. Add the cask name to `homebrew.casks`.
3. Run `nixfmt home/darwin/default.nix`.
4. Run `sudo darwin-rebuild switch --flake .`.

Add a new program module:

1. Create `home/base/programs/<program>/default.nix`.
2. Put that program's Home Manager configuration in the new module.
3. Import it from `home/base/default.nix`.
4. Format and apply the flake.

Add a new Mac host:

1. Copy `hosts/hosts.nix.sample` to `hosts/<host>/default.nix`.
2. Set `username`, `nixpkgs.hostPlatform`, Git name, and Git email.
3. Add a matching `darwinConfigurations."<host>"` entry in `flake.nix`.
4. Apply with `sudo darwin-rebuild switch --flake .#<host>`.

Update flake inputs:

```sh
nix flake update
sudo darwin-rebuild switch --flake .
```

Work with Continue configuration:

- Edit `home/base/programs/continue/default.nix`.
- Apply the flake to regenerate `~/.continue/config.yaml`.
- Restart Continue or the IDE after changing MCP server definitions.

## Troubleshooting

`darwin-rebuild` is not found:

Install nix-darwin first, then open a new shell. See the README for the initial nix-darwin installation flow.

Xcode Command Line Tools are missing:

Run:

```sh
./boot-strap.sh
```

Home Manager refuses to overwrite an existing file:

This flake sets `home-manager.backupFileExtension = "backup"` in `flake.nix`, so conflicting files may be moved to a `.backup` file during activation. Review backup files before deleting them.

Alacritty or another cask is quarantined by macOS:

This is a macOS Gatekeeper issue, not a Nix evaluation issue. If needed, remove the quarantine attribute manually for the affected app after verifying the app source.

Continue shows `[MCP Prompt - failed to load content during startup]`:

Check `~/.continue/logs/core.log`. This has previously been caused by `mcp-server-fetch` exposing a prompt that Continue tried to load without a URL. The fetch MCP server is configured in `home/base/programs/continue/config.yaml`; temporarily comment that `mcpServers` entry if startup fails.

Ollama model errors:

Continue is configured for `qwen3-coder:30b` via `http://localhost:11434/v1`. Ensure Ollama is running and that the model exists locally:

```sh
ollama list
ollama pull qwen3-coder:30b
```

Nix evaluation complains about a path not existing in the Git repository:

When using flakes, files referenced from Nix expressions generally need to be tracked by Git. Add the file or fix the path.

## References

- README: `README.md`
- Nix: https://nix.dev/
- nix-darwin: https://github.com/nix-darwin/nix-darwin
- Home Manager: https://github.com/nix-community/home-manager
- nix-homebrew: https://github.com/zhaofengli/nix-homebrew
- Nix flakes: https://nixos.wiki/wiki/Flakes
- Homebrew Bundle/casks: https://docs.brew.sh/Cask-Cookbook
- Continue configuration: https://docs.continue.dev/

## Notes Needing Verification

- The README examples mention older or sample host names in a few places. The active host in `flake.nix` is currently `novumdnoMac-mini`.
- There is no explicit CI configuration in this repository. If CI is added later, document the exact check commands here.
- This guide assumes macOS as the primary target because the flake currently defines only Darwin configurations.
