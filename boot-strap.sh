#!/usr/bin/env bash

# 全プラットフォーム共通の導入スクリプト。
# 前提CLIだけを導入し、システム構成の反映はdocs/の手順から明示的に実行する。
set -euo pipefail

script_name="$(basename "$0")"
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"

# エラーと進捗へ常にスクリプト名を付け、どの処理の出力か分かるようにする。
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

# Nix導入直後でも後続処理がnixコマンドを見つけられるよう、既知のprofileをPATHへ追加する。
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

# kernel、WSLの識別情報、Nix-on-Droidの環境変数から実行環境を判定する。
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

# Linuxのシステムパッケージ導入だけ、rootまたはsudo経由で実行する。
run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif has_command sudo; then
    sudo "$@"
  else
    die "sudo is required to install system packages"
  fi
}

# Nix導入に必要なcurl・Git・証明書・xzだけを、利用可能なパッケージマネージャーで導入する。
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

# NixOSとNix-on-DroidではOS側のNixを尊重し、それ以外だけDeterminate Nixを導入する。
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

# Home Managerを反映する前でも検証できるよう、不足している基礎CLIをNix profileへ追加する。
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
    # リポジトリのNix-on-Droid構成と同じ固定revisionからCLIを導入する。
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

# すでに導入済みのNixも含め、以降の確認前にPATHを正規化する。
refresh_path

if [ ! -f "$script_dir/flake.nix" ]; then
  die "flake.nix was not found next to this script"
fi

if [ "$platform" = "macOS" ] && ! xcode-select -p >/dev/null 2>&1; then
  info "Xcode Command Line Tools are required; opening the installer"
  xcode-select --install
  die "finish the Xcode Command Line Tools installation, then run this script again"
fi

# 汎用LinuxとWSLでは、Nixインストーラーの前提CLIがない場合だけOS側から補う。
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

# このスクリプトはactivationせず、環境別の次の確認先だけを案内する。
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
