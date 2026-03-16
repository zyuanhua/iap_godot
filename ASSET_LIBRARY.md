# Google IAP Ultimate - Asset Library Listing

## Title
Google IAP Ultimate - Commercial Edition

## Description

**The Ultimate Google Play Billing Library 6+ Integration Plugin for Godot 4.x!**

### 🚀 Get Started in 5 Minutes, Zero-Code Experience Needed!

Perfect for indie game developers who want to add in-app purchases without the hassle! This all-in-one solution provides everything you need to monetize your Godot game on Google Play Store.

---

## ✨ Key Features

### 1. **Visual UI Configuration Panel**
- Drag-and-drop interface for easy product setup
- Real-time code preview and generation
- No coding required for basic setup
- Save/load configurations in JSON format

### 2. **Auto Item Grant System**
- 3-step setup for automatic item delivery
- Payment success → auto-grant items
- Customizable item mapping (coins, VIP, no-ads, etc.)
- Complete signal system for notifications

### 3. **Anti-Cheat Server Verification**
- Prevent player cheating with server-side validation
- Optional switch for flexible control
- JSON parameter passing (sku + token)
- Complete success/failure callbacks
- Items only granted after verification succeeds

### 4. **One-Click CSV Export**
- Export directly to Google Play official CSV format
- Format: `Product ID,Name,Price`
- UTF-8 encoding support
- Save to user directory

### 5. **Full Godot 4.x Compatibility**
- Perfectly supports Godot 4.0, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7
- No version-specific API issues
- Compatibility fallback mechanisms
- Tested across all 4.x versions

### 6. **Google Play Billing Library 6.2.1**
- Latest Billing Library integration
- One-time purchases support
- Subscriptions support
- Purchase restoration
- Product consumption

### 7. **Complete Documentation & Examples**
- 5-minute quick start tutorial
- Multiple example scripts (minimal, item grant, server verification)
- Comprehensive API documentation
- Server-side implementation guides (Node.js, Python, PHP)

---

## 🎯 Who Is This For?

- **Indie Game Developers** - No prior IAP experience needed
- **Hobbyists** - Quick and easy integration
- **Commercial Studios** - Production-ready, battle-tested
- **Teams** - Clear documentation and examples

---

## 📦 What's Included

```
addons/
└── google_iap/
    ├── plugin.cfg                    # Plugin configuration
    ├── GoogleIAP.gd                  # Core GDScript singleton
    ├── GoogleIAPEditorPlugin.gd      # Editor plugin (UI panel)
    ├── GoogleIAPConfigPanel.tscn    # Configuration panel scene
    ├── GoogleIAPConfigPanel.gd      # Configuration panel logic
    └── icon.svg                      # Plugin icon

android/
└── build/
    ├── build.gradle                  # Android build config
    ├── AndroidManifest.xml           # Android manifest
    └── src/com/godot/plugin/googleiap/
        └── GoogleIAP.java            # Android plugin implementation

examples/
├── IAPExample.gd                     # Basic usage example
├── IAPGameExample.tscn              # Game example scene
├── IAPGameExample.gd                # Game example logic
├── IAP_Minimal_Example.gd           # 3-step minimal example
├── IAP_ItemGrant_Example.gd         # Item grant system example
├── IAP_ServerVerification_Example.gd # Server verification example
└── SERVER_VERIFICATION_GUIDE.md     # Detailed server verification guide

README.md                              # Complete documentation
LICENSE                                # Commercial license
```

---

## 💰 Pricing

**$49.99 - Commercial Edition**

---

## 📋 Requirements

- Godot Engine 4.0 or higher (4.0 ~ 4.7 supported)
- Android export template
- Google Play Developer Account
- Basic GDScript knowledge (for advanced customization)

---

## 🔧 Quick Start

### Step 1: Install (1 minute)
1. Copy `addons/google_iap` to your project's `addons` folder
2. Enable plugin in Project Settings → Plugins

### Step 2: Configure (2 minutes)
1. Open configuration panel: Project → Tools → Google IAP → Config Panel
2. Add your products (SKU, name, price, type)
3. Save configuration

### Step 3: Integrate (2 minutes)
```gdscript
extends Node

func _ready() -> void:
    GoogleIAP.item_granted.connect(_on_item_granted)
    GoogleIAP.initialize()

func buy_coins() -> void:
    GoogleIAP.purchase_product("com.yourgame.coins.100")

func _on_item_granted(product_id: String, item_data: Dictionary):
    print("Received: ", item_data.get("item_name"))
```

✅ **Done!** Your game now has complete IAP functionality!

---

## 🛡️ Security Features

- Server-side purchase verification
- Items only granted after verification
- Optional verification switch
- Complete error handling and logging
- Timeout handling for HTTP requests

---

## 📞 Support

- Complete documentation included
- Multiple example scripts
- Server-side implementation guides
- Active community support

---

## 📄 License

Commercial License - Can be used in commercial projects.

---

**Make your game profitable with Google IAP Ultimate!** 🎮💰
