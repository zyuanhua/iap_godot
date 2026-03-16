# Google IAP Ultimate - 商用终极版发布包

## 📦 发布包概览

**版本**: 6.0.0  
**定价**: $49.99  
**兼容**: Godot 4.0 ~ 4.7  
**状态**: ✅ 商用就绪

---

## 🎯 核心卖点

### 1. 零门槛商用
- 开箱即用，5分钟集成到你的游戏
- 无需深入理解 IAP 复杂流程
- 完整文档和示例代码

### 2. 自动发道具
- 支付成功自动发放，无需手动编写代码
- 灵活的商品-道具映射配置
- 完整的信号通知系统

### 3. 防作弊验单
- HTTP 请求封装，完整回调处理
- 验单成功后才发放道具
- 可选开关，灵活控制

### 4. 全版本兼容
- 完美支持 Godot 4.0~4.7 所有版本
- 兼容性兜底机制
- 无版本专属 API 问题

---

## 📋 发布包完整文件清单

```
google_iap_ultimate_v6.0.0/
│
├── 📁 addons/
│   └── 📁 google_iap/
│       ├── 📄 plugin.cfg                    # 插件配置文件
│       ├── 📄 GoogleIAP.gd                  # GDScript 单例类（核心）
│       ├── 📄 GoogleIAPEditorPlugin.gd      # 编辑器插件（UI面板）
│       ├── 📄 GoogleIAPConfigPanel.tscn    # 配置面板场景
│       ├── 📄 GoogleIAPConfigPanel.gd      # 配置面板逻辑
│       └── 🖼️ icon.svg                      # 插件图标
│
├── 📁 android/
│   └── 📁 build/
│       ├── 📄 build.gradle                  # Android 构建配置
│       ├── 📄 AndroidManifest.xml           # Android 清单文件
│       └── 📁 src/com/godot/plugin/googleiap/
│           └── 📄 GoogleIAP.java            # Android 插件实现
│
├── 📁 examples/
│   ├── 📄 IAPExample.gd                     # 基础调用示例
│   ├── 📄 IAPGameExample.tscn              # 游戏示例场景
│   ├── 📄 IAPGameExample.gd                # 游戏示例逻辑
│   ├── 📄 IAP_Minimal_Example.gd           # 最小化示例（3步使用）
│   ├── 📄 IAP_ItemGrant_Example.gd         # 道具发放系统示例
│   ├── 📄 IAP_ServerVerification_Example.gd # 服务端验单完整示例
│   └── 📄 SERVER_VERIFICATION_GUIDE.md     # 服务端验单详细指南
│
├── 📄 README.md                              # 完整中文文档
├── 📄 ASSET_LIBRARY.md                       # 英文上架文案
├── 📄 COMPATIBILITY_GUIDE.md                # 兼容性指南
├── 📄 RELEASE_PACKAGE.md                     # 本文件 - 发布包说明
├── 📄 CHANGELOG.md                           # 版本更新日志
├── 📄 CONTRIBUTING.md                        # 贡献指南
└── 📄 LICENSE                                # 商用许可证
```

---

## 🚀 快速开始（5分钟）

### 第1步：安装插件（1分钟）

1. 将 `addons/google_iap` 文件夹复制到你的 Godot 项目的 `addons` 目录
2. 在 Godot 编辑器中：`项目` -> `项目设置` -> `插件`
3. 启用 "Google IAP Ultimate" 插件

### 第2步：配置商品（2分钟）

1. 点击编辑器菜单栏：`项目` -> `工具` -> `Google IAP` -> `配置面板`
2. 输入商品信息：
   - 商品ID (SKU)：如 `com.yourgame.coins.100`
   - 商品名称：如 `100金币`
   - 价格：参考价
   - 商品类型：一次性购买或订阅
3. 点击"添加商品"
4. 点击"保存配置"或"复制代码"

### 第3步：游戏内集成（2分钟）

创建一个简单的脚本：

```gdscript
extends Node

func _ready() -> void:
    # 1. 连接道具发放信号
    GoogleIAP.item_granted.connect(_on_item_granted)
    
    # 2. 初始化
    GoogleIAP.initialize()

# 3. 购买商品，道具自动发放！
func buy_100_coins() -> void:
    GoogleIAP.purchase_product("com.yourgame.coins.100")

# 道具发放成功回调
func _on_item_granted(product_id: String, item_data: Dictionary) -> void:
    var item_name = item_data.get("item_name", "道具")
    print("恭喜获得: ", item_name)
```

✅ **完成！** 你的游戏现在已经集成了完整的IAP功能！

---

## 📚 详细文档索引

| 文档 | 说明 |
|------|------|
| `README.md` | 完整中文使用文档 |
| `ASSET_LIBRARY.md` | 英文上架文案 |
| `COMPATIBILITY_GUIDE.md` | 兼容性指南 |
| `SERVER_VERIFICATION_GUIDE.md` | 服务端验单详细指南 |
| `examples/IAP_Minimal_Example.gd` | 3步最小化示例 |
| `examples/IAP_ItemGrant_Example.gd` | 道具发放系统完整示例 |
| `examples/IAP_ServerVerification_Example.gd` | 服务端验单完整示例 |

---

## 🎮 功能特性详解

### 1. 可视化UI配置面板

- ✅ 商品ID、名称、价格、类型输入
- ✅ 实时代码预览
- ✅ 一键保存/复制
- ✅ 配置持久化（JSON格式）
- ✅ 批量删除商品

