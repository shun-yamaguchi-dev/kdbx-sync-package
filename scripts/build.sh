#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

BUILD_DIR="$PROJECT_ROOT/build"
APP="$BUILD_DIR/KDBX Sync.app"
CONTENTS="$APP/Contents"

EXECUTABLE="$CONTENTS/MacOS/KDBXSync"
RUNTIME_DIR="$CONTENTS/Resources/Runtime"

echo "==> Building KDBXSync"
cd "$PROJECT_ROOT"
swift build -c release

echo "==> Creating app bundle"
rm -rf "$APP"

mkdir -p \
  "$CONTENTS/MacOS" \
  "$RUNTIME_DIR"

echo "==> Installing executable"
cp \
  "$PROJECT_ROOT/.build/release/KDBXSync" \
  "$EXECUTABLE"

echo "==> Installing Info.plist"
cp \
  "$PROJECT_ROOT/resources/Info.plist" \
  "$CONTENTS/Info.plist"

echo "==> Installing runtime"
cp \
  "$PROJECT_ROOT/runtime/"*.sh \
  "$RUNTIME_DIR/"

chmod +x \
  "$EXECUTABLE" \
  "$RUNTIME_DIR/"*.sh

echo "==> Build complete"
echo "$APP"
