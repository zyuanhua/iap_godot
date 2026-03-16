# Google IAP Ultimate - 项目结构与API文档

> 商用终极版Google Play Billing Library 6+集成插件  
> 全兼容Godot 4.0~4.7 | 可视化UI配置 | 自动代码生成 | 一键CSV导出 | 智能道具发放 | 防作弊服务端验单

---

## 📁 项目目录结构

```
d:\work\trae\plug-in\iap/
│
├── addons/google_iap/                    # 核心插件目录
│   ├── GoogleIAP.gd                      # ⭐ 运行时API（真正的IAP功能）
│   ├── GoogleIAPConfigPanel.gd           # 编辑器配置面板
│   ├── GoogleIAPConfigPanel.tscn         # UI场景文件
│   ├── GoogleIAPEditorPlugin.gd          # 编辑器插件入口
│   ├── GoogleIAPLicense.gd               # 许可证管理
│   ├── plugin.cfg                        # 插件配置
│   ├── iap_config.json                   # 配置保存文件（自动生成）
│   └── icon.svg                          # 插件图标
│
├── android/                              # Android原生代码
│   └── build/src/com/godot/plugin/googleiap/
│       └── GoogleIAP.java                # Android Java实现
│
├── examples/                             # 示例代码
│   ├── IAPExample.gd                     # 基础示例
│   ├── IAPGameExample.gd                 # 游戏示例
│   ├── IAP_Commercial_Example.gd         # 商用示例
│   ├── IAP_ServerVerification_Example.gd # 服务端验单示例
│   └── SERVER_VERIFICATION_GUIDE.md      # 验单指南
│
└── example_project/                      # 示例项目
    ├── autoload/Global.gd                # 全局单例
    └── scripts/                          # 游戏脚本
```

---

## 🔧 核心API文档

### 1. GoogleIAP.gd - 运行时API

#### 初始化方法

```gdscript
# 初始化Billing服务
func initialize() -> void

# 检查Billing服务是否已连接
func is_billing_ready() -> bool
```

#### 商品查询API

```gdscript
# 查询商品信息
# product_ids: 商品ID数组，如 ["com.yourgame.coins100", "com.yourgame.gems50"]
func query_products(product_ids: Array) -> void

# 获取缓存的商品列表
func get_cached_products() -> Array
```

**相关信号：**
```gdscript
# 商品加载成功
signal products_loaded(products: Array)
# 参数格式：
# [
#   {
#     "product_id": "com.yourgame.coins100",
#     "title": "100金币",
#     "description": "购买100金币",
#     "price": "¥6.00",
#     "price_amount_micros": 6000000,
#     "price_currency_code": "CNY"
#   }
# ]

# 商品加载失败
signal products_load_failed(error_code: int, error_message: String)
```

#### 购买API

```gdscript
# 发起购买
# product_id: 商品ID
func purchase_product(product_id: String) -> void

# 恢复购买（用于非消耗型商品和订阅）
func restore_purchases() -> void

# 消耗商品（用于消耗型商品，如金币）
# product_id: 商品ID
# purchase_token: 购买凭证
func consume_product(product_id: String, purchase_token: String) -> void
```

**相关信号：**
```gdscript
# 购买成功
signal purchase_success(product_id: String, purchase_token: String, order_id: String)

# 购买失败
signal purchase_failed(error_code: int, error_message: String)

# 购买待处理（需要用户在Play Store中完成）
signal purchase_pending(product_id: String)

# 购买被用户取消
signal purchase_cancelled()

# 恢复购买成功
signal purchases_restored(purchases: Array)

# 恢复购买失败
signal purchases_restore_failed(error_code: int, error_message: String)

# 消耗成功
signal consume_success(product_id: String, purchase_token: String)

# 消耗失败
signal consume_failed(error_code: int, error_message: String)
```

#### 服务端验单API

```gdscript
# 服务端验证购买凭证
# product_id: 商品ID
# purchase_token: 购买凭证
# order_id: 订单ID
func verify_purchase_on_server(product_id: String, purchase_token: String, order_id: String) -> void

# 重试待补验单
func retry_pending_verifications() -> void
```

**相关信号：**
```gdscript
# 服务端验单成功
signal server_verify_success(product_id: String, purchase_token: String, order_id: String, response: Dictionary)

# 服务端验单失败
signal server_verify_failed(product_id: String, error_code: int, error_message: String)
```

#### 道具发放API

```gdscript
# 设置商品-道具映射字典
# mapping: 商品ID到道具数据的映射
func set_product_item_mapping(new_mapping: Dictionary) -> void

# 添加单个商品-道具映射
func add_product_item_mapping(product_id: String, item_data: Dictionary) -> void

# 移除商品-道具映射
func remove_product_item_mapping(product_id: String) -> void

# 获取商品对应的道具数据
func get_item_data_for_product(product_id: String) -> Dictionary

# 道具发放核心函数
# product_id: 商品ID
# item_data: 道具数据
# purchase_token: 购买凭证（可选）
func grant_item_to_player(product_id: String, item_data: Dictionary, purchase_token: String = "") -> bool
```

