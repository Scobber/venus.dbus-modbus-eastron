#!/bin/bash

set -e

# Remove compiled bytecode
PYC_FILE="/opt/victronenergy/dbus-modbus-client/__pycache__/Eastron.cpython-38.pyc"
if [ -f "$PYC_FILE" ]; then
    echo "🧹 Removing cached bytecode: $PYC_FILE"
    rm -f "$PYC_FILE"
fi

# Restart logic for dbus-modbus-client or fallback
SERVICE_DIR="/service/dbus-modbus-client"
FALLBACK_NAME="dbus-modbus-client.py"

if [ -d "$SERVICE_DIR" ]; then
    echo "🔁 Restarting dbus-modbus-client via svc..."
    svc -d "$SERVICE_DIR"
    sleep 2
    svc -u "$SERVICE_DIR"
elif [ -d /service/serial-starter ]; then
    echo "🔁 Restarting serial-starter instead..."
    svc -d /service/serial-starter
    sleep 2
    svc -u /service/serial-starter
else
    echo "⚠️ svc not found for dbus-modbus-client or serial-starter — using pkill fallback"
    pkill -f "$FALLBACK_NAME" || echo "No running process found"
    sleep 2
fi

echo "✅ Restart complete."
