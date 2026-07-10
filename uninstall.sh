#!/usr/bin/env bash
# Uninstall helper for moontrader-core-installer.

set -Eeuo pipefail

SERVICE_NAME="${SERVICE_NAME:-moontrader-core}"
TMUX_SESSION="${TMUX_SESSION:-mt}"
RUN_USER="${RUN_USER:-}"
INSTALL_DIR="${MOONTRADER_DIR:-}"
PURGE_FILES=0

log() {
  printf '\n[%s] %s\n' "$(date +'%H:%M:%S')" "$*"
}

die() {
  printf '\nError: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
MoonTrader Core uninstall helper.

Normal usage:
  bash uninstall.sh

Options:
  --dir /path/to/MoonTrader     Install directory. Default: ~/MoonTrader
  --user ubuntu                 User that runs MTCore. Default: current user
  --session mt                  tmux session name. Default: mt
  --service moontrader-core     systemd service name. Default: moontrader-core
  --purge-files                 Remove the MoonTrader directory too
  -h, --help                    Show this help
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
    --purge-files)
      PURGE_FILES=1
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
  [[ "$TMUX_SESSION" =~ ^[A-Za-z0-9_.-]+$ ]] || die "Invalid tmux session name."
  [[ "$SERVICE_NAME" =~ ^[A-Za-z0-9_.@-]+$ ]] || die "Invalid service name."
}

main() {
  command -v systemctl >/dev/null 2>&1 || die "systemctl is required."
  if [[ $EUID -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || die "sudo is required unless the script is run as root."
  fi

  resolve_user_and_paths

  log "Stopping ${SERVICE_NAME}.service if it exists."
  if systemctl list-unit-files "${SERVICE_NAME}.service" >/dev/null 2>&1; then
    as_root systemctl stop "${SERVICE_NAME}.service" || true
    as_root systemctl disable "${SERVICE_NAME}.service" || true
  fi

  log "Stopping tmux session '${TMUX_SESSION}' if it exists."
  if command -v tmux >/dev/null 2>&1 && as_run_user tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    as_run_user tmux send-keys -t "$TMUX_SESSION" C-c || true
    sleep 2
    as_run_user tmux kill-session -t "$TMUX_SESSION" || true
  fi

  log "Removing systemd unit file."
  as_root rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
  as_root systemctl daemon-reload

  if [[ "$PURGE_FILES" == "1" ]]; then
    log "Removing MoonTrader directory: $INSTALL_DIR"
    as_root rm -rf "$INSTALL_DIR"
  else
    log "MoonTrader directory was kept: $INSTALL_DIR"
  fi

  cat <<DONE

Done.

Autostart service removed: ${SERVICE_NAME}.service
tmux session stopped:      ${TMUX_SESSION}
MoonTrader directory:      ${INSTALL_DIR}

To remove the MoonTrader directory too, run:
  bash uninstall.sh --purge-files

DONE
}

main "$@"