**相关信号：**
```gdscript
# 道具发放成功
signal item_granted(product_id: String, item_data: Dictionary)

# 道具发放失败
signal item_grant_failed(product_id: String, error_message: String)
```

#### 配置变量

```gdscript
# 是否自动发放道具（默认为true）
var auto_grant_items: bool = true

# 是否需要服务端验单后才发放道具（默认为false）
var require_server_verification: bool = false

# 服务端验证URL（开发者设置自己的服务端地址）
var server_verification_url: String = ""

# 服务端请求超时时间（秒）
var server_request_timeout: float = 10.0

# 日志级别：DEBUG=0, INFO=1, WARNING=2, ERROR=3
var log_level: int = LogLevel.INFO

# 是否启用日志输出
var enable_logging: bool = true

# 商品查询失败最大重试次数
var max_query_retry_count: int = 3

# 商品查询重试间隔（秒）
var query_retry_interval: float = 2.0

# 验单失败时是否降级处理（先发放道具，联网后补验单）
var fallback_on_verify_failed: bool = true
```

#### 商品-道具映射配置示例

```gdscript
var product_item_mapping: Dictionary = {
    "com.yourgame.coins.100": {
        "item_type": "coins",           # 道具类型：金币
        "item_amount": 100,             # 金币数量
        "item_name": "100金币"          # 道具名称
    },
    "com.yourgame.coins.500": {
        "item_type": "coins",
        "item_amount": 500,
        "item_name": "500金币"
    },
    "com.yourgame.vip_month": {
        "item_type": "vip_days",        # 道具类型：VIP天数
        "item_amount": 30,              # VIP天数
        "item_name": "30天VIP"
    },
    "com.yourgame.vip_year": {
        "item_type": "vip_days",
        "item_amount": 365,
        "item_name": "1年VIP"
    },
    "com.yourgame.no_ads": {
        "item_type": "no_ads",          # 道具类型：去除广告
        "item_amount": 1,
        "item_name": "永久去除广告"
    },
    "com.yourgame.weapon_sword": {
        "item_type": "item",            # 道具类型：普通道具
        "item_amount": 1,
        "item_name": "传说之剑",
        "item_id": "weapon_sword_001"   # 道具ID
    }
}
```

---

### 2. GoogleIAPConfigPanel.gd - 编辑器配置面板

#### 公共API

```gdscript
# 获取SKU列表
# 返回格式：[{"sku_id": "...", "sku_name": "...", "sku_price": "...", "sku_amount": "..."}]
func get_sku_list() -> Array

# 获取商品-道具映射
# 返回格式：{"com.yourgame.item": {"item_type": "...", "item_amount": ..., "item_name": "..."}}
func get_product_item_mapping() -> Dictionary
```

#### 配置文件格式

**文件路径：** `res://addons/google_iap/iap_config.json`

```json
{
  "sku_list": [
    {
      "sku_id": "com.yourgame.coins100",
      "sku_name": "金币礼包",
      "sku_price": "0.99",
      "sku_amount": "100"
    },
    {
      "sku_id": "com.yourgame.gems50",
      "sku_name": "宝石礼包",
      "sku_price": "1.99",
      "sku_amount": "50"
    }
  ],
  "sandbox_mode": true,
  "last_updated": "2025-01-15 10:30:00"
}
```

---

## 📋 使用指南

### 步骤1：编辑器配置

1. 打开Godot编辑器
2. 启用「Google IAP Ultimate」插件
3. 在配置面板中添加SKU商品
4. 配置自动保存到 `iap_config.json`

### 步骤2：游戏集成

