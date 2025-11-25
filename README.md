# 🌀 **Sensei Class Resource Bar**

[![GitHub Release](https://img.shields.io/github/v/release/Snsei987/SenseiClassResourceBar?style=for-the-badge)](https://github.com/Snsei987/SenseiClassResourceBar/releases/latest) ![CurseForge Game Versions](https://img.shields.io/curseforge/game-versions/1383623?style=for-the-badge&logo=battledotnet) [![CurseForge Downloads](https://img.shields.io/curseforge/dt/1383623?style=for-the-badge&logo=curseforge&label=Downloads)](https://www.curseforge.com/wow/addons/senseiclassresourcebar)

**Sensei Class Resource Bar** is a lightweight, fully customizable resource display addon for World of Warcraft.  
It automatically adapts to your character’s **class, specialization, and shapeshift form**, showing your **primary** and **secondary** resources in clean, modern bars that you can freely move, resize, and restyle through **Edit Mode**.

***

## ✨ Features

***

## 🎯 Dynamic Resource Tracking

Automatically detects your character’s current resource type:

**Health Bar**

**Primary Resources Supported**  
Mana, Rage, Energy, Focus, Fury, Runic Power, Astral Power, and more.

**Secondary Resources Supported**

*   **Paladin** → Holy Power
*   **Rogue** → Combo Points
*   **Monk** → Chi / **Stagger** (Brewmaster)
*   **Warlock** → Soul Shards (shows partial resource)
*   **Death Knight** → Runes (with cooldown timers per rune)
*   **Evoker** → Essence
*   **Mage** → Arcane Charges
*   **Druid** → Combo Points (Cat Form)
*   **Demon Hunter** → Soul (Devourer) ⚠️ It needs to have the Player Frame visible

**Elemental Shaman Dynamic Resource Coloring:**  
The Primary Resource Bar can automatically change text and bar colors based on combat state and spell availability (priority order, highest first):
*   🔴 Maelstrom at 100% → Red (#FF0000) - Highest priority
*   🟣 Elemental Blast Castable → Pink/Purple (#D468FF)
*   🟡 Earthquake Castable → Yellow (#FFC900)
*   🔵 Out of Combat → Light Blue (#21D1FF) with adjustable opacity
*   Default: Uses your selected primary resource color

**Configuration:** *(Only visible for Elemental Shaman)*
*   ✅ **Enable Elemental Shaman Specific Text Color** - Toggle dynamic text coloring (enabled by default)
*   ⚪ **Enable Elemental Shaman Specific Bar Color** - Toggle dynamic bar coloring (disabled by default)
*   🎚️ **Out of Combat Opacity** - Slider to adjust transparency when out of combat (0-100%, default 50%)
*   All options can be configured independently in Edit Mode settings
*   Settings are only shown when playing as Elemental Shaman

**Ebon Might as a standalone bar** ⚠️ It needs to have the Player Frame visible

**Druid Form Adaptive Support:**  
Automatically switches to Mana, Energy, Rage, or Astral Power depending on current shapeshift form.

***

## 🧩 Edit Mode Integration

Built on **LibEditMode**, offering seamless integration with Blizzard’s modern UI:

*   Move and reposition bars anywhere on your screen
*   Resize and restyle without extra menus
*   Every setting is **per-layout**, meaning different UI layouts can have unique bar setups

***

## ⚙️ Customization Options

Each bar (Primary & Secondary) has its own configuration:

### **Appearance & Layout**

*   📏 Adjustable **width**, **height**, and **overall scale**
*   ✏️ Customizable **font**, **size**, and **outline**
*   🖼 Multiple **foreground textures**, **backgrounds**, and **border styles**
*   🎯 Text alignment (Left / Center / Right), Font, Size
*   🎨 All the resources color are editable
*   ⭐ Support for LibSharedMedia-3.0

### **Behavior**

*   💬 Toggle resource number text
*   🔄 Optional **smooth animation** for bar updating
*   🕶 Visibility rules:
    *   Always visible
    *   In combat
    *   With target
    *   Target OR combat
    *   Hidden
*   ✔️ Tick marks for segmented resources (Combo Points, Chi, Holy Power, Essence, etc.)
*   💧 Optional **Mana as percentage**
*   ⏱ Rune-specific cooldown text for Death Knights
*   🎨 Class/Spec specific dynamic coloring with opacity control (Elemental Shaman)

### **Hide default Blizzard UI**

*   Option to hide Blizzard Player Frame
*   Option to hide Blizzard secondary resource bars (Combo Points, Essence, Holy Power, Arcane Charges, etc.)

### **Advanced**

*   🔗 Width syncing with the Cooldown Manager :
    *   Essential Cooldowns
    *   Utility Cooldowns

***

## 🔧 Performance

*   Lightweight and efficient
*   Event-driven updates (no constant polling)
*   Minimal CPU usage
*   No overhead when the bar is hidden or disabled
*   Uses clean Blizzard-style textures for a cohesive UI look