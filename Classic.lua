local addonName, addon = ...

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end

local BUFF_DEFENSIVE = "buffs_defensive"
local BUFF_OFFENSIVE = "buffs_offensive"
local BUFF_OTHER = "buffs_other"
local INTERRUPT = "interrupts"
local CROWD_CONTROL = "cc"
local ROOT = "roots"
local IMMUNITY = "immunities"

addon.Units = {
    "player",
    "pet",
    "target",
    "party1",
    "party2",
    "party3",
    "party4",
}

-- Make sure we always see these debuffs, but don't make them bigger
addon.PriorityDebuffs = {
    770, -- Faerie Fire
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
}

addon.Spells = {

    -- Racials

    [20600] = { type = BUFF_OFFENSIVE }, -- Perception
    [7744] = { type = BUFF_OFFENSIVE }, -- Will of the Forsaken
    [20549] = { type = CROWD_CONTROL }, -- War Stomp
    [20594] = { type = BUFF_OFFENSIVE }, -- Stoneform

    -- Other

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

    -- Interrupts
    [15752] = { type = INTERRUPT, duration = 10 }, -- Linken's Boomerang Disarm
    [19244] = { type = INTERRUPT, duration = 6 }, -- Spell Lock - Rank 1 (Warlock)
        [19647] = { parent = 19244, duration = 8 }, -- Spell Lock - Rank 2 (Warlock)
    [8042] = { type = INTERRUPT, duration = 2 }, -- Earth Shock (Shaman)
        [8044] = { parent = 8042 },
        [8045] = { parent = 8042 },
        [8046] = { parent = 8042 },
        [10412] = { parent = 8042 },
        [10413] = { parent = 8042 },
        [10414] = { parent = 8042 },
    [16979] = { type = INTERRUPT, duration = 4 }, -- Feral Charge (Druid)
    [2139] = { type = INTERRUPT, duration = 10 }, -- Counterspell (Mage)
    [1766] = { type = INTERRUPT, duration = 5 }, -- Kick (Rogue)
        [1767] = { parent = 1766 },
        [1768] = { parent = 1766 },
        [1769] = { parent = 1766 },
    [14251] = { type = INTERRUPT, duration = 6 }, -- Riposte (Rogue)
    [6552] = { type = INTERRUPT, duration = 4 }, -- Pummel
        [6554] = { parent = 6552 },
    [72] = { type = INTERRUPT, duration = 6 }, -- Shield Bash
        [1671] = { parent = 72 },
        [1672] = { parent = 72 },

    -- Priest

    [17] = { type = BUFF_DEFENSIVE }, -- Power Word: Shield
    [592] = { parent = 17 }, -- Power Word: Shield
        [600] = { parent = 17 },
        [3747] = { parent = 17 },
        [6065] = { parent = 17 },
        [6066] = { parent = 17 },
        [10898] = { parent = 17 },
        [10899] = { parent = 17 },
        [10900] = { parent = 17 },
        [10901] = { parent = 17 },
    [605] = { type = CROWD_CONTROL }, -- Mind Control
        [10911] = { parent = 605 },
        [10912] = { parent = 605 },
    [8122] = { type = CROWD_CONTROL }, -- Psychic Scream
        [8124] = { parent = 8122 },
        [10888] = { parent = 8122 },
        [10890] = { parent = 8122 },
    [10060] = { type = BUFF_OFFENSIVE }, -- Power Infusion
    [15269] = { type = CROWD_CONTROL }, -- Blackout

    -- Warlock

    [24259] = { type = CROWD_CONTROL }, -- Spell Lock Silence
    [6358] = { type = CROWD_CONTROL }, -- Seduction
    [5782] = { type = CROWD_CONTROL }, -- Fear
        [6213] = { parent = 5782 },
        [6215] = { parent = 5782 },
    [5484] = { type = CROWD_CONTROL }, -- Howl of Terror
        [17928] = { parent = 5484 },
    [710] = { type = CROWD_CONTROL }, -- Banish
        [18647] = { parent = 710 },
    [6789] = { type = CROWD_CONTROL }, -- Death Coil
        [17925] = { parent = 6789 },
        [17926] = { parent = 6789 },
    [6229] = { type = BUFF_DEFENSIVE }, -- Shadow Ward
        [11739] = { parent = 6229 },
        [11740] = { parent = 6229 },
        [28610] = { parent = 6229 },
    [7812] = { type = BUFF_DEFENSIVE }, -- Sacrifice
        [19438] = { parent = 7812 },
        [19440] = { parent = 7812 },
        [19441] = { parent = 7812 },
        [19442] = { parent = 7812 },
        [19443] = { parent = 7812 },
    [18093] = { type = CROWD_CONTROL }, -- Pyroclasm

    -- Shaman

    [8178] = { type = IMMUNITY }, -- Grounding Totem Effect
    [16188] = { type = BUFF_DEFENSIVE }, -- Nature's Swiftness

    -- Paladin

    [1022] = { type = IMMUNITY },-- Blessing of Protection
        [5599] = { parent = 1022 },
        [10278] = { parent = 1022 },
    [498] = { type = IMMUNITY }, -- Divine Shield
        [5573] = { parent = 498 },
        [642] = { parent = 498 },
        [1020] = { parent = 498 },
    [853] = { type = CROWD_CONTROL }, -- Hammer of Justice
        [5588] = { parent = 853 },
        [5589] = { parent = 853 },
        [10308] = { parent = 853 },
    [1044] = { type = BUFF_DEFENSIVE }, -- Blessing of Freedom
    [20066] = { type = CROWD_CONTROL }, -- Repentance
    [20170] = { type = CROWD_CONTROL }, -- Seal of Justice stun

    -- Hunter

    [13159] = { type = BUFF_OFFENSIVE }, -- Aspect of the Pack
        [5118] = { parent = 13159 }, -- Aspect of the Cheetah
    [1513] = { type = CROWD_CONTROL }, -- Scare Beast
        [14326] = { parent = 1513 },
        [14327] = { parent = 1513 },
    [19410] = { type = CROWD_CONTROL }, -- Concussive Shot Stun
    [3045] = { type = BUFF_OFFENSIVE }, -- Rapid Fire
    [19263] = { type = BUFF_DEFENSIVE }, -- Deterrence
    [19574] = { type = BUFF_OFFENSIVE }, -- Bestial Wrath
    [3355] = { type = CROWD_CONTROL }, -- Freezing Trap
        [14308] = { parent = 3355 },
        [14309] = { parent = 3355 },
    [19229] = { type = ROOT }, -- Wing Clip Root
    [19306] = { type = ROOT }, -- Counterattack Root
        [20909] = { parent = 19306 },
        [20910] = { parent = 19306 },
    [19386] = { type = CROWD_CONTROL }, --Wyvern Sting
        [24132] = { parent = 19386 },
        [24133] = { parent = 19386 },
    [19185] = { type = ROOT }, -- Entrapment
    [19503] = { type = CROWD_CONTROL }, -- Scatter Shot
    [25999] = { type = ROOT }, -- Boar Charge

    -- Druid

    [22812] = { type = BUFF_DEFENSIVE }, -- Barkskin
    [19975] = { type = ROOT }, -- Nature's Grasp
    [339] = { type = ROOT }, -- Entangling Roots
        [1062] = { parent = 339 },
        [5195] = { parent = 339 },
        [5196] = { parent = 339 },
        [9852] = { parent = 339 },
        [9853] = { parent = 339 },
    [2637] = { type = CROWD_CONTROL }, -- Hibernate
        [18657] = { parent = 2637 },
        [18658] = { parent = 2637 },
    [29166] = { type = BUFF_OFFENSIVE }, -- Innervate
    [9005] = { type = CROWD_CONTROL }, -- Pounce Stun
        [9823] = { parent = 9005 },
        [9827] = { parent = 9005 },
    [16922] = { type = CROWD_CONTROL }, -- Starfire Stun
    [5211] = { type = CROWD_CONTROL}, -- Bash
        [6798] = { parent = 5211 },
        [8983] = { parent = 5211 },
    [16979] = { type = ROOT }, -- Feral Charge
    [1850] = { type = BUFF_OFFENSIVE }, -- Dash
        [9821] = { parent = 1850 },
    [16689] = { type = BUFF_OFFENSIVE }, -- Nature's Grasp Buff
        [16810] = { parent = 16689 },
        [16811] = { parent = 16689 },
        [16812] = { parent = 16689 },
        [16813] = { parent = 16689 },
        [17329] = { parent = 16689 },

    -- Mage

    [18469] = { type = CROWD_CONTROL }, -- Improved Counterspell
    [118] = { type = CROWD_CONTROL }, -- Polymorph
        [12824] = { parent = 118 },
        [12825] = { parent = 118 },
        [12826] = { parent = 118 },
        [28270] = { parent = 118 },
        [28271] = { parent = 118 },
        [28272] = { parent = 118 },
    [11426] = { type = BUFF_DEFENSIVE }, -- Ice Barrier
        [13031] = { parent = 11426 },
        [13032] = { parent = 11426 },
        [13033] = { parent = 11426 },
    [543] = { type = BUFF_DEFENSIVE }, -- Fire Ward
        [8457] = { parent = 543 },
        [8458] = { parent = 543 },
        [10223] = { parent = 543 },
        [10225] = { parent = 543 },
    [6143] = { type = BUFF_DEFENSIVE }, -- Frost Ward
        [8461] = { parent = 6143 },
        [8462] = { parent = 6143 },
        [10177] = { parent = 6143 },
        [28609] = { parent = 6143 },
    [12355] = { type = CROWD_CONTROL }, -- Impact Stun
    [12494] = { type = ROOT }, -- Frostbite
    [122] = { type = ROOT }, -- Frost Nova
        [865] = { parent = 122 },
        [6131] = { parent = 122 },
        [10230] = { parent = 122 },
    [12042] = { type = BUFF_OFFENSIVE }, -- Arcane Power
    [11958] = { type = IMMUNITY }, -- Ice Block
    [12051] = { type = BUFF_OFFENSIVE }, -- Evocation
    [1463] = { type = BUFF_DEFENSIVE }, -- Mana Shield
    [8494] = { parent = 1463 },
    [8495] = { parent = 1463 },
    [10191] = { parent = 1463 },
    [10192] = { parent = 1463 },
    [10193] = { parent = 1463 },

    -- Rogue

    [18425] = { type = CROWD_CONTROL }, -- Improved Kick
    [13750] = { type = BUFF_OFFENSIVE}, -- Adrenaline Rush
    [13877] = { type = BUFF_OFFENSIVE}, -- Blade Flurry
    [1833] = { type = CROWD_CONTROL }, -- Cheap Shot
    [408] = { type = CROWD_CONTROL }, -- Kidney Shot
        [8643] = { parent = 408 },
    [2070] = { type = CROWD_CONTROL }, -- Sap
        [6770] = { parent = 2070 },
        [11297] = { parent = 2070 },
    [2094] = { type = CROWD_CONTROL }, -- Blind
    [2983] = { type = BUFF_OFFENSIVE }, -- Sprint
        [8696] = { parent = 2983 },
        [11305] = { parent = 2983 },
    [5277] = { type = BUFF_DEFENSIVE }, -- Evasion
    [1776] = { type = CROWD_CONTROL }, -- Gouge
        [1777] = { parent = 1776 },
        [8629] = { parent = 1776 },
        [8629] = { parent = 1776 },
        [11285] = { parent = 1776 },
        [11286] = { parent = 1776 },
    [14278] = { type = BUFF_DEFENSIVE }, -- Ghostly Strike

    -- Warrior

    [18498] = { type = CROWD_CONTROL }, -- Improved Shield Bash
    [20230] = { type = IMMUNITY }, -- Retaliation
    [1719] = { type = BUFF_OFFENSIVE }, -- Recklessness
    [871] = { type = BUFF_DEFENSIVE }, -- Shield Wall
    [12328] = { type = BUFF_OFFENSIVE }, -- Death Wish
    [23694] = { type = ROOT }, -- Improved Hamstring
    [18499] = { type = BUFF_OFFENSIVE}, -- Berserker Rage
    [20253] = { type = CROWD_CONTROL }, -- Intercept Stun
        [20614] = { parent = 20253 },
        [20615] = { parent = 20253 },
    [12798] = { type = CROWD_CONTROL }, -- Revenge Stun
    [12809] = { type = CROWD_CONTROL }, -- Concussion Blow
    [7922] = { type = CROWD_CONTROL }, -- Charge Stun
    [5530] = { type = CROWD_CONTROL }, -- Mace Spec Stun (Warrior & Rogue)

}