```gdscript
extends Node

# 引用GoogleIAP单例（需要在项目设置中添加为Autoload）
onready var iap = GoogleIAP

func _ready():
    # 1. 设置商品-道具映射
    var mapping = {
        "com.yourgame.coins100": {
            "item_type": "coins",
            "item_amount": 100,
            "item_name": "100金币"
        },
        "com.yourgame.vip_month": {
            "item_type": "vip_days",
            "item_amount": 30,
            "item_name": "30天VIP"
        }
    }
    iap.set_product_item_mapping(mapping)
    
    # 2. 初始化IAP
    iap.initialize()
    
    # 3. 连接信号
    iap.billing_connected.connect(_on_billing_connected)
    iap.products_loaded.connect(_on_products_loaded)
    iap.purchase_success.connect(_on_purchase_success)
    iap.purchase_failed.connect(_on_purchase_failed)
    iap.item_granted.connect(_on_item_granted)
    iap.server_verify_success.connect(_on_server_verify_success)

func _on_billing_connected():
    print("计费服务已连接")
    # 查询商品信息
    iap.query_products(["com.yourgame.coins100", "com.yourgame.vip_month"])

func _on_products_loaded(products: Array):
    print("商品加载成功，数量：%d" % products.size())
    for product in products:
        print("商品：%s - %s" % [product.title, product.price])

func _on_purchase_success(product_id: String, purchase_token: String, order_id: String):
    print("购买成功：%s, 订单ID：%s" % [product_id, order_id])

func _on_purchase_failed(error_code: int, error_message: String):
    print("购买失败：%d - %s" % [error_code, error_message])

func _on_item_granted(product_id: String, item_data: Dictionary):
    print("道具发放成功：%s - %s" % [product_id, item_data.item_name])
    # 更新游戏UI
    update_player_items()

func _on_server_verify_success(product_id: String, purchase_token: String, order_id: String, response: Dictionary):
    print("服务端验单成功：%s" % product_id)

# 发起购买
func buy_coins():
    iap.purchase_product("com.yourgame.coins100")

# 恢复购买
func restore_purchases():
    iap.restore_purchases()
```

### 步骤3：服务端验单配置

```gdscript
# 在游戏启动时配置服务端验单
func configure_server_verification():
    iap.require_server_verification = true
    iap.server_verification_url = "https://your-server.com/api/verify_purchase"
    iap.server_request_timeout = 10.0
    iap.fallback_on_verify_failed = true  # 验单失败时降级处理
```

### 步骤4：自定义道具发放逻辑

```gdscript
# 在GoogleIAP.gd中修改以下函数

func _add_coins_to_player(amount: int) -> void:
    # 调用你的游戏逻辑
    GameManager.add_coins(amount)
    print("玩家获得%d金币" % amount)

func _add_vip_days_to_player(days: int) -> void:
    # 调用你的游戏逻辑
    GameManager.add_vip_days(days)
    print("玩家获得%d天VIP" % days)

func _set_no_ads_to_player(no_ads: bool) -> void:
    # 调用你的游戏逻辑
    GameManager.set_no_ads(no_ads)
    print("玩家无广告状态：%s" % no_ads)

func _add_item_to_player(item_id: String, amount: int) -> void:
    # 调用你的游戏逻辑
    InventoryManager.add_item(item_id, amount)
    print("玩家获得道具：%s x%d" % [item_id, amount])
```

---

## 🔐 服务端验单实现

### 服务端API规范

**请求格式：**
```json
POST /api/verify_purchase
Content-Type: application/json

{
  "sku": "com.yourgame.coins100",
  "token": "purchase_token_from_google",
  "order_id": "GPA.1234-5678-9012-34567",
  "timestamp": 1704067200000
}
```

**响应格式（成功）：**
```json
{
  "verified": true,
  "product_id": "com.yourgame.coins100",
  "order_id": "GPA.1234-5678-9012-34567",
  "purchase_state": 1,
  "message": "验证成功"
}
```

**响应格式（失败）：**
```json
{
  "verified": false,
  "error_code": 400,
  "message": "无效的购买凭证"
}
```

---

## 🎯 最佳实践

### 1. 安全性

- ✅ 使用服务端验单防止作弊
- ✅ 验证购买凭证的真实性
- ✅ 防止重复发放道具
- ✅ 记录所有交易日志

### 2. 用户体验

- ✅ 显示加载动画
- ✅ 处理网络错误
- ✅ 提供重试机制
- ✅ 清晰的错误提示

### 3. 测试

- ✅ 使用沙盒账号测试
- ✅ 测试所有购买流程
- ✅ 测试恢复购买
- ✅ 测试网络异常情况

---

## 📊 错误码参考

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| 0 | 成功 | - |
| 1 | 服务不可用 | 提示用户稍后重试 |
| 2 | 用户取消 | 无需处理 |
| 3 | 商品不可用 | 检查商品ID是否正确 |
| 4 | 商品已拥有 | 提示用户已购买 |
| 5 | 开发者错误 | 检查配置是否正确 |
| 6 | 网络错误 | 提示用户检查网络 |
| 7 | 验单失败 | 联系客服处理 |

---

## 📝 更新日志

### v6.0.0 (2025-01-15)
- ✅ 新增编辑器配置面板
- ✅ 新增配置持久化功能
- ✅ 新增沙盒/生产环境切换
- ✅ 新增模拟购买流程
- ✅ 新增日志导出功能
- ✅ 修复UI与API断连问题
- ✅ 优化配置保存机制

---

## 📞 技术支持

- **文档版本：** v1.0
- **最后更新：** 2025-01-15
- **兼容版本：** Godot 4.0~4.7
- **插件版本：** Google IAP Ultimate v6.0.0

---

## 📄 许可证

本插件遵循 MIT 许可证，可免费用于商业项目。
