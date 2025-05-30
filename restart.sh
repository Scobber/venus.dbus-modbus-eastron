#!/bin/bash

set -e

# Remove bytecode cache
PYC_FILE="/opt/victronenergy/dbus-modbus-client/__pycache__/Eastron.cpython-38.pyc"

if [ -f "$PYC_FILE" ]; then
    echo "🧹 Removing cached bytecode: $PYC_FILE"
    rm -f "$PYC_FILE"
fi

# Gracefully stop the dbus-modbus-client via svc
SERVICE_NAME="dbus-modbus-client"

if svc -s "$SERVICE_NAME" 2>/dev/null; then
    echo "🛑 Stopping $SERVICE_NAME via svc..."
    svc -k "$SERVICE_NAME"
else
    echo "⚠️ svc not available or service name not found — falling back to manual kill"
    pkill -f "dbus-modbus-client.py" || echo "No matching process found"
fi
