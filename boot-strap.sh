#!/usr/bin/env bash

# All-platform bootstrap. It installs prerequisites, but never activates a
# system configuration. The activation command remains explicit in docs/.
set -euo pipefail

script_name="$(basename "$0")"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"

die() {
  printf '%s: %s\n' "$script_name" "$1" >&2
  exit 1
}

info() {
  printf '%s: %s\n' "$script_name" "$1"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

refresh_path() {
  local profile_dir

  for profile_dir in \
    "$HOME/.nix-profile/bin" \
    "$HOME/.local/state/nix/profiles/profile/bin" \
    "/nix/var/nix/profiles/default/bin"; do
    if [ -d "$profile_dir" ]; then
      case ":$PATH:" in
        *":$profile_dir:"*) ;;
        *) PATH="$profile_dir:$PATH" ;;
      esac
    fi
  done

  export PATH
}

detect_platform() {
  local kernel proc_version
  kernel="$(uname -s)"

  case "$kernel" in
    Darwin)
      printf '%s\n' "macOS"
      ;;
    Linux)
      proc_version=""
      if [ -r /proc/version ]; then
        proc_version="$(< /proc/version)"
      fi

      case "$proc_version" in
        *[Mm]icrosoft*)
          printf '%s\n' "WSL"
          ;;
        *)
          if [ -n "${TERMUX_VERSION-}" ] || [ -n "${NIX_ON_DROID-}" ] || [ -d /data/data/com.termux.nix ]; then
            printf '%s\n' "Nix-on-Droid"
          elif [ -e /etc/NIXOS ] || has_command nixos-version; then
            printf '%s\n' "NixOS"
          else
            printf '%s\n' "Linux"
          fi
          ;;
      esac
      ;;
    *)
      die "unsupported operating system: $kernel"
      ;;
  esac
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif has_command sudo; then
    sudo "$@"
  else
    die "sudo is required to install system packages"
  fi
}

install_linux_tools() {
  local package_manager
  package_manager=""

  for package_manager in apt-get dnf pacman zypper apk; do
    if has_command "$package_manager"; then
      break
    fi
    package_manager=""
  done

  [ -n "$package_manager" ] || die "no supported Linux package manager found; install curl and git manually"

  info "installing system prerequisites with ${package_manager}"
  case "$package_manager" in
    apt-get)
      run_as_root apt-get update
      run_as_root apt-get install -y ca-certificates curl git xz-utils
      ;;
    dnf)
      run_as_root dnf install -y ca-certificates curl git xz
      ;;
    pacman)
      run_as_root pacman -Sy --needed --noconfirm ca-certificates curl git xz
      ;;
    zypper)
      run_as_root zypper --non-interactive install ca-certificates curl git xz
      ;;
    apk)
      run_as_root apk add ca-certificates curl git xz
      ;;
  esac
}

install_nix() {
  local platform="$1"

  if has_command nix; then
    return
  fi

  case "$platform" in
    NixOS)
      die "Nix is managed by NixOS; boot a NixOS installer or repair the system configuration before running this script"
      ;;
    Nix-on-Droid)
      die "install or repair the Nix-on-Droid app first; this script cannot install the app or its Nix runtime"
      ;;
  esac

  has_command curl || die "curl is required to install Nix"
  info "installing Nix with the Determinate installer"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
  refresh_path
  has_command nix || die "Nix installation finished, but nix is not on PATH; open a new shell and run this script again"
}

install_profile_tools() {
  local platform="$1" command_name package_name nixpkgs_ref missing_packages=()
  local -a expected_tools=(
    "git:git"
    "curl:curl"
    "wget:wget"
    "jq:jq"
    "unzip:unzip"
    "xz:xz"
    "rg:ripgrep"
    "fd:fd"
    "nixfmt:nixfmt"
    "statix:statix"
    "shellcheck:shellcheck"
    "shfmt:shfmt"
    "nil:nil"
  )

  nixpkgs_ref="nixpkgs#"
  if [ "$platform" = "Nix-on-Droid" ]; then
    # Match the pinned nixpkgs used by this repository's Droid configuration.
    nixpkgs_ref="github:NixOS/nixpkgs/88d3861acdd3d2f0e361767018218e51810df8a1#"
  fi

  for tool in "${expected_tools[@]}"; do
    command_name="${tool%%:*}"
    package_name="${tool##*:}"
    if ! has_command "$command_name"; then
      missing_packages+=("${nixpkgs_ref}${package_name}")
    fi
  done

  if [ "${#missing_packages[@]}" -gt 0 ]; then
    info "installing missing command-line tools with nix profile"
    nix profile install --accept-flake-config "${missing_packages[@]}"
    refresh_path
  fi
}

platform="$(detect_platform)"
info "bootstrapping ${platform}"

refresh_path

if [ ! -f "$script_dir/flake.nix" ]; then
  die "flake.nix was not found next to this script"
fi

if [ "$platform" = "macOS" ] && ! xcode-select -p >/dev/null 2>&1; then
  info "Xcode Command Line Tools are required; opening the installer"
  xcode-select --install
  die "finish the Xcode Command Line Tools installation, then run this script again"
fi

if [ "$platform" = "Linux" ] || [ "$platform" = "WSL" ]; then
  if ! has_command curl || ! has_command git; then
    install_linux_tools
  fi
fi

install_nix "$platform"
refresh_path
install_profile_tools "$platform"

for required_command in nix git curl; do
  has_command "$required_command" || die "${required_command} is still unavailable after installation"
done

info "bootstrap complete; installed prerequisites are ready"
case "$platform" in
  macOS)
    info "next: read docs/macos-setup.md and evaluate the darwin configuration"
    ;;
  NixOS)
    info "next: evaluate .#nixosConfigurations.nixos"
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
