#!/bin/bash
set -euo pipefail

ID=""
LOCAL=""
REMOTE=""
KEYFILE=""
KEEPASSXC=""
STATE_DIR=""

usage() {
  cat <<EOF
Usage:
  kdbx-pull.sh \\
    --id UUID \\
    --local-path PATH \\
    --remote-path PATH \\
    --keyfile-path PATH \\
    --keepassxc PATH \\
    --state-dir PATH
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --id)
    [[ $# -ge 2 ]] || die "--id requires a value."
    [[ -z "$ID" ]] || die "--id specified more than once."
    ID="$2"
    shift 2
    ;;

  --local-path)
    [[ $# -ge 2 ]] || die "--local-path requires a value."
    [[ -z "$LOCAL" ]] || die "--local-path specified more than once."
    LOCAL="$2"
    shift 2
    ;;

  --remote-path)
    [[ $# -ge 2 ]] || die "--remote-path requires a value."
    [[ -z "$REMOTE" ]] || die "--remote-path specified more than once."
    REMOTE="$2"
    shift 2
    ;;

  --keyfile-path)
    [[ $# -ge 2 ]] || die "--keyfile-path requires a value."
    [[ -z "$KEYFILE" ]] || die "--keyfile-path specified more than once."
    KEYFILE="$2"
    shift 2
    ;;

  --keepassxc)
    [[ $# -ge 2 ]] || die "--keepassxc requires a value."
    [[ -z "$KEEPASSXC" ]] || die "--keepassxc specified more than once."
    KEEPASSXC="$2"
    shift 2
    ;;

  --state-dir)
    [[ $# -ge 2 ]] || die "--state-dir requires a value."
    [[ -z "$STATE_DIR" ]] || die "--state-dir specified more than once."
    STATE_DIR="$2"
    shift 2
    ;;

  --help | -h)
    usage
    exit 0
    ;;

  --*)
    die "unknown argument: $1"
    ;;

  *)
    die "unexpected positional argument: $1"
    ;;
  esac
done

[[ -n "$ID" ]] || die "--id is required."
[[ -n "$LOCAL" ]] || die "--local-path is required."
[[ -n "$REMOTE" ]] || die "--remote-path is required."
[[ -n "$KEYFILE" ]] || die "--keyfile-path is required."
[[ -n "$KEEPASSXC" ]] || die "--keepassxc is required."
[[ -n "$STATE_DIR" ]] || die "--state-dir is required."

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

mkdir -p "$STATE_DIR"

LOG="$STATE_DIR/sync.log"

log() {
  echo "[$(date '+%F %T')] [PULL] $1" >>"$LOG"
}

acquire_lock || exit 0

log "started"

TMP="$STATE_DIR/tmp_pull"
rm -rf "$TMP"
mkdir -p "$TMP"

cp "$LOCAL" "$TMP/local.kdbx"
cp "$REMOTE" "$TMP/remote.kdbx"

chmod 600 "$TMP"/*.kdbx "$KEYFILE"

log "merge start"

"$KEEPASSXC" merge \
  "$TMP/local.kdbx" \
  "$TMP/remote.kdbx" \
  -k "$KEYFILE" \
  --key-file-from "$KEYFILE" \
  --no-password \
  --no-password-from

log "merge end"

if ! cmp -s "$TMP/local.kdbx" "$LOCAL"; then
  cp "$TMP/local.kdbx" "$LOCAL"
  log "write LOCAL (changed)"
  date +%s >"$STATE_DIR/last_pull_time"
else
  log "skip LOCAL write (no change)"
fi

log "done"
