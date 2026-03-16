# Google IAP 插件 - 源码保护与对外交付方案

## 目录
1. [概述](#概述)
2. [GDScript混淆方案](#gdscript混淆方案)
3. [GDExtension二进制封装方案](#gdextension二进制封装方案)
4. [授权绑定方案](#授权绑定方案)
5. [对外交付包结构](#对外交付包结构)
6. [使用协议](#使用协议)
7. [迭代升级指南](#迭代升级指南)

---

## 概述

本方案提供了三种级别的源码保护：

1. **轻量级保护** - GDScript代码混淆
2. **中量级保护** - GDExtension二进制封装
3. **重量级保护** - 授权绑定机制

您可以根据需要选择合适的保护级别，或组合使用多种方式。

---

## GDScript混淆方案

### 方案简介

GDScript混淆通过变量名、函数名重命名和代码结构变换来保护源码，使代码难以阅读和理解，但不影响功能执行。

### 工具推荐

#### 1. GDScript Obfuscator (Python脚本)

**优点**：
- 纯Python实现，无需额外依赖
- 可自定义混淆规则
- 保留函数接口（公共API不混淆）

#### 2. Godot Obfuscator (第三方工具)

GitHub搜索关键词：`godot gdscript obfuscator`

### 手动混淆步骤（简单版）

如果不想使用第三方工具，可以手动进行基础混淆：

#### 步骤1：备份源码
```bash
# 复制原始文件作为备份
copy addons\google_iap\GoogleIAP.gd addons\google_iap\GoogleIAP.gd.source
```

#### 步骤2：重命名私有变量
将私有变量名改为无意义的名称：
```gdscript
# 原始代码
private var _cached_products: Array = []
private var _is_billing_connected: bool = false

# 混淆后
private var _a: Array = []
private var _b: bool = false
```

#### 步骤3：重命名私有函数
```gdscript
# 原始代码
private func _initialize_godot_version() -> void:
    pass

# 混淆后
private func _x1() -> void:
    pass
```

#### 步骤4：删除或混淆注释
```gdscript
# 删除所有中文注释
# 删除详细的英文注释
# 只保留最必要的注释
```

### 使用Python脚本自动化混淆

创建一个简单的Python混淆脚本：

```python
# obfuscator.py
import re
import sys

def obfuscate_gdscript(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 步骤1: 删除注释
    # 删除单行注释
    content = re.sub(r'#.*$', '', content, flags=re.MULTILINE)
    # 删除多行注释（如果有）
    content = re.sub(r'""".*?"""', '', content, flags=re.DOTALL)
    
    # 步骤2: 删除空行
    content = re.sub(r'\n\s*\n', '\n', content)
    
    # 步骤3: 重命名私有变量（简单示例）
    # 实际使用时需要更复杂的逻辑
    var_map = {
        '_cached_products': '_v1',
        '_cached_purchases': '_v2',
        '_is_billing_connected': '_v3',
        '_is_initialized': '_v4',
    }
    
    for old, new in var_map.items():
        content = content.replace(old, new)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"混淆完成: {output_file}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("用法: python obfuscator.py <输入文件> <输出文件>")
        sys.exit(1)
    
    obfuscate_gdscript(sys.argv[1], sys.argv[2])
```

使用方法：
```bash
python obfuscator.py addons\google_iap\GoogleIAP.gd addons\google_iap\GoogleIAP.gd.obfuscated
```

---

## GDExtension二进制封装方案

### 方案简介

将核心逻辑用GDExtension封装为二进制文件（.so/.dll/.dylib），只暴露必要的API接口。这是最强的保护方式。

### 无需C++的简化方案

#### 方案A：使用GDNative + 预编译模板

推荐使用现有的GDExtension模板项目：

1. **下载GDExtension模板**
   - GitHub搜索：`godot gdextension template`
   - 推荐：`godot-cpp-template`

2. **创建GDExtension包装层**
   - 将GDScript逻辑转换为C++（或使用GDExtension的GDScript绑定）

#### 方案B：使用Godot的PCK打包（推荐新手）

虽然不是真正的二进制封装，但PCK打包可以将脚本打包成二进制格式：

```gdscript
# 创建打包脚本
extends EditorScript

func _run():
    var pck_path = "res://google_iap_core.pck"
    var files = [
        "res://addons/google_iap/GoogleIAP.gd"
    ]
    
    var packer = PCKPacker.new()
    packer.pck_start(pck_path)
    
    for file in files:
        packer.add_file(file, file)
    
    packer.flush()
    print("PCK文件已生成: " + pck_path)
```

#### 方案C：使用第三方工具

- **godot-encrypt**: 加密GDScript文件
- **GodotObfuscator**: 综合混淆工具

### 完整GDExtension实现步骤（简化版）

#### 步骤1：准备GDExtension环境

```bash
# 克隆godot-cpp
git clone https://github.com/godotengine/godot-cpp.git
cd godot-cpp
git checkout 4.2
scons platform=windows
```

#### 步骤2：创建简单的C++包装

```cpp
// src/register_types.cpp
#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "google_iap.h"

using namespace godot;

void initialize_google_iap_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    
    ClassDB::register_class<GoogleIAP>();
}

void uninitialize_google_iap_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

extern "C" {
    GDExtensionBool GDE_EXPORT google_iap_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
        godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
        
        init_obj.register_initializer(initialize_google_iap_module);
        init_obj.register_terminator(uninitialize_google_iap_module);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
        
        return init_obj.init();
    }
}
```

---

## 授权绑定方案

### 方案简介

基于设备唯一ID的授权绑定，限制插件只能在授权的设备上使用。

### 实现代码

授权管理脚本已创建在 `addons/google_iap/GoogleIAPLicense.gd`

### 集成到GoogleIAP

在 `GoogleIAP.gd` 中集成授权验证：

```gdscript
# 在文件顶部添加
var license_manager: GoogleIAPLicense = null

func _ready() -> void:
    # 初始化授权管理器
    license_manager = GoogleIAPLicense.new()
    add_child(license_manager)
    
    # 连接授权信号
    license_manager.license_verified.connect(_on_license_verified)
    license_manager.license_failed.connect(_on_license_failed)
    
    # 加载授权配置
    license_manager.load_authorized_devices()
    
    # 验证授权（如果启用）
    license_manager.verify_license()
    
    # 原有初始化代码...
    _initialize_godot_version()
    # ...

func _on_license_verified() -> void:
    _log(LogLevel.INFO, "授权验证成功")

func _on_license_failed(reason: String) -> void:
    _log(LogLevel.ERROR, "授权验证失败: ", reason)
    # 可以选择禁用插件功能或显示提示

# 公共方法：快速授权当前设备
func authorize_current_device() -> void:
    if license_manager:
        license_manager.quick_authorize_current_device()

# 公共方法：显示设备ID
func show_device_id() -> void:
    if license_manager:
        license_manager.show_device_id_dialog()
```

### 使用流程

1. **开发者首次使用**：
   ```gdscript
   # 在编辑器或游戏中运行
   GoogleIAP.show_device_id()  # 查看并复制设备ID
   ```

2. **添加授权**：
   ```gdscript
   GoogleIAP.authorize_current_device()  # 快速授权当前设备
   ```

3. **分发时配置**：
   - 在插件配置中设置授权设备列表
   - 或在代码中硬编码授权ID

---

## 对外交付包结构

### 目录结构说明

```
google_iap_plugin_v6.0.0/
├── README_DELIVERY.md          # 对外交付说明
├── LICENSE_FOR_USERS.md        # 用户使用协议
├── CHANGELOG.md                 # 更新日志
├── addons/
│   └── google_iap/
│       ├── GoogleIAP.gd        # [加密/混淆] 核心逻辑
│       ├── GoogleIAP.gd.source # [仅自留] 原始源码备份
│       ├── GoogleIAPLicense.gd # [公开] 授权管理
│       ├── GoogleIAPConfigPanel.gd    # [公开] UI配置面板
│       ├── GoogleIAPConfigPanel.tscn   # [公开] UI场景
│       ├── GoogleIAPEditorPlugin.gd    # [公开] 编辑器插件
│       ├── plugin.cfg          # [公开] 插件配置
│       └── icon.svg            # [公开] 插件图标
├── android/
│   └── build/
│       ├── AndroidManifest.xml  # [公开] Android清单
│       ├── build.gradle         # [公开] Gradle配置
│       └── src/
│           └── com/godot/plugin/googleiap/
│               └── GoogleIAP.java  # [加密/混淆] Java源码
├── examples/
│   ├── IAP_Minimal_Example.gd    # [公开] 最简示例
│   ├── IAP_Commercial_Example.gd # [公开] 商用示例
│   └── IAP_ServerVerification_Example.gd  # [公开] 验单示例
├── docs/
│   ├── QUICK_START.md          # [公开] 快速开始
│   ├── FAQ.md                  # [公开] 常见问题
│   └── API_REFERENCE.md        # [公开] API参考
└── tools/
    └── obfuscator.py           # [仅自留] 混淆工具
```

### 文件分类说明

#### 🔒 仅自留（不要对外分发）
- `addons/google_iap/GoogleIAP.gd.source` - 原始源码备份
- `tools/obfuscator.py` - 混淆工具
- `SOURCE_PROTECTION_GUIDE.md` - 本文档
- 所有.git文件夹和开发相关文件

#### 🔐 需要加密/混淆后分发
- `addons/google_iap/GoogleIAP.gd` - 核心逻辑（混淆后）
- `android/build/src/com/godot/plugin/googleiap/GoogleIAP.java` - Java源码（混淆后）

#### 📢 可以直接公开
- 所有UI配置文件
- 所有示例代码
- 所有文档
- AndroidManifest.xml, build.gradle等配置文件

### 打包脚本（Windows批处理）

创建 `build_delivery_package.bat`：

```batch
@echo off
echo ========================================
echo Google IAP 插件 - 交付包构建脚本
echo ========================================

set VERSION=6.0.0
set SOURCE_DIR=.
set DELIVERY_DIR=google_iap_plugin_v%VERSION%

echo.
echo [1/6] 创建交付目录...
if exist %DELIVERY_DIR% rmdir /s /q %DELIVERY_DIR%
mkdir %DELIVERY_DIR%

echo.
echo [2/6] 复制公开文件...
xcopy /e /i /y "%SOURCE_DIR%\addons" "%DELIVERY_DIR%\addons\"
xcopy /e /i /y "%SOURCE_DIR%\examples" "%DELIVERY_DIR%\examples\"
xcopy /e /i /y "%SOURCE_DIR%\android" "%DELIVERY_DIR%\android\"

echo.
echo [3/6] 创建文档目录...
mkdir "%DELIVERY_DIR%\docs"
copy "%SOURCE_DIR%\README.md" "%DELIVERY_DIR%\docs\QUICK_START.md"
copy "%SOURCE_DIR%\FAQ.md" "%DELIVERY_DIR%\docs\FAQ.md"

echo.
echo [4/6] 备份原始源码...
copy "%SOURCE_DIR%\addons\google_iap\GoogleIAP.gd" "%SOURCE_DIR%\addons\google_iap\GoogleIAP.gd.source"

echo.
echo [5/6] 请手动执行混淆步骤...
echo.
echo 提示：
echo 1. 运行混淆工具处理 GoogleIAP.gd
echo 2. 用混淆后的文件替换原文件
echo 3. 确认功能正常后继续
echo.
pause

echo.
echo [6/6] 清理敏感文件...
del "%DELIVERY_DIR%\addons\google_iap\GoogleIAP.gd.source"
del "%DELIVERY_DIR%\SOURCE_PROTECTION_GUIDE.md"

echo.
echo ========================================
echo 交付包构建完成！
echo 位置: %DELIVERY_DIR%
echo ========================================
echo.
echo 请检查：
echo - GoogleIAP.gd 是否已混淆
echo - 敏感文件是否已删除
echo - 所有必要文件是否完整
echo.
pause
```

---

## 使用协议

### LICENSE_FOR_USERS.md

```
# Google IAP Ultimate - 使用协议

版权所有 © 2024 [您的名称/公司名]

## 授权范围

### ✅ 允许的使用

1. **商用授权**
   - 可以在商业项目中使用本插件
   - 可以在免费或付费游戏中集成
   - 无需支付额外的版税或分成

2. **修改权限**
   - 可以修改配置文件
   - 可以修改UI界面
   - 可以调整示例代码

3. **分发权限**
   - 可以将集成了本插件的游戏发布到任何平台
   - 可以将编译后的游戏包含本插件二进制文件分发

### ❌ 禁止的行为

1. **禁止二次售卖**
   - 不得将本插件（或修改后的版本）单独售卖
   - 不得将本插件作为商品在任何平台上架销售
   - 不得将本插件包含在其他插件/工具包中售卖

2. **禁止反向工程**
   - 不得对混淆/加密的代码进行反向工程
   - 不得试图破解或绕过授权机制
   - 不得提取核心算法用于其他项目

3. **禁止移除版权声明**
   - 不得移除或修改本协议文件
   - 不得移除插件中的版权声明
   - 不得声称本插件为自己原创

## 免责声明

本插件按"现状"提供，不提供任何明示或暗示的保证。
作者不对因使用本插件造成的任何损失或损害负责。

## 保留权利

作者保留随时修改本协议的权利。
作者保留对本插件的所有著作权。

## 联系方式

如有问题，请联系：[您的联系方式]
```

---

## 迭代升级指南

### 升级流程

当需要更新插件时：

1. **在源码版本上开发**
   - 使用 `GoogleIAP.gd.source` 进行开发
   - 测试新功能
   - 确保向后兼容

2. **更新混淆配置**
   - 保留公共API不混淆
   - 更新混淆脚本中的变量映射

3. **重新混淆**
   ```bash
   python tools/obfuscator.py addons/google_iap/GoogleIAP.gd.source addons/google_iap/GoogleIAP.gd
   ```

4. **测试混淆版本**
   - 确保所有功能正常
   - 检查API兼容性

5. **构建新交付包**
   - 运行打包脚本
   - 更新版本号
   - 更新CHANGELOG

### 版本管理建议

```
google_iap_plugin/
├── develop/              # 开发分支（源码）
│   ├── addons/
│   │   └── google_iap/
│   │       └── GoogleIAP.gd  # 清晰源码
│   └── ...
└── release/              # 发布分支（混淆）
    ├── addons/
    │   └── google_iap/
    │       └── GoogleIAP.gd  # 混淆后代码
    └── ...
```

---

## 总结

本方案提供了完整的源码保护和交付流程：

1. **轻量级保护**：GDScript混淆，简单有效
2. **中量级保护**：GDExtension二进制封装，保护更强
3. **重量级保护**：授权绑定，限制使用范围

选择适合您需求的保护级别，或组合使用多种方式！

---

**祝您使用愉快！** 🛡️

