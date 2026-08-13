#!/usr/bin/env bash

# All-platform preflight check. This script verifies prerequisites only;
# platform-specific activation remains an explicit command in docs/.
set -euo pipefail

script_name="$(basename "$0")"

die() {
  printf '%s: %s\n' "$script_name" "$1" >&2
  exit 1
}

info() {
  printf '%s: %s\n' "$script_name" "$1"
}

detect_platform() {
  case "$(uname -s)" in
    Darwin)
      printf '%s\n' "macOS"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        printf '%s\n' "WSL"
      elif [ -n "${TERMUX_VERSION-}" ] || [ -n "${NIX_ON_DROID-}" ]; then
        printf '%s\n' "Nix-on-Droid"
      else
        printf '%s\n' "Linux"
      fi
      ;;
    *)
      die "unsupported operating system: $(uname -s)"
      ;;
  esac
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required; install it before continuing"
}

platform="$(detect_platform)"
info "checking prerequisites for ${platform}"

require_command git

if [ "$platform" = "macOS" ] && ! xcode-select -p >/dev/null 2>&1; then
  info "Xcode Command Line Tools are required; opening the installer"
  xcode-select --install
  die "finish the Xcode Command Line Tools installation, then run this script again"
fi

require_command nix

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  die "run this script from a cloned dotfiles repository"
fi

info "all prerequisite checks passed"
case "$platform" in
  macOS)
    info "next: read docs/macos-setup.md and evaluate the darwin configuration"
    ;;
  Nix-on-Droid)
    info "next: read docs/nix-on-droid.md and run nix-on-droid switch"
    ;;
  WSL)
    info "next: evaluate .#nixosConfigurations.windows-vm"
    ;;
  Linux)
    info "next: evaluate .#nixosConfigurations.nixos"
    ;;
esac
