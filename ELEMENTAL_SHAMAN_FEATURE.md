# Elemental Shaman Dynamic Text Color Feature

## Overview

This feature provides dynamic, condition-based text color changes for Elemental Shaman characters when viewing their Primary Resource Bar (Maelstrom). The text color automatically adapts based on combat state, spell availability, and resource levels, providing visual feedback similar to WeakAuras functionality.

## Feature Details

### Color Conditions (Priority Order)

The text color is determined by checking the following conditions in order of priority:

1. **Out of Combat** - `#21D1FF` (Light Blue with 50% opacity)
   - Applied when the player is not in combat
   - Lowest priority condition
   - Semi-transparent to distinguish from active combat

2. **Maelstrom at 100%** - `#FF0000` (Red)
   - Applied when Maelstrom resource reaches maximum capacity (150/150)
   - **HIGHEST priority in-combat condition**
   - Overrides all other spell-ready states to prevent resource waste

3. **Elemental Blast Castable** - `#D468FF` (Pink/Purple)
   - Applied when Elemental Blast (Spell ID: 117014) is usable
   - High priority for important single-target cooldown

4. **Earthquake Castable** - `#FFC900` (Yellow)
   - Applied when Earthquake (Spell ID: 61882) is usable
   - Indicates sufficient Maelstrom (60+) and spell availability for AoE

5. **Default** - User's Selected Primary Resource Color
   - Applied when in combat but none of the above conditions are met
   - Respects player's custom Maelstrom color settings
   - Typically shows when building Maelstrom below spell thresholds

### Technical Implementation

#### Files Modified

1. **`Helpers/Color.lua`**
   - Added `GetElementalShamanTextColor()` function
   - Implements the priority-based color logic
   - Uses `C_Spell.IsSpellUsable()` API for spell availability checks
   - Uses `UnitPower()` and `UnitPowerMax()` for resource level checks

2. **`Bars/PrimaryResourceBar.lua`**
   - Overridden `GetResourceNumberColor()` to detect Elemental Shaman spec (ID: 262)
   - Added custom `OnLoad()` to register additional events for Shaman class
   - Added custom `OnEvent()` to handle spell and power update events
   - Registered events: `SPELL_UPDATE_USABLE`, `UNIT_POWER_FREQUENT`

#### Event Handling

The feature responds to the following WoW events:

- **`SPELL_UPDATE_USABLE`**: Fires when spell usability changes (cooldowns, resources, etc.)
- **`UNIT_POWER_FREQUENT`**: Fires frequently when player power changes
- **`PLAYER_REGEN_ENABLED/DISABLED`**: Inherited from parent, handles combat state changes

### Code Flow

```

### Visual Logic Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    START: Update Text Color                  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────────┐
                    │ In Combat?         │
                    │ (InCombatLockdown) │
                    └─────────┬──────────┘
                              │
                   ┌──────────┴──────────┐
                   │                     │
                  NO                    YES
                   │                     │
                   ▼                     ▼
         ┌─────────────────┐   ┌─────────────────────┐
         │ 🔵 Light Blue   │   │ Maelstrom = 100%?   │
         │ (50% opacity)   │   │ (150/150)           │
         └─────────────────┘   └──────────┬──────────┘
                                           │
                                ┌──────────┴──────────┐
                                │                     │
                               YES                   NO
                                │                     │
                                ▼                     ▼
                      ┌─────────────────┐   ┌──────────────────────┐
                      │ 🔴 RED          │   │ Elemental Blast      │
                      │ (URGENT!)       │   │ Usable?              │
                      └─────────────────┘   └──────────┬───────────┘
                                                        │
                                             ┌──────────┴──────────┐
                                             │                     │
                                            YES                   NO
                                             │                     │
                                             ▼                     ▼
                                   ┌─────────────────┐   ┌──────────────────┐
                                   │ 🟣 Pink/Purple  │   │ Earthquake       │
                                   │                 │   │ Usable?          │
                                   └─────────────────┘   └──────────┬───────┘
                                                                     │
                                                          ┌──────────┴──────────┐
                                                          │                     │
                                                         YES                   NO
                                                          │                     │
                                                          ▼                     ▼
                                                ┌─────────────────┐   ┌─────────────────┐
                                                │ 🟡 Yellow       │   │ 🎨 User's       │
                                                │                 │   │ Resource Color  │
                                                └─────────────────┘   └─────────────────┘
```
PrimaryResourceBar:ApplyFontSettings()
  └─> PrimaryResourceBar:GetResourceNumberColor()
      └─> Check if player is Elemental Shaman (spec 262)
          └─> addonTable:GetElementalShamanTextColor()
              └─> Check conditions in priority order
                  └─> Return appropriate color
