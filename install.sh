#!/bin/bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MODBUS_CLIENT_DIR="/opt/victronenergy/dbus-modbus-client"
GUI_DIR="/opt/victronenergy/gui/qml"
RC_LOCAL="/data/rc.local"

echo "📁 Ensuring helper scripts are executable..."
for s in restart.sh installGuiV2.sh uninstall.sh; do
    chmod a+x "$SCRIPT_DIR/$s"
    chmod 744 "$SCRIPT_DIR/$s"
done

# --- Persist install script across firmware updates ---
if [ ! -f "$RC_LOCAL" ]; then
    echo "📄 Creating rc.local..."
    echo -e "#!/bin/bash\n" > "$RC_LOCAL"
    chmod 755 "$RC_LOCAL"
fi

if ! grep -qxF "$SCRIPT_DIR/install.sh" "$RC_LOCAL"; then
    echo "📌 Adding install.sh to rc.local for persistence..."
    echo "$SCRIPT_DIR/install.sh" >> "$RC_LOCAL"
fi

# --- Patch GUI V2 ---
PATCH="$SCRIPT_DIR/PageAcInSetup_patch.qml"
GUI_FILE="$GUI_DIR/PageAcInSetup.qml"
BACKUP="$GUI_DIR/PageAcInSetup._qml"

if [ ! -f "$BACKUP" ]; then
    echo "📦 Backing up GUI file..."
    cp "$GUI_FILE" "$BACKUP"
fi

EXISTING_BLOCK="$(sed -n '/\\/\\* Eastron settings \\*\\//,/\\/\\* Eastron settings end \\*\\//p' "$GUI_FILE")"
NEW_BLOCK="$(cat "$PATCH")"

if [ "$EXISTING_BLOCK" != "$NEW_BLOCK" ]; then
    echo "🎨 Updating GUI with Eastron patch..."
    sed -i '/\\/\\* Eastron settings \\*\\//,/\\/\\* Eastron settings end \\*\\//d' "$GUI_FILE"

    EM24_LINE=$(grep -n "/\\* EM24 settings \\*/" "$GUI_FILE" | cut -d ':' -f1)
    if [ -n "$EM24_LINE" ]; then
        INSERT_LINE=$((EM24_LINE - 1))
        sed -i "${INSERT_LINE}r $PATCH" "$GUI_FILE"
        echo "🔄 Restarting GUI service..."
        svc -t /service/gui
    else
        echo "❌ Could not locate insertion point: '/\\* EM24 settings \\*/' not found in $GUI_FILE"
    fi
else
    echo "✅ GUI patch already present. Skipping."
fi

# --- Patch dbus-modbus-client ---
MODBUS_FILE="$MODBUS_CLIENT_DIR/dbus-modbus-client.py"
MODBUS_BACKUP="$MODBUS_CLIENT_DIR/dbus-modbus-client._py"

if [ ! -f "$MODBUS_BACKUP" ]; then
    echo "📦 Backing up Modbus client..."
    cp "$MODBUS_FILE" "$MODBUS_BACKUP"
fi

# Symlink our Eastron module into modbus client folder
ln -sf "$SCRIPT_DIR/Eastron.py" "$MODBUS_CLIENT_DIR/Eastron.py"
echo "🔗 Linked Eastron.py into $MODBUS_CLIENT_DIR"

if ! grep -q "import Eastron" "$MODBUS_FILE"; then
    echo "🧩 Patching dbus-modbus-client to import Eastron..."
    IMPORT_LINE=$(grep -n "import carlo_gavazzi" "$MODBUS_FILE" | cut -d ':' -f1)
    if [ -n "$IMPORT_LINE" ]; then
        sed -i "${IMPORT_LINE}i import Eastron" "$MODBUS_FILE"
        "$SCRIPT_DIR/restart.sh"
    else
        echo "❌ Failed to patch: 'import carlo_gavazzi' not found."
    fi
else
    echo "✅ Modbus client already patched with Eastron. Skipping."
fi
