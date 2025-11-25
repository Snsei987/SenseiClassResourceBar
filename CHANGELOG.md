# Changelog

All notable changes to Sensei Class Resource Bar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Elemental Shaman Dynamic Resource Coloring**: Primary Resource Bar now features intelligent text and bar color changes based on combat state and spell availability
  - Red (#FF0000) when Maelstrom reaches 100% (highest priority)
  - Pink/Purple (#D468FF) when Elemental Blast is castable
  - Yellow (#FFC900) when Earthquake is castable
  - Light Blue (#21D1FF) with adjustable opacity when out of combat (lowest priority)
  - Default: Uses player's selected primary resource color
  - Priority system ensures the most important condition is always displayed
  - Automatically updates in real-time as conditions change
  - **Configuration Options** (Only visible for Elemental Shaman):
    - "Enable Elemental Shaman Specific Text Color" - Toggle dynamic text coloring (enabled by default)
    - "Enable Elemental Shaman Specific Bar Color" - Toggle dynamic bar coloring (disabled by default)
    - "Out of Combat Opacity" - Slider to control transparency (0-100%, default 50%)
    - Settings display actual spec name instead of generic "Class/Spec"
    - All options can be configured independently per layout in Edit Mode settings
    - Settings only appear when playing as Elemental Shaman
  - Opacity slider applies to both text and bar colors when out of combat
  - User can enable both text and bar coloring simultaneously or use them independently

### Technical
- Added `GetElementalShamanTextColor(opacity)` function to Color.lua helper with opacity parameter
- Added `GetElementalShamanBarColor(opacity)` function to Color.lua helper with opacity parameter
- Enhanced PrimaryResourceBar with `SPELL_UPDATE_USABLE` and `UNIT_POWER_FREQUENT` event handling
- Overridden `GetResourceNumberColor()` for spec-specific text color logic (Elemental Shaman spec ID: 262)
- Overridden `GetBarColor()` for spec-specific bar color logic (Elemental Shaman spec ID: 262)
- Conditional settings loading - only shows Elemental Shaman options when appropriate
- Dynamic spec name detection for setting labels
- StatusBar alpha channel support for opacity control

---

## [Previous Releases]

For information about previous releases, please visit the [CurseForge page](https://www.curseforge.com/wow/addons/senseiclassresourcebar) or [GitHub Releases](https://github.com/Snsei987/SenseiClassResourceBar/releases).