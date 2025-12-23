#!/usr/bin/env bash
set -Eeuo pipefail

# Re-exec in bash if invoked via sh or another shell.
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

fail() {
  printf "Error: %s\n" "$1" >&2
  exit 1
}

run() {
  printf "+ %s\n" "$*"
  "$@"
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ATOMVM_ESP32_DIR_DEFAULT="${ROOT}/atomvm/AtomVM/src/platforms/esp32"
IDF_PATH_DEFAULT="${HOME}/esp/esp-idf"

ESP32_DIR="$ATOMVM_ESP32_DIR_DEFAULT"
IDF_PATH="${IDF_PATH:-$IDF_PATH_DEFAULT}"
PORT=""
BAUD="115200"
EXTRA_ARGS=()

usage() {
  cat <<EOF
Usage:
  ./scripts/monitor-esp32.sh [options] [-- <extra idf.py monitor args>]

Options:
  --esp32-dir PATH   AtomVM ESP32 dir (default: ${ATOMVM_ESP32_DIR_DEFAULT})
  --idf-path PATH    ESP-IDF root (default: \$IDF_PATH or ${IDF_PATH_DEFAULT})
  --port PORT        Serial port (default: auto-detect /dev/ttyACM* or /dev/ttyUSB*)
  --baud BAUD        Baud rate (default: ${BAUD})
  -h, --help         Show this help

Examples:
  ./scripts/monitor-esp32.sh
  ./scripts/monitor-esp32.sh --port /dev/ttyACM0 --baud 115200
  ./scripts/monitor-esp32.sh -- --timestamps
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --esp32-dir)
      ESP32_DIR="${2:-}"
      shift 2
      ;;
    --idf-path)
      IDF_PATH="${2:-}"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --baud)
      BAUD="${2:-}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      EXTRA_ARGS=("$@")
      break
      ;;
    *)
      fail "Unknown option: $1"
      ;;
    esac
  done
}

validate_inputs() {
  if [ -z "$ESP32_DIR" ]; then
    fail "--esp32-dir is empty"
  fi

  if [ -d "$ESP32_DIR" ]; then
    :
  else
    fail "ESP32 dir not found: $ESP32_DIR"
  fi

  if [ -f "${IDF_PATH}/export.sh" ]; then
    :
  else
    fail "ESP-IDF export.sh not found: ${IDF_PATH}/export.sh"
  fi

  if [[ "$BAUD" =~ ^[0-9]+$ ]]; then
    :
  else
    fail "--baud must be a number (got: $BAUD)"
  fi
}

resolve_port() {
  if [ -n "$PORT" ]; then
    if [ -e "$PORT" ]; then
      return
    else
      fail "Port not found: $PORT"
    fi
  fi

  local ports=()
  shopt -s nullglob
  ports=(/dev/ttyACM* /dev/ttyUSB*)
  shopt -u nullglob

  if [ "${#ports[@]}" -eq 0 ]; then
    fail "No serial ports found. Pass --port /dev/ttyACM0"
  fi

  if [ "${#ports[@]}" -eq 1 ]; then
    PORT="${ports[0]}"
    return
  fi

  printf "Multiple serial ports detected:\n" >&2
  printf "  %s\n" "${ports[@]}" >&2
  fail "Please specify --port."
}

main() {
  parse_args "$@"
  validate_inputs
  resolve_port

  (
    cd "$ESP32_DIR"

    # shellcheck disable=SC1090
    source "${IDF_PATH}/export.sh" >/dev/null 2>&1

    if command -v idf.py >/dev/null 2>&1; then
      :
    else
      fail "idf.py not found after sourcing ESP-IDF export.sh"
    fi

    run idf.py -p "$PORT" -b "$BAUD" monitor "${EXTRA_ARGS[@]}"
  )
}

main "$@"
