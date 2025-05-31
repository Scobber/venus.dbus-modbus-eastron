#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MODBUS_CLIENT_DIR="/opt/victronenergy/dbus-modbus-client"
RC_LOCAL="/data/rc.local"

# --- Restore GUI V2 QML ---
echo "🔍 Searching for patched PageAcInSetup.qml..."

GUI_FILE="$(find / -path '*/gui/qml/PageAcInSetup.qml' 2>/dev/null | head -n 1)"
BACKUP="${GUI_FILE%/*}/PageAcInSetup._qml"

if [ -z "$GUI_FILE" ]; then
    echo "⚠️ GUI QML file not found — nothing to restore"
else
    if [ -f "$BACKUP" ]; then
        echo "🧼 Restoring original GUI QML from backup..."
        cp "$BACKUP" "$GUI_FILE"
        [ -d /service/gui ] && svc -t /service/gui || echo "⚠️ GUI service not found"
    else
        echo "⚠️ No backup found at $BACKUP — cannot restore original GUI"
    fi
fi

# --- Unpatch dbus-modbus-client ---
MODBUS_FILE="$MODBUS_CLIENT_DIR/dbus-modbus-client.py"
MODBUS_BACKUP="$MODBUS_CLIENT_DIR/dbus-modbus-client._py"

if [ -f "$MODBUS_BACKUP" ]; then
    echo "♻️ Restoring Modbus client..."
    cp "$MODBUS_BACKUP" "$MODBUS_FILE"
    rm -f "$MODBUS_BACKUP"
fi

if [ -f "$MODBUS_CLIENT_DIR/Eastron.py" ]; then
    echo "🧹 Removing Eastron.py..."
    rm -f "$MODBUS_CLIENT_DIR/Eastron.py"
fi

# --- Clean rc.local ---
echo "🧽 Cleaning install.sh from rc.local if present..."
if [ -f "$RC_LOCAL" ]; then
    grep -vxF "$SCRIPT_DIR/install.sh" "$RC_LOCAL" > /data/temp.local || true
    mv /data/temp.local "$RC_LOCAL"
    chmod 755 "$RC_LOCAL"
fi

# --- Restart services ---
"$SCRIPT_DIR/restart.sh"
