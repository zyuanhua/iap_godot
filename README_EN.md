# Google IAP Ultimate - Commercial Edition

[![Godot Engine](https://img.shields.io/badge/Godot-4.0--4.7-%23478cbf?logo=godot-engine)](https://godotengine.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-%233DDC84?logo=android)](https://developer.android.com)
[![IAP Version](https://img.shields.io/badge/Google%20Play%20Billing-6.0%2B-blue)](https://developer.android.com/google/play/billing)

A fully compatible Godot 4.0~4.7 plugin supporting Google Play Billing Library 6+, featuring visual UI configuration, automatic code generation, one-click CSV export, intelligent item granting, and anti-cheat server-side verification. Get started in 5 minutes with zero commercial barriers.

## 🎯 Project Features

### ✨ Core Advantages
- **🚀 5-Minute Integration** - Out-of-the-box, zero configuration barrier
- **🔄 Full Version Compatibility** - Perfect support for all Godot 4.0~4.7 versions
- **🎨 Visual Configuration** - Drag-and-drop UI panel, no coding required
- **🔒 Enterprise-Grade Security** - Complete anti-cheat and server-side verification mechanisms
- **📊 Data Analytics** - Multi-platform sales data report integration

### 🛠️ Feature Overview

| Feature Module | Description | Status |
|----------------|-------------|---------|
| **SKU Management** | Visual product management with multi-vendor support | ✅ Complete |
| **Billing Service** | Google Play Billing 6+ integration | ✅ Stable |
| **Server Configuration** | Multi-account, multi-environment configuration management | ✅ Comprehensive |
| **Verification Testing** | Anti-cheat server-side verification tools | ✅ Powerful |
| **Data Analytics** | Platform sales report integration | ✅ Professional |
| **Multi-language Support** | Chinese and English interface localization | ✅ Complete |

## 📦 Quick Start

### Environment Requirements
- **Godot Engine**: 4.0 ~ 4.7
- **Android SDK**: API Level 21+
- **Google Play Console**: Valid developer account

### Installation Steps

1. **Download Plugin**
   ```bash
   # Download latest version from GitHub Releases
   # Or clone repository directly
   git clone https://github.com/your-repo/google-iap-ultimate.git
   ```

2. **Install to Project**
   ```
   Copy addons/google_iap folder to your Godot project's addons directory
   ```

3. **Enable Plugin**
   ```
   Project → Project Settings → Plugins → Enable "Google IAP Ultimate"
   ```

4. **Configure Android**
   ```
   Ensure Android export template is properly configured
   Set up app and products in Google Play Console
   ```

### Basic Usage

```gdscript
# Simplest IAP call example
extends Node

func _ready():
    # Initialize IAP service
    if GoogleIAP.init():
        print("IAP service initialized successfully")
    
    # Query product information
    GoogleIAP.query_products(["product_id_1", "product_id_2"])

# Purchase product
func _on_purchase_button_pressed():
    GoogleIAP.purchase("product_id_1")

# Handle purchase result
func _on_iap_purchase_success(product_id: String, receipt: String):
    print("Purchase successful:", product_id)
    # Item granting logic...
```

## 🏗️ Architecture Design

### Modular Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                          │
├─────────────────────────────────────────────────────────────┤
│  • Visual Configuration Panel                              │
│  • Example Projects and Game Integration                   │
├─────────────────────────────────────────────────────────────┤
│                   Business Logic Layer                       │
├─────────────────────────────────────────────────────────────┤
│  • SKU Management Module     • Billing Service Module      │
│  • Server Config Module      • Verification Test Module    │
│  • Data Analytics Module     • Log System Module           │
├─────────────────────────────────────────────────────────────┤
│                   Data Access Layer                         │
├─────────────────────────────────────────────────────────────┤
│  • JSON Configuration Files  • Localization Files          │
│  • Settings Files           • User Configuration          │
├─────────────────────────────────────────────────────────────┤
│                   Platform Adaptation Layer                 │
├─────────────────────────────────────────────────────────────┤
│  • Android Native Plugin    • Godot Engine Integration    │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

| Component | File | Description |
|-----------|------|-------------|
| **Main Singleton** | `GoogleIAP.gd` | IAP core functionality implementation |
| **Configuration Panel** | `GoogleIAPConfigPanel.gd` | Visual configuration interface |
| **Editor Plugin** | `GoogleIAPEditorPlugin.gd` | Godot editor integration |
| **Android Plugin** | `GoogleIAP.java` | Native platform adaptation |
| **Custom Control** | `ResizableTree.gd` | Resizable column tree control |

## 📚 Detailed Documentation

### Usage Guides
- [📖 Complete Usage Manual](docs/USAGE_GUIDE.md) - From beginner to expert
- [🔧 Configuration Guide](docs/CONFIGURATION.md) - Detailed configuration instructions
- [🚀 Quick Start](docs/QUICK_START.md) - 5-minute getting started tutorial
- [🎮 Game Integration](docs/GAME_INTEGRATION.md) - Real project integration cases

### Technical Documentation
- [🏗️ Architecture Design](ARCHITECTURE.md) - System architecture details
- [🔌 API Reference](docs/API_REFERENCE.md) - Complete API documentation
- [🔒 Security Guide](docs/SECURITY.md) - Security best practices
- [📊 Performance Optimization](docs/PERFORMANCE.md) - Performance tuning guide

### Development Documentation
- [👥 Contribution Guide](CONTRIBUTING.md) - Development participation guide
- [🐛 Troubleshooting](docs/TROUBLESHOOTING.md) - Common issue resolution
- [🧪 Testing Guide](docs/TESTING.md) - Testing strategies and methods
- [📦 Release Process](docs/RELEASE.md) - Version release specifications

## 🔧 Advanced Features

### Multi-Vendor Support
- **Google Play**: Complete Billing Library 6+ integration
- **Apple App Store**: App Store Connect API integration
- **Huawei AppGallery**: HMS IAP SDK integration

### Data Analytics Reports
- **Sales Reports**: Real-time sales data and analysis
- **User Behavior**: Purchase behavior analysis
- **Revenue Statistics**: Multi-dimensional revenue reports

### Enterprise Features
- **Multi-environment Configuration**: Development/Test/Production environment separation
- **User Management**: Multi-account permission control
- **Audit Logs**: Complete operation log recording

## 🚀 Performance Metrics

### Response Time
- **Initialization Time**: < 2 seconds
- **Product Query**: < 1 second
- **Purchase Process**: < 3 seconds
- **Verification**: < 1.5 seconds

### Resource Usage
- **Memory Usage**: < 50MB
- **CPU Usage**: < 5%
- **Network Traffic**: Optimized request compression

## 🔒 Security Features

### Data Protection
- **Configuration File Encryption**: Sensitive information encrypted storage
- **Communication Security**: HTTPS + signature verification
- **Local Storage**: Secure local data storage

### Anti-Cheat Mechanisms
- **Server-side Verification**: Complete purchase verification process
- **Duplicate Purchase Detection**: Intelligent duplicate purchase recognition
- **Anomaly Monitoring**: Real-time abnormal behavior detection

## 🌍 Internationalization Support

### Multi-language Interface
- **Chinese**: Complete Chinese localization
- **English**: Professional English interface
- **Extensibility**: Easy to add new languages

### Regional Adaptation
- **Currency Support**: Multi-currency price display
- **Timezone Handling**: Smart timezone conversion
- **Localization Format**: Display formats conforming to local habits

## 🤝 Community and Support

### Getting Help
- **Documentation**: Check detailed usage documentation
- **Examples**: Reference complete example projects
- **Community**: Join developer community discussions

### Issue Reporting
- **GitHub Issues**: Report bugs and feature requests
- **Email Support**: Enterprise-level technical support
- **Community Forum**: Technical discussions and experience sharing

### Contribution Guidelines
We welcome community contributions! Please read: [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Thanks to all developers who contributed to this project, especially:
- Godot Engine community
- Google Play Billing team
- All users who tested and provided feedback

---

**Project Maintainer**: zyuanhua  
**Latest Version**: 6.0.0  
**Update Date**: 2026-03-16  
**Documentation Version**: 2.0

---

<div align="center">

**If this project helps you, please give us a ⭐ Star!**

[![Star History Chart](https://api.star-history.com/svg?repos=your-repo/google-iap-ultimate&type=Date)](https://star-history.com/#your-repo/google-iap-ultimate&Date)

</div>