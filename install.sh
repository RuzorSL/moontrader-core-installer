#!/usr/bin/env bash
# MoonTrader Core auto-installer for Ubuntu 22.04+ x86_64 VPS.
# MoonTrader website:
# https://moontrader.com

set -Eeuo pipefail

CORE_URL="${CORE_URL:-https://cdn3.moontrader.com/beta/linux-x86_64/MoonTrader-linux-x86_64.tar.xz}"
SERVICE_NAME="${SERVICE_NAME:-moontrader-core}"
TMUX_SESSION="${TMUX_SESSION:-mt}"
DO_SYSTEM_UPGRADE="${DO_SYSTEM_UPGRADE:-1}"
FORCE_REINSTALL="${FORCE_REINSTALL:-0}"
START_AFTER_INSTALL="${START_AFTER_INSTALL:-1}"
ATTACH_AFTER_INSTALL="${ATTACH_AFTER_INSTALL:-1}"

RUN_USER="${RUN_USER:-}"
INSTALL_DIR="${MOONTRADER_DIR:-}"
TMP_DIR=""

log() {
  printf '\n[%s] %s\n' "$(date +'%H:%M:%S')" "$*"
}

die() {
  printf '\nError: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'USAGE'
MoonTrader Core auto-installer for Ubuntu 22.04+ x86_64 VPS.

Normal usage:
  bash install.sh

Options:
  --dir /path/to/MoonTrader     Install directory. Default: ~/MoonTrader
  --user ubuntu                 User that should run MTCore. Default: current user
  --session mt                  tmux session name. Default: mt
  --service moontrader-core     systemd service name. Default: moontrader-core
  --skip-upgrade                Do not run apt upgrade
  --force-reinstall             Download and unpack MTCore again
  --no-start                    Install only, do not start MTCore now
  --no-attach                   Start MTCore but do not attach tmux after install
  -h, --help                    Show this help

Environment variables:
  MOONTRADER_DIR=/path          Same as --dir
  RUN_USER=ubuntu               Same as --user
  TMUX_SESSION=mt               Same as --session
  SERVICE_NAME=moontrader-core  Same as --service
  DO_SYSTEM_UPGRADE=0           Same as --skip-upgrade
  FORCE_REINSTALL=1             Same as --force-reinstall
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      [[ $# -ge 2 ]] || die "Missing path after --dir."
      INSTALL_DIR="$2"
      shift 2
      ;;
    --user)
      [[ $# -ge 2 ]] || die "Missing user after --user."
      RUN_USER="$2"
      shift 2
      ;;
    --session)
      [[ $# -ge 2 ]] || die "Missing tmux session name after --session."
      TMUX_SESSION="$2"
      shift 2
      ;;
    --service)
      [[ $# -ge 2 ]] || die "Missing systemd service name after --service."
      SERVICE_NAME="$2"
      shift 2
      ;;
    --skip-upgrade)
      DO_SYSTEM_UPGRADE=0
      shift
      ;;
    --force-reinstall)
      FORCE_REINSTALL=1
      shift
      ;;
    --no-start)
      START_AFTER_INSTALL=0
      ATTACH_AFTER_INSTALL=0
      shift
      ;;
    --no-attach)
      ATTACH_AFTER_INSTALL=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

as_root() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

as_run_user() {
  local current_uid target_uid
  current_uid="$(id -u)"
  target_uid="$(id -u "$RUN_USER")"

  if [[ "$current_uid" == "$target_uid" ]]; then
    "$@"
  elif [[ $EUID -eq 0 && -x /usr/sbin/runuser ]]; then
    runuser -u "$RUN_USER" -- "$@"
  else
    sudo -H -u "$RUN_USER" "$@"
  fi
}

apt_install() {
  as_root env DEBIAN_FRONTEND=noninteractive apt-get -y \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    "$@"
}

find_library_path() {
  local lib_name="$1"
  local lib_path=""

  lib_path="$(ldconfig -p 2>/dev/null | awk -v name="$lib_name" '$1 == name { print $NF; exit }' || true)"
  if [[ -n "$lib_path" && -e "$lib_path" ]]; then
    printf '%s\n' "$lib_path"
    return 0
  fi

  for lib_path in \
    "/usr/lib/x86_64-linux-gnu/$lib_name" \
    "/lib/x86_64-linux-gnu/$lib_name"; do
    if [[ -e "$lib_path" ]]; then
      printf '%s\n' "$lib_path"
      return 0
    fi
  done

  return 1
}

check_system() {
  [[ "$(uname -m)" == "x86_64" ]] || die "This script supports only x86_64."
  command -v apt-get >/dev/null 2>&1 || die "Ubuntu with apt-get is required."
  command -v systemctl >/dev/null 2>&1 || die "systemd/systemctl is required."

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" && "${ALLOW_NON_UBUNTU:-0}" != "1" ]]; then
      die "This script is intended for Ubuntu 22.04 or newer. Found: ${PRETTY_NAME:-unknown}. To force it, run: ALLOW_NON_UBUNTU=1 bash $0"
    fi

    if [[ "${ID:-}" == "ubuntu" ]]; then
      local ubuntu_version="${VERSION_ID:-0}"
      if [[ "$(printf '%s\n%s\n' "22.04" "$ubuntu_version" | sort -V | head -n 1)" != "22.04" ]]; then
        die "This script supports Ubuntu 22.04 or newer. Found: ${PRETTY_NAME:-Ubuntu $ubuntu_version}."
      fi
    fi
  fi

  if [[ $EUID -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || die "sudo is required unless the script is run as root."
  fi
}

resolve_user_and_paths() {
  if [[ -z "$RUN_USER" ]]; then
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != "root" ]]; then
      RUN_USER="$SUDO_USER"
    else
      RUN_USER="$(id -un)"
    fi
  fi

  id "$RUN_USER" >/dev/null 2>&1 || die "User '$RUN_USER' was not found."

  local run_home
  run_home="$(getent passwd "$RUN_USER" | cut -d: -f6)"
  [[ -n "$run_home" ]] || die "Could not detect home directory for user '$RUN_USER'."

  if [[ -z "$INSTALL_DIR" ]]; then
    INSTALL_DIR="$run_home/MoonTrader"
  fi

  [[ "$INSTALL_DIR" == /* ]] || die "Install path must be absolute: $INSTALL_DIR"
  [[ "$INSTALL_DIR" != *" "* ]] || die "Please use an install path without spaces for systemd: $INSTALL_DIR"
  [[ "$INSTALL_DIR" != *"%"* ]] || die "Install path must not contain the percent sign."
  [[ "$TMUX_SESSION" =~ ^[A-Za-z0-9_.-]+$ ]] || die "tmux session name may contain only letters, digits, '_', '-' or '.'."
  [[ "$SERVICE_NAME" =~ ^[A-Za-z0-9_.@-]+$ ]] || die "Service name may contain only letters, digits, '_', '-', '.', '@'."
}

install_packages() {
  log "Updating Ubuntu package index."
  as_root env DEBIAN_FRONTEND=noninteractive apt-get update

  if [[ "$DO_SYSTEM_UPGRADE" == "1" ]]; then
    log "Upgrading installed packages. Use --skip-upgrade to skip this step."
    apt_install upgrade
  else
    log "Skipping apt upgrade."
  fi

  log "Installing dependencies: ca-certificates, wget, xz-utils, tar, tmux, libtommath1, libncurses6."
  apt_install install ca-certificates wget xz-utils tar tmux libtommath1 libncurses6
}

create_compat_links() {
  local arch_dir="/usr/lib/x86_64-linux-gnu"
  local tommath_src tommath_dst ncurses_src ncurses_dst

  log "Creating compatibility library files expected by MTCore."
  as_root mkdir -p "$arch_dir"

  tommath_src="$(find_library_path "libtommath.so.1")" || die "libtommath.so.1 was not found after installing libtommath1."
  tommath_dst="$arch_dir/libtommath.so.0"
  if [[ ! -e "$tommath_dst" ]]; then
    as_root ln -s "$tommath_src" "$tommath_dst"
  fi

  ncurses_src="$(find_library_path "libncurses.so.6")" || die "libncurses.so.6 was not found after installing libncurses6."
  ncurses_dst="$arch_dir/libncurses.so.5"
  if [[ ! -e "$ncurses_dst" ]]; then
    as_root cp -L "$ncurses_src" "$ncurses_dst"
    as_root chmod 0644 "$ncurses_dst"
  fi

  as_root ldconfig
}

download_and_install_core() {
  local archive extract_dir core_path core_dir run_group
  run_group="$(id -gn "$RUN_USER")"

  if [[ -x "$INSTALL_DIR/MTCore" && "$FORCE_REINSTALL" != "1" ]]; then
    log "MTCore already exists in $INSTALL_DIR. Skipping download."
    return
  fi

  log "Downloading MoonTrader Core x86_64."
  TMP_DIR="$(mktemp -d)"
  archive="$TMP_DIR/MoonTrader-linux-x86_64.tar.xz"
  extract_dir="$TMP_DIR/extract"
  mkdir -p "$extract_dir"

  wget -O "$archive" "$CORE_URL"

  log "Unpacking MTCore into $INSTALL_DIR."
  tar -xJf "$archive" -C "$extract_dir"

  core_path="$(find "$extract_dir" -type f -name MTCore | head -n 1)"
  [[ -n "$core_path" ]] || die "MTCore file was not found in the archive."
  core_dir="$(dirname "$core_path")"

  as_root mkdir -p "$INSTALL_DIR"
  as_root cp -a "$core_dir"/. "$INSTALL_DIR"/
  as_root chown -R "$RUN_USER:$run_group" "$INSTALL_DIR"
  as_root chmod +x "$INSTALL_DIR/MTCore"
}

write_systemd_service() {
  local service_path="/etc/systemd/system/${SERVICE_NAME}.service"
  local unit_file
  unit_file="$(mktemp)"

  log "Configuring autostart service: ${SERVICE_NAME}.service."
  cat > "$unit_file" <<UNIT
[Unit]
Description=MoonTrader Core in tmux
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=${RUN_USER}
WorkingDirectory=${INSTALL_DIR}
Environment=TERM=xterm-256color
ExecStart=/bin/bash -lc '/usr/bin/tmux has-session -t ${TMUX_SESSION} 2>/dev/null || /usr/bin/tmux new-session -d -s ${TMUX_SESSION} ./MTCore'
ExecStop=/bin/bash -lc '/usr/bin/tmux has-session -t ${TMUX_SESSION} 2>/dev/null && /usr/bin/tmux send-keys -t ${TMUX_SESSION} C-c || true'
ExecStopPost=/bin/bash -lc 'sleep 2; /usr/bin/tmux has-session -t ${TMUX_SESSION} 2>/dev/null && /usr/bin/tmux kill-session -t ${TMUX_SESSION} || true'

[Install]
WantedBy=multi-user.target
UNIT

  as_root install -m 0644 "$unit_file" "$service_path"
  rm -f "$unit_file"

  as_root systemctl daemon-reload
  as_root systemctl enable "${SERVICE_NAME}.service"
}

print_summary() {
  cat <<DONE

Done.

Core directory:   ${INSTALL_DIR}
tmux session:     ${TMUX_SESSION}
systemd service:  ${SERVICE_NAME}.service

After a VPS reboot, MTCore will start automatically inside tmux.
Attach manually:
  tmux a -t ${TMUX_SESSION}

Detach from tmux without stopping MTCore:
  Ctrl+B, then D

Useful service commands:
  sudo systemctl status ${SERVICE_NAME}.service
  sudo systemctl restart ${SERVICE_NAME}.service
  sudo systemctl stop ${SERVICE_NAME}.service

DONE
}

start_core_and_attach() {
  if [[ "$START_AFTER_INSTALL" != "1" ]]; then
    log "Install finished. MTCore start was skipped because --no-start was used."
    print_summary
    return
  fi

  log "Starting tmux session with ./MTCore."

  if as_run_user tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    log "tmux session '$TMUX_SESSION' is already running."
  else
    as_root systemctl restart "${SERVICE_NAME}.service"
  fi

  for _ in {1..10}; do
    if as_run_user tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
      break
    fi
    sleep 1
  done

  as_run_user tmux has-session -t "$TMUX_SESSION" 2>/dev/null || die "tmux session '$TMUX_SESSION' did not start. Check: sudo systemctl status ${SERVICE_NAME}.service"
  print_summary

  if [[ "$ATTACH_AFTER_INSTALL" != "1" ]]; then
    log "tmux attach was skipped because --no-attach was used."
    return
  fi

  if [[ -t 0 && -t 1 ]]; then
    log "Opening tmux now. Continue MTCore setup in the session."
    if [[ -n "${TMUX:-}" ]]; then
      as_run_user tmux switch-client -t "$TMUX_SESSION" || true
    else
      as_run_user tmux attach-session -t "$TMUX_SESSION"
    fi
  else
    log "No interactive terminal detected. Attach manually: tmux a -t ${TMUX_SESSION}"
  fi
}

main() {
  check_system
  resolve_user_and_paths

  log "MTCore user: $RUN_USER"
  log "Install directory: $INSTALL_DIR"

  install_packages
  create_compat_links
  download_and_install_core
  write_systemd_service
  start_core_and_attach
}

main "$@"
