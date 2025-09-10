# Copilot Instructions for Shop_PaintBall Plugin

## Repository Overview

This repository contains a **SourceMod plugin** that provides paintball functionality for Source engine games (CS:GO, CS2, TF2, etc.). The plugin integrates with the Shop-Core framework to allow players to purchase paintball effects that create colorful decals when their bullets hit surfaces.

**Current Version**: 2.1.3 (as defined in plugin info)
**Author**: FrozDark (HLModders LLC)
**URL**: www.hlmod.ru

### Key Components
- **Main Plugin**: `addons/sourcemod/scripting/Shop_PaintBall.sp` (269 lines)
- **Custom Include**: `addons/sourcemod/scripting/include/smartdm.inc` (model parsing utilities)
- **Configuration**: `addons/sourcemod/configs/paintball.txt` (paintball material paths)
- **Translations**: `addons/sourcemod/translations/shop_paintball.phrases.txt` (EN/RU support)
- **Build Config**: `sourceknight.yaml` (SourceKnight build system)

## Technical Stack & Dependencies

### Core Technologies
- **Language**: SourcePawn (SourceMod scripting language)
- **Platform**: SourceMod 1.11.0+ (minimum supported version)
- **Build Tool**: SourceKnight (Python-based SourceMod build system)
- **Compiler**: SourcePawn Compiler (spcomp)

