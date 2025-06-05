local addonName, addon = ...

local BUFF_DEFENSIVE = "buffs_defensive"
local BUFF_OFFENSIVE = "buffs_offensive"
local DEBUFF_OFFENSIVE = "debuffs_offensive"
local BUFF_OTHER = "buffs_other"
local INTERRUPT = "interrupts"
local CROWD_CONTROL = "cc"
local ROOT = "roots"
local IMMUNITY = "immunities"
local IMMUNITY_SPELL = "immunities_spells"

addon.Units = {
    "player",
    "pet",
    "target",
    "focus",
    "party1",
    "party2",
    "party3",
    "party4",
    "arena1",
    "arena2",
    "arena3",
    "arena4",
    "arena5",
}

-- Show one of these when a big debuff is displayed
addon.WarningDebuffs = {
    30108, -- Unstable Affliction
    34914, -- Vampiric Touch
}

-- Make sure we always see these debuffs, but don't make them bigger
addon.PriorityDebuffs = {
    770, -- Faerie Fire
    16857, -- Faerie Fire (Feral)
    12294, -- Mortal Strike
    21551, -- Mortal Strike
    21552, -- Mortal Strike
    21553, -- Mortal Strike
    9035, -- Hex of Weakness
    19281, -- Hex of Weakness
    19282, -- Hex of Weakness
    19283, -- Hex of Weakness
    19284, -- Hex of Weakness
    19285, -- Hex of Weakness
    23230, -- Blood Fury Debuff
    23605, -- Nightfall, Spell Vulnerability
}

