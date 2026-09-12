#!/bin/bash
set -euo pipefail

ID=""
WATCH_PATH=""
FSWATCH=""
DEBOUNCE=""
IGNORE_WINDOW=""
STATE_DIR=""
OPERATION=""

LOCAL=""
REMOTE=""
KEYFILE=""
KEEPASSXC=""

usage() {
    cat <<EOF2
Usage:
  kdbx-pull-runner.sh \
    --id UUID \
    --watch-path PATH \
    --fswatch PATH \
    --debounce SECONDS \
    --ignore-window SECONDS \
    --state-dir PATH \
    --operation PATH \
    --local-path PATH \
    --remote-path PATH \
    --keyfile-path PATH \
    --keepassxc PATH
EOF2
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
        --watch-path)
            [[ $# -ge 2 ]] || die "--watch-path requires a value."
            [[ -z "$WATCH_PATH" ]] || die "--watch-path specified more than once."
            WATCH_PATH="$2"
            shift 2
            ;;
        --fswatch)
            [[ $# -ge 2 ]] || die "--fswatch requires a value."
            [[ -z "$FSWATCH" ]] || die "--fswatch specified more than once."
            FSWATCH="$2"
            shift 2
            ;;
        --debounce)
            [[ $# -ge 2 ]] || die "--debounce requires a value."
            [[ -z "$DEBOUNCE" ]] || die "--debounce specified more than once."
            DEBOUNCE="$2"
            shift 2
            ;;
        --ignore-window)
            [[ $# -ge 2 ]] || die "--ignore-window requires a value."
            [[ -z "$IGNORE_WINDOW" ]] || die "--ignore-window specified more than once."
            IGNORE_WINDOW="$2"
            shift 2
            ;;
        --state-dir)
            [[ $# -ge 2 ]] || die "--state-dir requires a value."
            [[ -z "$STATE_DIR" ]] || die "--state-dir specified more than once."
            STATE_DIR="$2"
            shift 2
            ;;
        --operation)
            [[ $# -ge 2 ]] || die "--operation requires a value."
            [[ -z "$OPERATION" ]] || die "--operation specified more than once."
            OPERATION="$2"
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
        --help|-h)
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
[[ -n "$WATCH_PATH" ]] || die "--watch-path is required."
[[ -n "$FSWATCH" ]] || die "--fswatch is required."
[[ -n "$DEBOUNCE" ]] || die "--debounce is required."
[[ -n "$IGNORE_WINDOW" ]] || die "--ignore-window is required."
[[ -n "$STATE_DIR" ]] || die "--state-dir is required."
[[ -n "$OPERATION" ]] || die "--operation is required."
[[ -n "$LOCAL" ]] || die "--local-path is required."
[[ -n "$REMOTE" ]] || die "--remote-path is required."
[[ -n "$KEYFILE" ]] || die "--keyfile-path is required."
[[ -n "$KEEPASSXC" ]] || die "--keepassxc is required."

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

mkdir -p "$STATE_DIR"

LOG="$STATE_DIR/sync.log"
LAST_PUSH_TIME="$STATE_DIR/last_push_time"
PULL_EVENT_TOKEN="$STATE_DIR/pull_event_token"

log() {
    echo "[$(date '+%F %T')] [PULL-RUNNER] $1" >>"$LOG"
}

schedule_pull() {
    log "schedule_pull called"

    local TOKEN
    TOKEN=$(uuidgen)

    printf '%s\n' "$TOKEN" >"$PULL_EVENT_TOKEN"

    (
        sleep "$DEBOUNCE"

        local LAST
        LAST=$(cat "$PULL_EVENT_TOKEN")

        if [[ "$LAST" != "$TOKEN" ]]; then
            log "pull debounced"
            exit 0
        fi

        log "trigger pull"

        "$OPERATION" \
            --id "$ID" \
            --local-path "$LOCAL" \
            --remote-path "$REMOTE" \
            --keyfile-path "$KEYFILE" \
            --keepassxc "$KEEPASSXC" \
            --state-dir "$STATE_DIR"
    ) &
}

log "started"
log "watch REMOTE: $WATCH_PATH"

"$FSWATCH" -0 -r "$WATCH_PATH" |
    while IFS= read -r -d '' EVENT; do
        log "event: $EVENT"

        if [[ -f "$LAST_PUSH_TIME" ]]; then
            NOW=$(date +%s)
            LAST=$(cat "$LAST_PUSH_TIME")

            if (( NOW - LAST < IGNORE_WINDOW )); then
                log "ignored push-originated remote event"
                continue
            fi
        fi

        schedule_pull
    done
