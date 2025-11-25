# Elemental Shaman - Quick Reference Guide

## 🌀 What Is This Feature?

Your Primary Resource Bar (Maelstrom) can now change **text and bar colors** automatically based on what you can do in combat! This helps you make better decisions without needing WeakAuras.

**Note:** These settings only appear when you're playing as an **Elemental Shaman**. Other specs and classes won't see these options.

Both text and bar coloring can be enabled/disabled independently, and you can adjust the out-of-combat opacity with a slider.

## 🎨 Color Guide

| Color | What It Means | When You See It |
|-------|---------------|-----------------|
| 🔴 **Red** | Maelstrom Capped | You're at 100% Maelstrom - spend it! (HIGHEST PRIORITY) |
| 🟣 **Pink/Purple** | Elemental Blast Ready | Elemental Blast is off cooldown and castable |
| 🟡 **Yellow** | Earthquake Ready | You have enough Maelstrom to cast Earthquake (60+) |
| 🔵 **Light Blue** | Out of Combat | When you're not fighting (with adjustable opacity 0-100%) |
| 🎨 **Resource Color** | Default | Your selected primary resource color when in combat |

## 📋 Priority System

If multiple conditions are true at once, the colors follow this priority (highest to lowest):

1. **Red** (100% Maelstrom) - Most urgent, you're wasting resource!
2. **Pink/Purple** (Elemental Blast) - Important cooldown ready
3. **Yellow** (Earthquake) - AoE spender available
4. **Light Blue** (Out of Combat) - Resting (lowest priority)
5. **Resource Color** (Default) - Your selected primary resource color

## 💡 How To Use

### Example Combat Flow:

1. **Pull enemies** → Text shows your **resource color** (building Maelstrom)
2. **Cast Lightning Bolt** × 3 → Text turns **yellow** (Earthquake ready at 60+)
3. **Elemental Blast comes off cooldown** → Text turns **pink/purple** (priority over yellow)
4. **Keep building Maelstrom** → Text stays **pink/purple** (Elemental Blast priority)
5. **Build to 100 Maelstrom** → Text turns **red** (warning: capped! Highest priority!)
6. **Spend Maelstrom** → Text returns to appropriate color based on what's available

## ⚙️ Configuration

### How to Enable/Disable:

1. Enter **Edit Mode** (Esc → Edit Mode)
2. Select the **Primary Resource Bar**
3. Find these options in the settings panel (only visible for Elemental Shaman):
   - **Enable Elemental Shaman Specific Text Color** - Toggle dynamic text coloring (enabled by default)
   - **Enable Elemental Shaman Specific Bar Color** - Toggle dynamic bar coloring (disabled by default)
   - **Out of Combat Opacity** - Slider to adjust transparency when out of combat (0-100%, default 50%)
4. Adjust settings as desired
5. Exit Edit Mode to save

### Requirements:

- Must be playing **Elemental Shaman** specialization (settings are hidden for other specs)
- Primary Resource Bar must be enabled and visible
- Enable one or both color options in Edit Mode settings
- Opacity slider only affects out-of-combat appearance

## ❓ FAQ

### Q: Why don't I see these settings?
**A:** These settings only appear when you're playing as an Elemental Shaman. If you're Enhancement or Restoration, or a different class, the settings won't be visible.

### Q: Can I turn this feature off?
**A:** Yes! Go to Edit Mode, select the Primary Resource Bar, and uncheck "Enable Elemental Shaman Specific Text Color" and/or "Enable Elemental Shaman Specific Bar Color".

### Q: Can I use text coloring without bar coloring (or vice versa)?
**A:** Yes! Both options are independent. You can enable just text color, just bar color, or both together.

### Q: What does the Out of Combat Opacity slider do?
**A:** It controls how transparent the text and bar appear when you're out of combat (light blue color). Set it to 0 for fully transparent, 100 (1.0) for fully opaque, or anywhere in between. Default is 50% (0.5).

### Q: Can I change the colors?
**A:** Not yet! This feature uses fixed colors, but custom colors may be added in a future update.

### Q: Does this work for Enhancement or Restoration?
**A:** No, this feature is specifically designed for Elemental Shaman only.

### Q: Why isn't my text changing color?
**A:** Check these things:
- Are you Elemental spec? (Not Enhancement or Resto)
- Is your Primary Resource Bar visible?
- Do you have Earthquake/Elemental Blast learned?
- Are you in combat? (Out of combat shows light blue with opacity)
- Try `/reload` to refresh the UI

### Q: Does this replace my WeakAuras?
**A:** Yes! This provides the same functionality natively in the addon, which will work in patch 12.0 when WeakAuras may have compatibility issues.

### Q: Will this slow down my game?
**A:** No! The feature is highly optimized and uses WoW's built-in event system. It only updates when something actually changes.

### Q: Why is bar color disabled by default?
**A:** Bar color is disabled by default because if your text and bar are the same color, the text might be hard to read. Enable it if you want both, but make sure text remains visible!

### Q: Does the opacity slider work in combat?
**A:** No, the opacity slider only affects the out-of-combat appearance (light blue color). In combat, all colors are fully opaque for maximum visibility.

## 🎯 Pro Tips

1. **Watch for Red** - When text turns red, you're capping Maelstrom. Spend it immediately!

2. **Purple Priority** - Pink/purple means Elemental Blast is ready. This is often your best single-target damage.

3. **Yellow for AoE** - Yellow means you can Earthquake. Great for multiple enemies!

4. **Light Blue = Prep Time** - Out of combat, the light blue reminds you to prepare for the next pull. Adjust opacity if it's too faint or too bright!

5. **Muscle Memory** - After using this for a while, you'll react to the colors without thinking!

6. **Adjust Opacity** - If the out-of-combat color is too faint, increase the opacity slider. If it's too bright, decrease it.

## 🔧 Troubleshooting

### Text shows wrong color
- Make sure you're in Elemental spec
- Verify spells are learned (Earthquake, Elemental Blast)
- Check if you're at 100% Maelstrom (red overrides everything else)
- Try `/reload ui`

### Colors don't match the guide
- Make sure the feature is enabled (check Edit Mode settings)
- Check if you have custom text color overrides set in the addon settings
- The override system takes priority over dynamic colors

### Feature not responding
- Make sure you're playing Elemental Shaman (settings hidden for other specs)
- Verify checkboxes are enabled in Edit Mode (text is enabled by default, bar is not)
- Try adjusting the opacity slider if out-of-combat colors seem invisible

### Feature not working after patch
- Make sure you have the latest version of the addon
- Check CurseForge or GitHub for updates

## 📝 Technical Details

If you're curious about how it works:
- Uses spell usability checks (`IsSpellUsable`)
- Monitors combat state and power levels
- Updates only when conditions change (event-driven)
- Zero performance impact

For full technical documentation, see `ELEMENTAL_SHAMAN_FEATURE.md`.

## 🙏 Feedback

Found a bug or have a suggestion? Please report it:
- GitHub: [Issues Page](https://github.com/Snsei987/SenseiClassResourceBar/issues)
- CurseForge: [Comment Section](https://www.curseforge.com/wow/addons/senseiclassresourcebar)

---

**Enjoy your enhanced Elemental Shaman experience!** ⚡🌊