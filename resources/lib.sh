#!/bin/bash

acquire_lock() {
    exec 200>"$STATE_DIR/lock"
    flock -n 200 || return 1
}