#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GUI_DIR="/opt/victronenergy/gui/qml"
ORIGINAL="$GUI_DIR/PageAcInSetup._qml"
TARGET="$GUI_DIR/PageAcInSetup.qml"

if [ -e "$ORIGINAL" ]; then
    echo "🔁 Restoring original PageAcInSetup.qml..."
    cp "$ORIGINAL" "$TARGET"
    echo "✅ GUI restored. Restarting GUI service..."
    svc -t /service/gui
else
    echo "⚠️ No backup found at $ORIGINAL. Nothing to restore."
fi