### External Dependencies
- **SourceMod Framework**: Base modding platform for Source engine games
- **Shop-Core Plugin**: Item management system (https://github.com/srcdslab/sm-plugin-Shop-Core)
- **Game Engine**: Source Engine (Valve games)

### Required Include Files
```sourcepawn
#include <sourcemod>     // Core SourceMod API
#include <sdktools>      // Extended SDK tools
#include <smartdm>       // Custom utility functions (local)
#include <shop>          // Shop-Core integration (external)
```

## Project Structure

```
├── .github/
│   ├── workflows/ci.yml         # CI/CD pipeline
│   └── copilot-instructions.md  # This file
├── addons/sourcemod/
│   ├── scripting/
│   │   ├── Shop_PaintBall.sp    # Main plugin source
│   │   └── include/smartdm.inc  # Local utility functions
│   ├── configs/paintball.txt    # Material file paths
│   └── translations/
│       └── shop_paintball.phrases.txt  # Localization
├── sourceknight.yaml            # Build configuration
└── .gitignore                   # Git ignore rules
```

## Build & Development Workflow

### Building the Plugin

1. **Using SourceKnight** (Recommended):
   ```bash
   # Install SourceKnight
   pip install sourceknight
   
   # Build the plugin
   sourceknight build
   ```

2. **Manual Compilation**:
   ```bash
   # Requires SourceMod compiler in PATH
   spcomp -i"addons/sourcemod/scripting/include" addons/sourcemod/scripting/Shop_PaintBall.sp
   ```

### Development Setup

1. **Dependencies**: Ensure SourceMod and Shop-Core are available
2. **IDE**: Use any text editor with SourcePawn syntax highlighting
3. **Testing**: Test on a SourceMod-enabled game server
4. **Debugging**: Use SourceMod's built-in error logging

### CI/CD Pipeline

The repository uses GitHub Actions for automated building and releases:
- **Triggers**: Push, PR, manual dispatch
- **Build Matrix**: Ubuntu 24.04
- **Artifacts**: Compiled plugins with configs and translations
- **Auto-releases**: Creates "latest" tag on main branch pushes

## Code Style & Conventions

### SourcePawn Standards
```sourcepawn
#pragma semicolon 1          // Require semicolons
#pragma newdecls required    // Require new declaration syntax

// Naming conventions
bool g_clientsPaintballEnabled[MAXPLAYERS + 1];  // Global: g_ prefix
ConVar g_hPrice, g_hSellPrice;                   // ConVars: g_h prefix
int g_iPrice, g_iSellPrice;                      // Integers: g_i prefix
ArrayList g_hArrayMaterials;                     // Handles: g_h prefix

// Function naming
public void OnPluginStart()        // PascalCase for public functions
void LoadPaintballMaterials()      // PascalCase for local functions
```

### Memory Management
```sourcepawn
// Proper handle cleanup - CRITICAL for preventing memory leaks
delete filehandle;              // Use delete, not CloseHandle (new syntax)
CloseHandle(filehandle);        // Legacy syntax - still acceptable
filehandle = null;              // Set to null after deletion

// ArrayList/StringMap management (this plugin uses legacy syntax)
g_hArrayMaterials = CreateArray();     // Legacy creation
ClearArray(g_hArrayMaterials);         // Legacy clear - acceptable for reuse

// Modern syntax (preferred for new code)
delete g_hArrayMaterials;       // Delete old instance
g_hArrayMaterials = new ArrayList();  // Create new instance
// Avoid .Clear() on new syntax - use delete/recreate pattern
```

### Shop Integration Pattern
```sourcepawn
public void Shop_Started() {
    CategoryId category_id = Shop_RegisterCategory(CATEGORY, "Name", "Desc", OnCategoryDisplay, OnCategoryDescription);
    if (Shop_StartItem(category_id, ITEM)) {
        Shop_SetInfo("Name", "", price, sellPrice, Item_Togglable, duration);
        Shop_SetCallbacks(OnItemRegistered, OnItemUsed, _, OnDisplay, OnDescription);
        Shop_EndItem();
    }
}
```

## Common Development Tasks

### Adding New Paintball Materials
1. Add material paths to `addons/sourcemod/configs/paintball.txt`
2. Ensure materials exist in game files or are downloaded
3. Plugin automatically loads materials on map start

### Modifying Plugin Behavior
- **Price Changes**: Edit ConVar definitions in `OnPluginStart()`
- **Duration Changes**: Modify `g_hDuration` ConVar
- **Effect Logic**: Edit `Event_BulletImpact()` function
- **Translations**: Update `shop_paintball.phrases.txt`

### Adding New Languages
1. Add language block to `shop_paintball.phrases.txt`:
   ```
   "paintball" {
       "en"  "Paintball"
       "ru"  "Пэйнтбол"
       "de"  "Farbkugel"  // New language
   }
   ```

### Debugging Common Issues

#### Plugin Not Loading
- Check SourceMod logs: `addons/sourcemod/logs/errors_*.log`
- Verify dependencies: Shop-Core must be loaded first
- Check include file availability

#### Materials Not Working
- Verify material paths in `paintball.txt`
- Ensure materials are precached by the game
- Check file permissions and existence

#### Shop Integration Issues
- Confirm Shop-Core is running: `sm plugins list shop`
- Check category/item registration in Shop menu
- Verify callback functions are properly implemented

## Performance Considerations

### Critical Optimizations
```sourcepawn
// Cache expensive operations
int size = GetArraySize(g_hArrayMaterials);  // Cache array size
if (!size) return;  // Early return optimization

// Efficient random selection
int index = GetArrayCell(g_hArrayMaterials, Math_GetRandomInt(0, size-1));

// Minimize string operations in hot paths
// Event_BulletImpact() is called frequently - keep it lightweight
```

### Memory Management
- **Always** use `delete` for handle cleanup
- **Never** use `.Clear()` on ArrayList/StringMap
- Set handles to `null` after deletion
- Use transactions for multiple SQL operations

## Testing & Validation

### Manual Testing
1. **Load Plugin**: Start SourceMod server with plugin
2. **Shop Integration**: Verify item appears in shop menu
3. **Purchase Flow**: Test buying/selling paintball effect
4. **Effect Testing**: Shoot weapons and verify paintball decals appear
5. **Translation Testing**: Test with different client languages

### Automated Testing
- CI pipeline compiles and packages plugin automatically
- No unit tests (SourcePawn limitations)
- Runtime testing requires game server environment

## Troubleshooting Guide

### Build Issues
```bash
# Missing dependencies
Error: Cannot read include file "shop.inc"
# Solution: Ensure Shop-Core include files are available

# Compilation errors
Error: Undefined symbol "Shop_RegisterCategory"
# Solution: Check Shop-Core version compatibility
```

### Runtime Issues
```
# Plugin load failure
[SM] Plugin "Shop_PaintBall" failed to load: Unable to load plugin
# Check: SourceMod version, dependencies, file permissions

# Materials not loading
[Shop_PaintBall] No materials loaded from config
# Check: paintball.txt file path and content, file permissions
```

### Common Fixes
1. **Dependency Issues**: Verify Shop-Core is loaded and up-to-date
2. **File Path Issues**: Use absolute paths in SourceMod directory structure
3. **Permission Issues**: Ensure web server/game server can read files
4. **Version Conflicts**: Check SourceMod and plugin version compatibility

## Quick Reference

### Key Files to Modify
- **Plugin Logic**: `Shop_PaintBall.sp`
- **Materials**: `paintball.txt`
- **Text/UI**: `shop_paintball.phrases.txt`
- **Build Config**: `sourceknight.yaml`

### Important Functions
- `OnPluginStart()`: Initialization and ConVar setup
- `Shop_Started()`: Shop integration and item registration  
- `Event_BulletImpact()`: Core paintball effect logic
- `LoadPaintballMaterials()`: Material loading from config

### ConVars
- `sm_shop_paintball_price` (default: "500"): Purchase price
- `sm_shop_paintball_sellprice` (default: "250"): Sell price (-1 = unsellable) 
- `sm_shop_paintball_duration` (default: "86400"): Effect duration in seconds (0 = forever)

This plugin exemplifies proper SourceMod development practices with Shop integration, efficient memory management, and comprehensive localization support.