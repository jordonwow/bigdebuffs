-- Table for function "addDebuffs(aura)" in BigDebuffs Code
BigDebuffsUnwantedSpells = {
    80354, -- Temporal Displacement
    371070, -- Rotting From Within
    390435, -- Exhaustion
    57723, -- Exhaustion
    206151, -- Challenger's Burden
    264689, -- Fatigued
}

-- Iterate through unwanted debuffs
function BigDebuffsUnwantedSpell(spellId)
    for _, unwantedSpellID in ipairs(BigDebuffsUnwantedSpells) do
        if unwantedSpellID == spellId then
            return true
        end
    end

    return false
end