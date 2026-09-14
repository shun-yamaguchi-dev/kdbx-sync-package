#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

BUILD_SCRIPT="$PROJECT_ROOT/scripts/build.sh"
BUILD_DIR="$PROJECT_ROOT/build"
APP="$BUILD_DIR/KDBX Sync.app"

APPLICATIONS_DIR="$HOME/Applications"
INSTALL_APP="$APPLICATIONS_DIR/KDBX Sync.app"

BIN_DIR="$HOME/.local/bin"
CLI="$BIN_DIR/kdbx-sync"

echo "==> Building KDBX Sync"
"$BUILD_SCRIPT"

echo "==> Installing application"
mkdir -p "$APPLICATIONS_DIR"

rm -rf "$INSTALL_APP"

cp -R "$APP" "$INSTALL_APP"

echo "==> Installing CLI"
mkdir -p "$BIN_DIR"

cat >"$CLI" <<EOF
#!/bin/bash
set -euo pipefail

APP="\$HOME/Applications/KDBX Sync.app"

exec "\$APP/Contents/MacOS/KDBXSync" "\$@"
EOF

chmod +x "$CLI"

echo "==> Installation complete"
echo "Application: $INSTALL_APP"
echo "CLI:         $CLI"
