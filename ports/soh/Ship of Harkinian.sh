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

# Source Device Info
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

# Set variables
GAMEDIR="/$directory/ports/soh"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

cd $GAMEDIR

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:/usr/lib":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG=$sdl_controllerconfig

# Permissions
$ESUDO chmod 666 /dev/tty0
$ESUDO chmod 666 /dev/tty1
$ESUDO chmod 777 $GAMEDIR/assets/extractor/otrgen
$ESUDO chmod 777 $GAMEDIR/assets/extractor/ZAPD.out

# List of compatibility firmwares
CFW_NAMES="ArkOS:ArkOS wuMMLe:ArkOS AeUX:knulli:TrimUI"

# Check if the current CFW name is in the list
contains() {
    local value="$CFW_NAME"
    local item
    local tmp=$IFS
    IFS=":" # Use : as the delimiter
    echo "Checking if CFW_NAME '$value' is in the list..."
    for item in $CFW_NAMES; do
        echo "Comparing '$item' with '$value'..."
        if [ "$item" = "$value" ]; then
            echo "Match found: '$item'"
            IFS=$tmp
            return 0
        fi
    done
    echo "No match found for '$value'."
    IFS=$tmp
    return 1
}

# If it's in the list use the compatibility binary
if contains "$CFW_NAME" $CFW_NAMES; then
    cp -f "$GAMEDIR/bin/compatibility.elf" "$GAMEDIR/soh.elf"
    if [ "$(find ./mods -name '*.otr')" ]; then
        echo "WARNING: .OTR MODS FOUND! PERFORMANCE WILL BE LOW IF ENABLED!!" > $CUR_TTY
    fi
else
    cp -f "$GAMEDIR/bin/performance.elf" "$GAMEDIR/soh.elf"
fi

if [ ! -f "oot.otr" ] || [ ! -f "oot-mq.otr" ]; then
    # Ensure we have a rom file before attempting to generate otr
    if ls *.*64 1> /dev/null 2>&1; then
        $GPTOKEYB "love" &
        ./love patcher -f "assets/extractor/otrgen" -g "Ship of Harkinian" -t "about 5 minutes"
        $ESUDO kill -9 $(pidof gptokeyb)
    else
        echo "Missing oot.otr or oot-mq.otr. If you meant to try to generate one, make sure tyour rom is in this folder."
    fi
fi

# Check if OTR files were generated
if [ ! -f "oot.otr" ] && [ ! -f "oot-mq.otr" ]; then
    echo "No otr files, can't run the game!"
    exit 1
fi

# Run the game
$ESUDO chmod 777 $GAMEDIR/soh.elf
echo "Loading, please wait... (might take a while!)" > $CUR_TTY
$GPTOKEYB "soh.elf" -c "soh.gptk" & 
./soh.elf

# Cleanup
rm -rf "$GAMEDIR/logs/"
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events & 
printf "\033c" > /dev/tty1
printf "\033c" > /dev/tty0