### 2. 智能道具发放系统

- ✅ 3步即可使用
- ✅ 支付成功自动发放
- ✅ 灵活的商品-道具映射
- ✅ 完整的信号通知
- ✅ 支持多种道具类型（金币、VIP、去广告、普通道具）

### 3. 防作弊服务端验单

- ✅ 可选开关，灵活控制
- ✅ JSON格式参数传递（sku + token）
- ✅ HTTP POST请求封装
- ✅ 完整的成功/失败回调
- ✅ 超时处理和错误恢复
- ✅ 验单成功后才发放道具

### 4. 一键CSV导出

- ✅ 直接导出Google Play官方格式
- ✅ 格式：`Product ID,Name,Price`
- ✅ 保存到用户目录
- ✅ 支持UTF-8编码

### 5. 完整信号系统

| 信号 | 说明 |
|------|------|
| `billing_connected` | Billing服务连接成功 |
| `products_loaded` | 商品加载成功 |
| `purchase_success` | 购买成功 |
| `purchase_failed` | 购买失败 |
| `item_granted` | 道具发放成功 |
| `item_grant_failed` | 道具发放失败 |
| `server_verify_success` | 验单成功 |
| `server_verify_failed` | 验单失败 |

---

## 🔒 安全特性

### 服务端验单工作流程

```
1. 玩家购买商品
2. Google Play 支付成功
3. 插件收到 purchase_success 信号
4. 检查是否需要服务端验单
5. 如需要，发送 HTTP POST 请求到服务端
6. 服务端验证购买凭证
7. 服务端返回验证结果
8. 验单成功后发放道具
```

### 服务端接口规范

**请求格式**:
```json
{
  "sku": "com.yourgame.coins.100",
  "token": "purchase_token",
  "order_id": "GPA.1234-5678-9012-34567",
  "timestamp": 1699999999999
}
```

**响应格式**:
```json
{
  "verified": true,
  "message": "验证成功"
}
```

> 详细的服务端实现示例（Node.js、Python、PHP）请查看 `examples/SERVER_VERIFICATION_GUIDE.md`

---

## 🛠 Android 构建配置

### 1. 配置 Gradle

在 `android/build/build.gradle` 中添加：
```gradle
dependencies {
    implementation "com.android.billingclient:billing:6.2.1"
}
```

### 2. AndroidManifest.xml

确保包含 Billing 权限：
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### 3. 集成 Java 插件

将 `android/build/src/com/godot/plugin/googleiap/GoogleIAP.java` 复制到你的 Android 项目。

---

## 🧪 测试说明

### 非 Android 平台

插件自动进入模拟模式，可测试：
- ✅ 商品查询（返回模拟数据）
- ✅ 购买流程（模拟成功）
- ✅ 恢复购买
- ✅ 消耗商品
- ✅ 服务端验单（模拟响应）

### Android 平台测试

1. 使用内部测试轨道
2. 添加测试账号
3. 使用 Google Play 内部应用分享
4. 或使用官方测试商品ID

---

## 📈 版本历史

### v6.0.0 (2026-03-10)
- 🎉 商用终极版发布
- ✅ 完整的服务端验单功能
- ✅ 验单后才发放道具（可选开关）
- ✅ 完善的异常处理和日志记录
- ✅ 5分钟上手教程
- ✅ 完整的兼容性保证
- ✅ 英文上架文案

### v5.0.0 (2026-03-10)
- ✅ 新增服务端验单功能
- ✅ HTTP请求封装，JSON参数传递
- ✅ 验单成功/失败回调处理
- ✅ 优化道具发放逻辑

### v4.0.0 (2026-03-10)
- ✅ 新增一键CSV导出功能
- ✅ 道具自动发放系统
- ✅ 可视化UI配置面板升级

---

## 📄 许可证

商用终极版 - 允许商业使用。

---

## 🤝 支持

如有问题，请：
1. 查看完整文档 `README.md`
2. 查看示例代码 `examples/`
3. 查看服务端验单指南 `examples/SERVER_VERIFICATION_GUIDE.md`

---

## ✨ 商用推荐配置

### 生产环境必备

```gdscript
extends Node

func _ready() -> void:
    # 启用服务端验单（防作弊）
    GoogleIAP.require_server_verification = true
    GoogleIAP.server_verification_url = "https://your-server.com/api/verify-purchase"
    GoogleIAP.server_request_timeout = 15.0
    
    # 启用自动发放道具
    GoogleIAP.auto_grant_items = true
    
    # 连接所有信号
    GoogleIAP.purchase_success.connect(_on_purchase_success)
    GoogleIAP.purchase_failed.connect(_on_purchase_failed)
    GoogleIAP.item_granted.connect(_on_item_granted)
    GoogleIAP.item_grant_failed.connect(_on_item_grant_failed)
    GoogleIAP.server_verify_success.connect(_on_server_verify_success)
    GoogleIAP.server_verify_failed.connect(_on_server_verify_failed)
    
    # 初始化
    GoogleIAP.initialize()
```

---

**祝您的游戏大卖！** 🎮💰🎉

---

## 📞 技术支持

- 完整文档：`README.md`
- 示例代码：`examples/`
- 兼容性指南：`COMPATIBILITY_GUIDE.md`
- 服务端验单指南：`examples/SERVER_VERIFICATION_GUIDE.md`
