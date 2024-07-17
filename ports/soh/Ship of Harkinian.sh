#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
get_controls

# Set variables
GAMEDIR="/$directory/ports/soh"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Source Device Info
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:/usr/lib"

# Permissions
$ESUDO chmod 666 /dev/tty0
$ESUDO chmod 666 /dev/tty1

cd $GAMEDIR

# Array of compatibility firmwares
CFW_NAMES=("ArkOS" "ArkOS wuMMLe" "ArkOS AeUX" "knulli")

# Function to check if a value is in an array
contains() {
    local value="$1"
    shift
    for item; do
        if [ "$item" == "$value" ]; then
            return 0
        fi
    done
    return 1
}

# Check if the current CFW name is in the array
if contains "$CFW_NAME" "${CFW_NAMES[@]}"; then
    cp -f "$GAMEDIR/bin/compatibility.elf" soh.elf
    if [ "$(find "./mods" -name '*.otr')" ]; then
        echo "WARNING: .OTR MODS FOUND! PERFORMANCE WILL BE LOW IF ENABLED!!" > /dev/tty0
    fi
else
    cp -f "$GAMEDIR/bin/performance.elf" soh.elf
fi

# Run the game
echo "Loading, please wait... (might take a while!)" > /dev/tty0

$GPTOKEYB "soh.elf" -c "soh.gptk" & 
./soh.elf

# Cleanup
rm -rf "$GAMEDIR/logs/Ship of Harkinian.log"
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events & 
printf "\033c" > /dev/tty1
printf "\033c" > /dev/tty0
