#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.27.4"
FLUTTER_DIR="$PWD/flutter"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  curl -fL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz
  tar -xf /tmp/flutter.tar.xz -C "$PWD"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_DIR"

case "${1:-}" in
  install)
    flutter --version
    flutter pub get
    ;;
  build)
    flutter build web --release
    ;;
  *)
    echo "Usage: $0 {install|build}" >&2
    exit 2
    ;;
esac