addon.Spells = {

    -- Racials

    [7744] = { type = BUFF_OFFENSIVE }, -- Will of the Forsaken
    [20549] = { type = CROWD_CONTROL }, -- War Stomp
    [20594] = { type = BUFF_OFFENSIVE }, -- Stoneform
    [20572] = { type = BUFF_OFFENSIVE }, -- Blood Fury
    [28730] = { type = CROWD_CONTROL, }, -- Arcane Torrent (Mana)
    [25046] = { type = CROWD_CONTROL, }, -- Arcane Torrent (Energy)
    [50613] = { type = CROWD_CONTROL, }, -- Arcane Torrent (Runic Power)
    [58984] = { type = BUFF_DEFENSIVE }, -- Shadowmeld

    -- Other

    [13099] = { type = ROOT }, -- Net-o-Matic
    [13119] = { type = ROOT }, -- Net-o-Matic
    [13120] = { type = ROOT }, -- Net-o-Matic
    [13138] = { type = ROOT }, -- Net-o-Matic
    [13139] = { type = ROOT }, -- Net-o-Matic
    [16566] = { type = ROOT }, -- Net-o-Matic
    [23723] = { type = BUFF_OFFENSIVE }, -- Mind Quickening Gem
    [30456] = { type = BUFF_DEFENSIVE }, -- Nigh-Invulnerability
    [30457] = { type = CROWD_CONTROL }, -- Complete Vulnerability
    [33961] = { type = IMMUNITY_SPELL }, -- Spell Reflection (Sethekk Initiate)
    [23451] = { type = BUFF_OFFENSIVE }, -- Battleground Speed buff
    [23493] = { type = BUFF_DEFENSIVE }, -- Battleground Heal buff
    [23505] = { type = BUFF_OFFENSIVE }, -- Battleground Damage buff
    [6615] = { type = BUFF_OFFENSIVE }, -- Free Action Potion
    [24364] = { type = BUFF_OFFENSIVE }, -- Living Action Potion
    [3169] = { type = IMMUNITY }, -- Limited Invulnerability Potion
    [16621] = { type = IMMUNITY }, -- Invulnerable Mail
    [1090] = { type = CROWD_CONTROL }, -- Magic Dust
    [13327] = { type = CROWD_CONTROL }, -- Reckless Charge
    [835] = { type = CROWD_CONTROL }, -- Tidal Charm
    [11359] = { type = BUFF_OFFENSIVE }, -- Restorative Potion
    [5024] = { type = BUFF_OFFENSIVE }, -- Skull of Impending Doom
    [2379] = { type = BUFF_OFFENSIVE }, -- Swiftness Potion
    [5134] = { type = CROWD_CONTROL }, -- Flash Bomb
    [23097] = { type = BUFF_OFFENSIVE }, -- Fire Reflector
    [23131] = { type = BUFF_OFFENSIVE }, -- Frost Reflector
    [23132] = { type = BUFF_OFFENSIVE }, -- Shadow Reflector
    [19769] = { type = CROWD_CONTROL }, -- Thorium Grenade
    [4068] = { type = CROWD_CONTROL }, -- Iron Grenade
    [23506] = { type = BUFF_DEFENSIVE }, -- Arena Grand Master trinket
    [29506] = { type = BUFF_DEFENSIVE }, -- Burrower's Shell trinket
    [12733] = { type = BUFF_OFFENSIVE }, -- Blacksmith trinket, Fear immunity
    [15753] = { type = CROWD_CONTROL }, -- Linken's Boomerang Stun
    [14530] = { type = BUFF_OFFENSIVE }, -- Nifty Stopwatch
    [13237] = { type = CROWD_CONTROL }, -- Goblin Mortar trinket
    [14253] = { type = BUFF_OFFENSIVE }, -- Black Husk Shield
    [9175] = { type = BUFF_OFFENSIVE }, -- Swift Boots
    [13141] = { type = BUFF_OFFENSIVE }, -- Gnomish Rocket Boots
    [8892] = { type = BUFF_OFFENSIVE }, -- Goblin Rocket Boots
    [9774] = { type = BUFF_OFFENSIVE }, -- Spider Belt & Ornate Mithril Boots
    [18798] = { type = CROWD_CONTROL }, -- Freezing Band
    [22734] = { type = BUFF_OTHER }, -- Drink
        [46755] = { parent = 22734 }, -- Drink
        [27089] = { parent = 22734 }, -- Drink
        [43183] = { parent = 22734 }, -- Drink
        [57073] = { parent = 22734 }, -- Drink
    [23605] = { type = BUFF_OTHER }, -- Nightfall, Spell Vulnerability
    [13494] = { type = BUFF_OFFENSIVE }, -- Manual Crowd Pummeler Haste buff

    -- Interrupts

    [15752] = { type = INTERRUPT, duration = 10 }, -- Linken's Boomerang Disarm
    [19647] = { type = INTERRUPT, duration = 6 }, -- Spell Lock - Rank 2 (Warlock)
    [13491] = { type = INTERRUPT, duration = 5 }, -- Iron Knuckles
    [16979] = { type = INTERRUPT, duration = 4 }, -- Feral Charge (Druid)
    [2139] = { type = INTERRUPT, duration = 8 }, -- Counterspell (Mage)
    [1766] = { type = INTERRUPT, duration = 5 }, -- Kick (Rogue)
    [26679] = { type = INTERRUPT, duration = 3 }, -- Deadly Throw
    [6552] = { type = INTERRUPT, duration = 4 }, -- Pummel
    [29443] = { type = INTERRUPT, duration = 10 }, -- Clutch of Foresight
    [80965] = { type = INTERRUPT, duration = 4 }, -- Skull Bash (Cat)
    [80964] = { type = INTERRUPT, duration = 4 }, -- Skull Bash (Bear)

    -- Death Knight

    [45524] = { type = ROOT }, -- Chains of Ice
    [47476] = { type = CROWD_CONTROL, },  -- Strangulate
    [91800] = { type = CROWD_CONTROL, },  -- Gnaw
    [47484] = { type = BUFF_DEFENSIVE, }, -- Huddle (Ghoul)
    [47528] = { type = INTERRUPT, duration = 4, },  -- Mind Freeze
    [48707] = { type = IMMUNITY_SPELL, },  -- Anti-Magic Shell
    [48792] = { type = BUFF_DEFENSIVE, },  -- Icebound Fortitude
    [49028] = { type = BUFF_OFFENSIVE, },  -- Dancing Rune Weapon // might not work - spell id vs aura
    [49039] = { type = IMMUNITY_SPELL, },  -- Lichborne
    [49203] = { type = CROWD_CONTROL, }, -- Hungering Cold
    [50461] = { type = BUFF_DEFENSIVE, },  -- Anti-Magic Zone
    [49016] = { type = BUFF_OFFENSIVE, },  -- Unholy Frenzy
    [91802] = { type = INTERRUPT, duration = 2 },  -- Shambling Rush (pet dk kick)
    [91797] = { type = CROWD_CONTROL },  -- Monstrous Blow (dk abom stun)

    -- Cataclysm

    [49206] = { type = DEBUFF_OFFENSIVE, },  -- Summon Gargoyle

    -- Priest

    -- WoTLK
    [20711] = { type = BUFF_DEFENSIVE, },  -- Spirit of Redemption
    [47585] = { type = IMMUNITY, },  -- Dispersion
    [47788] = { type = BUFF_DEFENSIVE, },  -- Guardian Spirit
    [64044] = { type = CROWD_CONTROL, }, -- Psychic Horror (Horrify)
    [64058] = { type = CROWD_CONTROL, }, -- Psychic Horror (Disarm)
    [64843] = { type = BUFF_DEFENSIVE, },  -- Divine Hymn
    [64901] = { type = BUFF_DEFENSIVE, }, -- Hymn of Hope

    [17] = { type = BUFF_DEFENSIVE }, -- Power Word: Shield
    [453] = { type = BUFF_OTHER }, -- Mind Soothe
    [605] = { type = CROWD_CONTROL }, -- Mind Control
    [8122] = { type = CROWD_CONTROL }, -- Psychic Scream
    [10060] = { type = BUFF_OFFENSIVE }, -- Power Infusion
    [15487] = { type = CROWD_CONTROL }, -- Silence
    [14892] = { type = BUFF_DEFENSIVE }, -- Inspiration
        [15362] = { parent = 14892 },
    [6346] = { type = BUFF_DEFENSIVE }, -- Fear Ward
    [9484] = { type = CROWD_CONTROL }, -- Shackle Undead
    [27827] = { type = IMMUNITY }, -- Spirit of Redemption
    [33206] = { type = BUFF_DEFENSIVE }, -- Pain Suppression
    [14751] = { type = BUFF_DEFENSIVE }, -- Inner Focus
    [87204] = { type = CROWD_CONTROL }, -- Sin and Punishment (VT dispel)
    [96267] = { type = BUFF_DEFENSIVE }, -- Strength of Soul

    -- Warlock

    -- WoTLK
    [47241] = { type = BUFF_OFFENSIVE, }, -- Metamorphosis
    [60995] = { type = CROWD_CONTROL, }, -- Demon Charge (Metamorphosis)

    [24259] = { type = CROWD_CONTROL }, -- Spell Lock Silence
    [6358] = { type = CROWD_CONTROL }, -- Seduction
    [5782] = { type = CROWD_CONTROL }, -- Fear
    [5484] = { type = CROWD_CONTROL }, -- Howl of Terror
    [710] = { type = CROWD_CONTROL }, -- Banish
    [6789] = { type = CROWD_CONTROL }, -- Death Coil
    [6229] = { type = BUFF_DEFENSIVE }, -- Shadow Ward
    [7812] = { type = BUFF_DEFENSIVE }, -- Sacrifice
    [18223] = { type = ROOT }, -- Curse of Exhaustion
    [1714] = { type = ROOT }, -- Curse of Tongues
    [22703] = { type = CROWD_CONTROL }, -- Inferno Effect
    [30283] = { type = CROWD_CONTROL }, -- Shadowfury
    [43523] = { type = CROWD_CONTROL }, -- Unstable Affliction
        [31117] = { parent = 43523 },
    [30299] = { type = BUFF_DEFENSIVE }, -- Nether Protection
        [30301] = { parent = 30299 },
    [18708] = { type = BUFF_DEFENSIVE }, -- Fel Domination
    [32752] = { type = CROWD_CONTROL }, -- Summoning Disorientation
    [19482] = { type = CROWD_CONTROL }, -- Doom Guard Stun
    [89766] = { type = CROWD_CONTROL }, -- Axe Toss (felguard stun)
    [79462] = { type = BUFF_OFFENSIVE }, -- Demon Soul: Felguard
    [79460] = { type = BUFF_OFFENSIVE }, -- Demon Soul: Felhunter
    [79459] = { type = BUFF_OFFENSIVE }, -- Demon Soul: Imp
    [79463] = { type = BUFF_OFFENSIVE }, -- Demon Soul: Succubus
    [79464] = { type = BUFF_OFFENSIVE }, -- Demon Soul: Voidwalker

    -- Shaman

    -- WoTLK
    [2825] = { type = BUFF_OFFENSIVE },  -- Bloodlust
    [16191] = { type = BUFF_OFFENSIVE }, -- Mana Tide Totem
    [32182] = { type = BUFF_OFFENSIVE },  -- Heroism
    [51514] = { type = CROWD_CONTROL, },  -- Hex
    [55277] = { type = BUFF_OTHER, }, -- Stoneclaw Totem (Absorb)
    [57994] = { type = INTERRUPT, duration = 2, },  -- Wind Shear
    [58861] = { type = CROWD_CONTROL, }, -- Bash (Spirit Wolf)
    [58875] = { type = BUFF_OTHER, }, -- Spirit Walk (Spirit Wolf)
    [63685] = { type = ROOT, }, -- Freeze (Enhancement)
    [64695] = { type = ROOT, }, -- Earthgrab (Elemental)

    [8178] = { type = IMMUNITY_SPELL }, -- Grounding Totem Effect
    [16188] = { type = BUFF_DEFENSIVE }, -- Nature's Swiftness
    [12548] = { type = ROOT }, -- Frost Shock
    [39796] = { type = CROWD_CONTROL }, -- Stoneclaw Totem
    [16166] = { type = BUFF_OFFENSIVE }, -- Elemental Mastery
    [30823] = { type = BUFF_DEFENSIVE }, -- Shamanistic Rage

    -- Paladin

    -- WoTLK
    [25771] = { type = BUFF_OTHER, }, -- Forbearance
    [31821] = { type = BUFF_DEFENSIVE, },  -- Aura Mastery
    [54428] = { type = BUFF_OTHER, }, -- Divine Plea
    [59578] = { type = BUFF_OTHER, }, -- The Art of War
    [31935] = { type = CROWD_CONTROL, }, -- Silenced - Avenger's Shield
    [64205] = { type = BUFF_DEFENSIVE, }, -- Divine Sacrifice

    [1022] = { type = IMMUNITY },-- Blessing of Protection
    [498] = { type = BUFF_DEFENSIVE }, -- Divine Protection
    [642] = { type = IMMUNITY }, -- Divine Shield
    [853] = { type = CROWD_CONTROL }, -- Hammer of Justice
    [1044] = { type = BUFF_DEFENSIVE }, -- Blessing of Freedom
    [20066] = { type = CROWD_CONTROL }, -- Repentance
    [20170] = { type = CROWD_CONTROL }, -- Seal of Justice stun
    [6940] = { type = BUFF_DEFENSIVE }, -- Blessing of Sacrifice
    [10326] = { type = CROWD_CONTROL }, -- Turn Evil
    [31884] = { type = BUFF_OFFENSIVE }, -- Avenging Wrath
    [31842] = { type = BUFF_DEFENSIVE }, -- Divine Illumination

    -- Cataclysm

    [96231] = { type = INTERRUPT, duration = 4 }, -- Rebuke
    [85696] = { type = BUFF_OFFENSIVE }, -- Zealotry

    -- Hunter

    -- WoTLK
    [1742] = { type = BUFF_DEFENSIVE, }, -- Cower (Pet)
    [26064] = { type = BUFF_DEFENSIVE, }, -- Shell Shield (Pet)
    [26090] = { type = INTERRUPT, duration = 2, }, -- Pummel (Pet)
    [53271] = { type = BUFF_DEFENSIVE, },  -- Master's Call
    [53476] = { type = BUFF_DEFENSIVE, }, -- Intervene (Pet)
    [53480] = { type = BUFF_DEFENSIVE, },  -- Roar of Sacrifice (Hunter Pet Skill)

    [13159] = { type = BUFF_OFFENSIVE }, -- Aspect of the Pack
        [5118] = { parent = 13159 }, -- Aspect of the Cheetah
    [1513] = { type = CROWD_CONTROL }, -- Scare Beast
    [3045] = { type = BUFF_OFFENSIVE }, -- Rapid Fire
    [19263] = { type = IMMUNITY }, -- Deterrence
    [19574] = { type = BUFF_OFFENSIVE }, -- Bestial Wrath
    [3355] = { type = CROWD_CONTROL }, -- Freezing Trap
    [19306] = { type = ROOT }, -- Counterattack Root
    [19386] = { type = CROWD_CONTROL }, --Wyvern Sting
    [19185] = { type = ROOT }, -- Entrapment
        [64803] = { parent = 19185 },
    [19503] = { type = CROWD_CONTROL }, -- Scatter Shot
    [25999] = { type = ROOT }, -- Boar Charge
    [34490] = { type = CROWD_CONTROL }, -- Silencing Shot
    [34471] = { type = IMMUNITY_SPELL }, -- The Beast Within
    [5384] = { type = BUFF_DEFENSIVE }, -- Feign Death
    [24394] = { type = CROWD_CONTROL }, -- Intimidation
    [19577] = { type = BUFF_OFFENSIVE, parent = 24394 }, -- Intimidation (Buff)
    [50479] = { type = INTERRUPT, duration = 2},  -- Nether Shock (nether ray pet kick)
    [90327] = { type = ROOT }, -- Lock Jaw (dog pet root)
    [50245] = { type = ROOT }, -- Pin (crab pet root)
    [52825] = { type = ROOT }, -- Swoop (carrion bird pet root)
    [54706] = { type = ROOT }, -- Venom Web Spray (silithid pet root)
    [4167] = { type = ROOT }, -- Web (spider pet root)
    [96201] = { type = ROOT }, -- Web Wrap (shale spider pet root)
    [90337] = { type = CROWD_CONTROL }, -- Bad Manner (monkey stun)
    [50519] = { type = CROWD_CONTROL }, -- Sonic Blast (bat pet stun)
    [50541] = { type = CROWD_CONTROL }, -- Clench (scorpid pet disarm)
    [91644] = { type = CROWD_CONTROL }, -- Snatch (bird of prey pet disarm)
    [50318] = { type = CROWD_CONTROL }, -- Serenity Dust (moth pet silence)
    [56626] = { type = CROWD_CONTROL }, -- Sting (wasp pet stun)


    -- Druid

    -- WoTLK
    [768] = { type = BUFF_OTHER, }, -- Cat Form
    [783] = { type = BUFF_OTHER, }, -- Travel Form
    [22570] = { type = CROWD_CONTROL, duration = 3 }, -- Maim
    [22842] = { type = BUFF_DEFENSIVE, },  -- Frenzied Regeneration
    [24858] = { type = BUFF_OTHER, }, -- Moonkin Form
    [33891] = { type = BUFF_OTHER, }, -- Tree of Life
    [50334] = { type = BUFF_OFFENSIVE, },  -- Berserk
    [61336] = { type = BUFF_DEFENSIVE, },  -- Survival Instincts
    [69369] = { type = BUFF_OFFENSIVE, }, -- Predator's Swiftness

    [22812] = { type = BUFF_DEFENSIVE }, -- Barkskin
    [339] = { type = ROOT }, -- Entangling Roots
        [19975] = { parent = 339 }, -- Nature's Grasp Rank 1
    [2637] = { type = CROWD_CONTROL }, -- Hibernate
    [29166] = { type = BUFF_OFFENSIVE }, -- Innervate
    [9005] = { type = CROWD_CONTROL }, -- Pounce Stun
    [5211] = { type = CROWD_CONTROL}, -- Bash
    -- [16979] = { type = ROOT }, -- Feral Charge TODO: invalid spellId, root effect must be different than the interrupt
    [1850] = { type = BUFF_OFFENSIVE }, -- Dash
    [16689] = { type = BUFF_OFFENSIVE }, -- Nature's Grasp Buff
    [770] = { type = BUFF_OTHER }, -- Faerie Fire
        [16857] = { parent = 770 }, -- Faerie Fire (Feral)
    [33786] = { type = CROWD_CONTROL }, -- Cyclone
    [45334] = { type = ROOT }, -- Feral Charge Effect
    [17116] = { type = BUFF_DEFENSIVE }, -- Nature's Swiftness
    [81261] = { type = CROWD_CONTROL, },  -- Solar Beam
    [78675] = { type = INTERRUPT, duration = 5 }, -- Solar Beam interrupt

    -- Mage

    -- WoTLK
    [41425] = { type = BUFF_OTHER, }, -- Hypothermia
    [66] = { type = BUFF_OFFENSIVE, },  -- Invisibility
    [44544] = { type = BUFF_OFFENSIVE, }, -- Fingers of Frost
    [44572] = { type = CROWD_CONTROL, }, -- Deep Freeze
    [55021] = { type = CROWD_CONTROL, }, -- Improved Counterspell
    [64346] = { type = CROWD_CONTROL, }, -- Fiery Payback (Fire Mage Disarm)
    [82691] = { type = CROWD_CONTROL, }, -- Ring of Frost
    [83302] = { type = ROOT, }, -- Improved Cone of Cold
    [116] = { type = ROOT }, -- Frostbolt
    [44614] = { type = ROOT }, -- Frostfire Bolt
    [7321] = { type = ROOT }, -- Chilled
    [120] = { type = ROOT }, -- Cone of Cold
    [12486] = { type = ROOT }, -- Chilled
    [12487] = { type = ROOT }, -- Ice Shards

    [18469] = { type = CROWD_CONTROL }, -- Improved Counterspell
    [118] = { type = CROWD_CONTROL }, -- Polymorph
        [28271] = { parent = 118 },
        [28272] = { parent = 118 },
        [71319] = { parent = 118 },
        [61305] = { parent = 118 },
        [61721] = { parent = 118 },

    [11426] = { type = BUFF_DEFENSIVE }, -- Ice Barrier
    [543] = { type = BUFF_DEFENSIVE }, -- Fire Ward
    [12355] = { type = CROWD_CONTROL }, -- Impact Stun
    [122] = { type = ROOT }, -- Frost Nova
        [55080] = { parent = 122 }, -- Shattered Barrier
    [12042] = { type = BUFF_OFFENSIVE }, -- Arcane Power
    [45438] = { type = IMMUNITY }, -- Ice Block
    [12051] = { type = BUFF_OFFENSIVE }, -- Evocation
    [1463] = { type = BUFF_DEFENSIVE }, -- Mana Shield
    [31661] = { type = CROWD_CONTROL }, -- Dragon's Breath
    [12043] = { type = BUFF_OFFENSIVE }, -- Presence of Mind
    [33395] = { type = ROOT }, -- Freeze
    [12472] = { type = BUFF_OFFENSIVE }, -- Icy Veins
    [87023] = { type = BUFF_OTHER, }, -- Cauterize

    -- Cataclysm

    [83853] = { type = DEBUFF_OFFENSIVE, }, -- Combustion

    -- Rogue

    -- WoTLK
    [51690] = { type = BUFF_OFFENSIVE, },  -- Killing Spree
    [51713] = { type = BUFF_OFFENSIVE, }, -- Shadow Dance
    [51722] = {type = CROWD_CONTROL, }, -- Dismantle

    [18425] = { type = CROWD_CONTROL }, -- Improved Kick
    [13750] = { type = BUFF_OFFENSIVE}, -- Adrenaline Rush
    [13877] = { type = BUFF_OFFENSIVE}, -- Blade Flurry
    [1833] = { type = CROWD_CONTROL }, -- Cheap Shot
    [408] = { type = CROWD_CONTROL }, -- Kidney Shot
    [6770] = { type = CROWD_CONTROL }, -- Sap
    [2094] = { type = CROWD_CONTROL }, -- Blind
    [2983] = { type = BUFF_OFFENSIVE }, -- Sprint
    [5277] = { type = BUFF_DEFENSIVE }, -- Evasion
    [1776] = { type = CROWD_CONTROL }, -- Gouge
    [3409] = { type = ROOT }, -- Crippling Poison
    [1330] = { type = CROWD_CONTROL }, -- Garrote Silence
    [31224] = { type = IMMUNITY_SPELL }, -- Cloak of Shadows
    [45182] = { type = BUFF_DEFENSIVE }, -- Cheating Death
    [14177] = { type = BUFF_OFFENSIVE }, -- Cold Blood
    [14251] = { type = BUFF_OTHER }, -- Riposte (Rogue)
    [86759] = { type = CROWD_CONTROL }, -- Improved Kick (Rank 2)
    [74001] = { type = BUFF_DEFENSIVE }, -- Combat Readiness

    -- Warrior

    -- WoTLK
    [71] = { type = BUFF_OTHER }, -- Defensive Stance
    [2457] = { type = BUFF_OTHER }, -- Battle Stance
    [2458] = { type = BUFF_OTHER }, -- Berserker Stance
    [2565] = { type = BUFF_DEFENSIVE }, -- Shield Block
    [3411] = { type = BUFF_DEFENSIVE },  -- Intervene
    [12975] = { type = BUFF_DEFENSIVE },  -- Last Stand
    [46924] = { type = IMMUNITY, },  -- Bladestorm
    [46968] = { type = CROWD_CONTROL, },  -- Shockwave
    [55694] = { type = BUFF_DEFENSIVE },  -- Enraged Regeneration
    [60503] = { type = BUFF_OFFENSIVE, }, -- Taste for Blood
    [65925] = { type = BUFF_OFFENSIVE, }, -- Unrelenting Assault (2/2)
    [85388] = { type = CROWD_CONTROL }, -- Throwdown

    [18498] = { type = CROWD_CONTROL }, -- Improved Shield Bash
    [20230] = { type = IMMUNITY }, -- Retaliation
    [1719] = { type = BUFF_OFFENSIVE }, -- Recklessness
    [871] = { type = BUFF_DEFENSIVE }, -- Shield Wall
    [12292] = { type = BUFF_OFFENSIVE }, -- Death Wish
    [23694] = { type = ROOT }, -- Improved Hamstring
    [18499] = { type = BUFF_OFFENSIVE }, -- Berserker Rage
    [20253] = { type = CROWD_CONTROL }, -- Intercept Stun
        [20615] = { parent = 20253 },
    [12809] = { type = CROWD_CONTROL }, -- Concussion Blow
    [7922] = { type = CROWD_CONTROL }, -- Charge Stun
    [5246] = { type = CROWD_CONTROL }, -- Intimidating Shout
        [20511] = { parent = 5246 },
    [676] = { type = BUFF_OTHER }, -- Disarm
    [23920] = { type = IMMUNITY_SPELL }, -- Spell Reflection
    [12976] = { type = BUFF_DEFENSIVE }, -- Last Stand
    [12294] = { type = BUFF_OTHER }, -- Mortal Strike

}
