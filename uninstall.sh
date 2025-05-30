#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MODBUS_CLIENT_DIR="/opt/victronenergy/dbus-modbus-client"
GUI_FILE="/opt/victronenergy/gui/qml/PageAcInSetup.qml"
RC_LOCAL="/data/rc.local"

# === Restore dbus-modbus-client.py ===
if [ -f "$MODBUS_CLIENT_DIR/dbus-modbus-client._py" ]; then
    echo "🔁 Restoring dbus-modbus-client.py..."
    cp "$MODBUS_CLIENT_DIR/dbus-modbus-client._py" "$MODBUS_CLIENT_DIR/dbus-modbus-client.py"
    rm "$MODBUS_CLIENT_DIR/dbus-modbus-client._py"
fi

# === Remove Eastron.py from modbus-client ===
if [ -f "$MODBUS_CLIENT_DIR/Eastron.py" ]; then
    echo "🧹 Removing Eastron.py..."
    rm "$MODBUS_CLIENT_DIR/Eastron.py"
fi

# === Clean /data/rc.local ===
if [ -f "$RC_LOCAL" ]; then
    echo "🧽 Cleaning install.sh reference in rc.local..."
    grep -vxF "$SCRIPT_DIR/install.sh" "$RC_LOCAL" > /data/temp.local || true
    mv /data/temp.local "$RC_LOCAL"
    chmod 755 "$RC_LOCAL"
fi

# === Remove Eastron GUI patch ===
if grep -q "Eastron settings" "$GUI_FILE"; then
    echo "🧼 Removing Eastron GUI patch..."
    sed -i '/\\/\\* Eastron settings \\*\\//,/\\/\\* Eastron settings end \\*\\//d' "$GUI_FILE"
    svc -t /service/gui
fi

# === Restart core services ===
"$SCRIPT_DIR/restart.sh"
