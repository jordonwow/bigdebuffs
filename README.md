A fork of BigDebuffs with some changes/fixes for Dragonflight. At the moment, most of these fixes were contributed by [Bicmex](https://www.youtube.com/c/Bicmex) and were found on his Discord server. All credit for the [original BigDebuffs addon](https://github.com/jordonwow/bigdebuffs) goes to the wonderful [jordonwow on GitHub](https://github.com/jordonwow).

I plan to maintain this fork for as long as the author of the original BigDebuffs remains inactive. However, please keep in mind that I did not write the original code and need to familiarize myself with it before I can fix bugs quickly or write new features.

# Download & Installation

You can download this addon from [Wago](https://addons.wago.io/addons/djuxdebuffs) or from the [GitHub releases page](https://github.com/nozzlegear/bigdebuffs/releases/latest). Curse/Overwolf is currently not supported, I recommend using [Wago's addon installer](https://addons.wago.io/) or [WowUp](https://wowup.io/). 

If you don't want to use another addon installer, you can always download the zip file from Wago or GitHub and then unzip it into your addons folder. Once unzipped, your file structure should look like this:

```
Interface
└── AddOns
    └── DjuxDebuffs
        ├── BigDebuffs.lua
        ├── BigDebuffs.toc
        └── etc
```

# BigDebuffs
BigDebuffs is an _extremely lightweight_ addon that hooks the Blizzard raid frames to increase the debuff size of crowd control effects. Additionally, it replaces unit frame portraits with debuff durations when important debuffs are present.

[Open a ticket to report any issues](https://github.com/nozzlegear/bigdebuffs/issues)

[Submit a pull request](https://github.com/nozzlegear/bigdebuffs/pulls)

## Features

### Anchor
Anchor BigDebuffs to the inner (default), left, or right of the raid frames.

![BigDebuffs Anchor Inner](https://i.imgur.com/O9Yacnl.png)
![BigDebuffs Anchor Right](https://i.imgur.com/NfADLaw.png)
![BigDebuffs Anchor Left](https://i.imgur.com/gYQ8DEM.png)

### Increase Maximum Buffs
Sets the maximum buffs displayed to 6.

![BigDebuffs Increase Maximum Buffs](https://i.imgur.com/iq5I2E4.png)

### Scale
Set the scale of the various types of debuffs.

### Warning Debuffs
Always show warning debuffs when BigDebuffs are displayed.

![BigDebuffs Special Debuffs](https://i.imgur.com/b0UWslt.png)

### Unit Frames
Show BigDebuffs on the unit frames.

![BigDebuffs Unit Frames](https://i.imgur.com/6QSbDlB.png)

### Third Party Support
BigDebuffs is fully compatible with the followings mods:

*   Z-Perl UnitFrames
*   Shadowed Unit Frames
*   ElvUI
*   Adapt
*   bUnitFrames

![BigDebuffs Z-Perl](https://i.imgur.com/ZOr4tbi.png)

### Profiles
Create custom profiles with dual specialization support.

## Configuration
To open the options panel, type `/bd`
