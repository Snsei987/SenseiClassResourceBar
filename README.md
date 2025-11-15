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
*   **Shaman** → Maelstrom (Elemental)
*   **Evoker** → Essence
*   **Mage** → Arcane Charges
*   **Priest** → Insanity (Shadow)
*   **Druid** → Combo Points (Cat Form)
*   **Demon Hunter** → Soul (Devourer)

**Druid Form Adaptive Support:**  
Automatically switches to Mana, Energy, Rage, or Lunar Power depending on current shapeshift form.

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
*   🎯 Text alignment (Left / Center / Right)
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