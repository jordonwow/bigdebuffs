#!/usr/bin/env fish

# Try to find the location of the _retail_ wow folder
set dirs "C:/Program Files (x86)/World of Warcraft/_retail_" "$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_" "/Applications/World of Warcraft/_retail_"

for d in $dirs
    if test -d "$d"
        set addonFolder "$d/Interface/AddOns/DjuxDebuffs"
        break
    end
end

if test -z "$addonFolder"
    set_color red
    echo "Unable to determine World of Warcraft retail folder. Checked the following locations:"
    echo
    set_color yellow
    for d in $dirs
        echo "\"$d\""
    end
    exit 1
end

# Move the addon files to the retail addons folder
mkdir -p "$addonFolder"
cp -r ./* "$addonFolder"

set_color green
echo "Updated addon folder."