```

### API Requirements

- **`C_Spell.IsSpellUsable(spellID)`**: Returns `true` if spell is castable
- **`InCombatLockdown()`**: Returns `true` if player is in combat
- **`UnitPower("player", Enum.PowerType.Maelstrom)`**: Returns current Maelstrom
- **`UnitPowerMax("player", Enum.PowerType.Maelstrom)`**: Returns max Maelstrom

## Usage

### For Players

This feature is **automatically enabled** for Elemental Shaman characters. No configuration is required.

Simply use your Primary Resource Bar as normal, and the text color will dynamically update based on your combat state and available abilities.

### For Developers

To add similar dynamic color features for other specs:

1. **Add color logic function** in `Helpers/Color.lua`:
```lua
function addonTable:GetYourSpecTextColor()
    -- Implement your condition checks
    -- Return color table: { r = 0-1, g = 0-1, b = 0-1 }
end
```

2. **Override `GetResourceNumberColor()`** in the appropriate bar file:
```lua
function YourBarMixin:GetResourceNumberColor()
    local playerClass = select(2, UnitClass("player"))
    if playerClass == "YOURCLASS" then
        local spec = C_SpecializationInfo.GetSpecialization()
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
        if specID == YOUR_SPEC_ID then
            return addonTable:GetYourSpecTextColor()
        end
    end
    -- Default behavior
    return addonTable:GetOverrideTextColor(...)
end
```

3. **Register relevant events** in `OnLoad()` if needed:
```lua
function YourBarMixin:OnLoad()
    -- Parent OnLoad
    if addonTable.PowerBarMixin.OnLoad then
        addonTable.PowerBarMixin.OnLoad(self)
    end
    
    -- Register your events
    self.Frame:RegisterEvent("YOUR_EVENT")
end
```

4. **Handle events** in `OnEvent()`:
```lua
function YourBarMixin:OnEvent(event, ...)
    -- Parent OnEvent
    if addonTable.PowerBarMixin.OnEvent then
        addonTable.PowerBarMixin.OnEvent(self, event, ...)
    end
    
    -- Your event handling
    if event == "YOUR_EVENT" then
        self:ApplyFontSettings()
    end
end
```

## Performance Considerations

- Uses event-driven updates (no polling)
- Only registers additional events for Shaman class
- Only checks spec and applies logic when actually needed
- Minimal CPU overhead due to efficient condition checking
- Color calculations are lightweight RGB conversions

## Compatibility

- **Minimum WoW Version**: The War Within (11.0+)
- **API Dependencies**: 
  - `C_Spell` namespace (introduced in modern WoW)
  - `C_SpecializationInfo` API
- **Fallback**: If APIs are unavailable, defaults to standard text color behavior

## Future Enhancements

Potential improvements for this feature:

1. User-configurable color options via settings panel
2. Configurable priority order for conditions
3. Additional spell/talent-based conditions
4. Support for other Shaman specs (Enhancement, Restoration)
5. Profile-specific enable/disable toggle

## Troubleshooting

### Text color not changing

- Ensure you're playing an Elemental Shaman (spec ID 262)
- Verify the spells are learned (Earthquake, Elemental Blast)
- Check if you have the Primary Resource Bar enabled and visible

### Performance issues

- This feature uses efficient event-driven updates
- If experiencing lag, ensure you're running the latest addon version
- Check for conflicts with other addons that modify unit frames

## Credits

This feature was implemented to replace WeakAuras functionality for patch 12.0 compatibility, providing native support within the addon framework.