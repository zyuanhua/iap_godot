# Google IAP 插件 UI 结构面板

## 🎯 整体结构

```
GoogleIAPConfigPanel (ScrollContainer)
└── MainVBox (VBoxContainer) - 主垂直布局
```

---

## 📦 模块 1：基础 IAP 操作区

**节点路径：** `MainVBox/Module1_Basic`

```
Module1_Basic (VBoxContainer)
├── TitleRow1 (HBoxContainer)
│   ├── Title1 (Label) - 模块标题
│   ├── language_selector (OptionButton) - 语言选择器
│   └── module1_info (Label) - 信息图标 ⓘ
├── Row1 (HBoxContainer)
│   ├── Label1 (Label) - "商品:"
│   └── test_sku_option (OptionButton) - 测试 SKU 下拉框
├── Row2 (HBoxContainer)
│   ├── Label2 (Label) - "订单 ID:"
│   └── order_id_edit (LineEdit) - 订单 ID 输入框
└── Row3 (HBoxContainer)
    ├── btn_check_order (Button) - 查询订单按钮
    ├── btn_clear_inputs (Button) - 清空输入按钮
    └── operation_status_label (Label) - 操作状态标签
```

### 功能说明
- 测试 SKU 选择
- 订单 ID 输入与查询
- 操作状态显示
- 语言切换功能

### 本地化键位
- 标题：`module1.title`
- 工具提示：`module1.tooltip`
- 标签：`module1.label.test_sku`, `module1.label.order_id`, `module1.label.operation_status`
- 按钮：`module1.btn.check_order`, `module1.btn.clear_inputs`
- 占位符：`module1.placeholder.order_id`
- 工具提示：`module1.tooltip.test_sku`, `module1.tooltip.order_id`, `module1.tooltip.btn_check_order` 等

---

## 📦 模块 2：计费服务控制区

**节点路径：** `MainVBox/Module2_Billing`

```
Module2_Billing (VBoxContainer)
├── TitleRow2 (HBoxContainer)
│   ├── Title2 (Label) - 模块标题
│   └── module2_info (Label) - 信息图标 ⓘ
├── Row1 (HBoxContainer)
│   ├── Label1 (Label) - "计费环境:"
│   └── env_option (OptionButton) - 环境选择（沙盒/生产）
├── Row2 (HBoxContainer)
│   ├── btn_init_billing (Button) - 初始化服务
│   └── btn_refresh_billing (Button) - 刷新服务
└── Row3 (HBoxContainer)
    ├── btn_close_billing (Button) - 关闭计费服务
    └── service_status_label (Label) - 服务状态标签
```

### 功能说明
- 计费环境切换
- 服务初始化/刷新/关闭控制
- 服务状态监控

### 本地化键位
- 标题：`module2.title`
- 工具提示：`module2.tooltip`
- 标签：`module2.label.env`, `module2.label.service_status`
- 按钮：`module2.btn.init_billing`, `module2.btn.refresh_billing`, `module2.btn.close_billing`
- 环境选项：`module2.env_option.sandbox`, `module2.env_option.production`
- 服务状态：`module2.service_status.uninitialized`, `module2.service_status.initialized`, `module2.service_status.error`

---

## 📦 模块 3：SKU 管理区

**节点路径：** `MainVBox/Module3_SKU`

```
Module3_SKU (VBoxContainer)
├── TitleRow3 (HBoxContainer)
│   ├── Title3 (Label) - 模块标题
│   └── module3_info (Label) - 信息图标 ⓘ
├── FilterRow (HBoxContainer)
│   ├── FilterLabel (Label) - "服务商:"
│   ├── sku_provider_filter (OptionButton) - 服务商筛选
│   ├── show_inactive_checkbox (CheckBox) - 显示已停用 SKU
│   ├── debug_mode_checkbox (CheckBox) - 调试模式
│   └── btn_manual_sync (Button) - 手动同步
├── Row1 (HBoxContainer) - SKU ID 输入
│   ├── Label1 (Label) - "SKU ID:"
│   └── sku_id_edit (LineEdit)
├── Row2 (HBoxContainer) - 商品名称输入
│   ├── Label2 (Label) - "商品名称:"
│   └── sku_name_edit (LineEdit)
├── Row3 (HBoxContainer) - 价格输入
│   ├── Label3 (Label) - "价格:"
│   └── sku_price_edit (LineEdit)
├── Row4 (HBoxContainer) - 服务商选择
│   ├── Label4 (Label) - "服务商:"
│   └── sku_provider_option (OptionButton)
├── Row5 (HBoxContainer) - 添加/编辑/更新按钮
│   ├── btn_add_sku (Button) - 添加 SKU
│   ├── btn_edit_sku (Button) - 编辑 SKU
│   └── btn_update_sku (Button) - 更新 SKU
├── Row6 (HBoxContainer) - 启用/停用按钮
│   ├── btn_deactivate_sku (Button) - 停用选中 SKU
│   └── btn_activate_sku (Button) - 启用选中 SKU
├── Row7 (HBoxContainer) - 导入导出按钮
│   ├── btn_import_sku (Button) - 导入 JSON
│   ├── btn_export_sku (Button) - 导出 JSON
│   ├── btn_import_csv (Button) - 导入 CSV
│   └── btn_export_csv (Button) - 导出 CSV
├── Row8 (HBoxContainer) - 管理按钮
│   ├── btn_add_new_sku (Button) - 新增 SKU
│   ├── btn_delete_sku (Button) - 删除 SKU
│   └── btn_clear_sku_list (Button) - 清空列表框
├── sku_tree (Tree) - SKU 列表（5 列）
│   列 0: ID
│   列 1: 名称
│   列 2: 价格
│   列 3: 服务商
│   列 4: 状态
└── status_timer (Timer) - 状态定时器
```

### 功能说明
- SKU 增删改查管理
- 服务商筛选与过滤
- 导入导出功能（JSON/CSV）
- 启用/停用 SKU
- 调试模式支持
- Tree 列表展示

### 本地化键位
- 标题：`module3.title`
- 工具提示：`module3.tooltip`
- 标签：`module3.label.provider_filter`, `module3.label.sku_id`, `module3.label.sku_name`, `module3.label.sku_price`, `module3.label.provider`, `module3.label.status`
- 按钮：`module3.btn.add_sku`, `module3.btn.edit_sku`, `module3.btn.update_sku`, `module3.btn.delete_sku`, `module3.btn.import_json`, `module3.btn.export_json`, `module3.btn.import_csv`, `module3.btn.export_csv`, `module3.btn.manual_sync`, `module3.btn.deactivate`, `module3.btn.activate`
- 复选框：`module3.checkbox.show_inactive`, `module3.checkbox.debug_mode`
- 服务商筛选选项：`module3.provider_filter_option.all`, `module3.provider_filter_option.google`, `module3.provider_filter_option.apple`, `module3.provider_filter_option.huawei`
- Tree 列标题：`module3.column.id`, `module3.column.name`, `module3.column.price`, `module3.column.provider`, `module3.column.status`
- 状态文本：`status.active`, `status.inactive`, `status.pending`

---

## 📦 模块 4：测试模拟区

**节点路径：** `MainVBox/Module4_Test`

```
Module4_Test (VBoxContainer)
├── TitleRow4 (HBoxContainer)
│   ├── Title4 (Label) - 模块标题
│   └── module4_info (Label) - 信息图标 ⓘ
├── Row1 (HBoxContainer) - 模拟按钮
│   ├── btn_simulate_success (Button) - 模拟购买成功
│   ├── btn_simulate_no_stock (Button) - 模拟库存不足
│   └── btn_simulate_cancel (Button) - 模拟取消购买
└── Row2 (HBoxContainer) - 控制按钮
    ├── btn_reset_test (Button) - 重置测试状态
    └── debug_checkbox (CheckBox) - 调试模式
```

### 功能说明
- 模拟购买成功/失败场景
- 库存数量模拟
- 测试状态重置
- 调试模式开关

### 本地化键位
- 标题：`module4.title`
- 工具提示：`module4.tooltip`
- 按钮：`module4.btn.simulate_success`, `module4.btn.simulate_no_stock`, `module4.btn.simulate_cancel`, `module4.btn.reset_test`
- 复选框：`module4.checkbox.debug`

---

## 📦 模块 5：日志输出区

**节点路径：** `MainVBox/Module5_Log`

```
Module5_Log (VBoxContainer)
├── TitleRow5 (HBoxContainer)
│   ├── Title5 (Label) - 模块标题
│   └── module5_info (Label) - 信息图标 ⓘ
├── log_text (TextEdit) - 日志显示框（只读）
└── Row1 (HBoxContainer)
    ├── btn_clear_log (Button) - 清空日志
    └── btn_export_log (Button) - 导出日志
```

### 功能说明
- 操作日志记录
- 时间戳显示
- 日志清空与导出

### 本地化键位
- 标题：`module5.title`
- 工具提示：`module5.tooltip`
- 按钮：`module5.btn.clear_log`, `module5.btn.export_log`

---

## 📦 模块 6：服务端配置区

**节点路径：** `MainVBox/Module6_ServerConfig`

```
Module6_ServerConfig (VBoxContainer)
├── TitleRow6 (HBoxContainer)
│   ├── Title6 (Label) - 模块标题
│   └── module6_info (Label) - 信息图标 ⓘ
├── AccountRow (HBoxContainer) - 账户管理
│   ├── AccountLabel (Label) - "账户:"
│   ├── account_selector (OptionButton) - 账户选择器
│   ├── btn_new_account (Button) - 新建账户
│   ├── btn_save_account (Button) - 保存账户
│   ├── btn_delete_account (Button) - 删除账户
│   └── btn_rename_account (Button) - 重命名账户
├── input_dialog (AcceptDialog) - 输入对话框
│   └── input_field (LineEdit) - 输入框
├── confirm_dialog (AcceptDialog) - 确认对话框
├── Row1 (HBoxContainer) - 服务商选择
│   ├── Label1 (Label) - "服务商:"
│   └── server_provider (OptionButton) - 服务商选择
├── Row2 (HBoxContainer) - 环境选择
│   ├── Label2 (Label) - "环境:"
│   └── server_env (OptionButton) - 环境选择（沙盒/生产）
├── google_config_container (VBoxContainer) - Google 配置
│   ├── GoogleRow1 (HBoxContainer)
│   │   ├── GoogleLabel1 (Label) - "密钥文件:"
│   │   ├── google_key_path (LineEdit) - 密钥文件路径
│   │   └── btn_select_google_key (Button) - 选择文件
│   └── GoogleRow2 (HBoxContainer)
│       ├── GoogleLabel2 (Label) - "包名:"
│       └── google_package_name (LineEdit) - 包名输入
├── apple_config_container (VBoxContainer) - Apple 配置
│   ├── AppleRow1 (HBoxContainer)
│   │   ├── AppleLabel1 (Label) - "Issuer ID:"
│   │   └── apple_issuer_id (LineEdit) - Issuer ID
│   ├── AppleRow2 (HBoxContainer)
│   │   ├── AppleLabel2 (Label) - "Key ID:"
│   │   └── apple_key_id (LineEdit) - Key ID
│   ├── AppleRow3 (HBoxContainer)
│   │   ├── AppleLabel3 (Label) - "Bundle ID:"
│   │   └── apple_bundle_id (LineEdit) - Bundle ID
│   └── AppleRow4 (HBoxContainer)
│       ├── AppleLabel4 (Label) - "私钥文件:"
│       ├── apple_key_path (LineEdit) - 私钥文件路径
│       └── btn_select_apple_key (Button) - 选择文件
├── huawei_config_container (VBoxContainer) - 华为配置
│   ├── HuaweiRow1 (HBoxContainer)
│   │   ├── HuaweiLabel1 (Label) - "API 密钥:"
│   │   └── huawei_api_key (LineEdit) - API 密钥
│   └── HuaweiRow2 (HBoxContainer)
│       ├── HuaweiLabel2 (Label) - "应用 ID:"
│       └── huawei_app_id (LineEdit) - 应用 ID
├── ConfigRow (HBoxContainer) - 配置操作按钮
│   ├── btn_save_server_config (Button) - 保存配置
│   ├── btn_load_server_config (Button) - 加载配置
│   └── btn_test_connection (Button) - 测试连接
└── validation_warning_dialog (AcceptDialog) - 验证失败对话框
```

### 功能说明
- 多账户管理（新建/保存/删除/重命名）
- 服务商配置（Google/Apple/华为/自定义）
- 环境切换（沙盒/生产）
- 各平台配置参数管理
- 配置验证与测试连接

### 本地化键位
- 标题：`module6.title`
- 工具提示：`module6.tooltip`
- 标签：`module6.label.provider`, `module6.label.env`, `module6.label.custom_url`, `module6.label.google_config`, `module6.label.apple_config`, `module6.label.huawei_config`, `module6.label.package_name`, `module6.label.key_path`, `module6.label.issuer_id`, `module6.label.key_id`, `module6.label.bundle_id`, `module6.label.api_key`, `module6.label.app_id`
- 按钮：`module6.btn.select_file`, `module6.btn.save_config`, `module6.btn.load_config`, `module6.btn.test_connection`, `module6.btn.new_account`, `module6.btn.save_account`, `module6.btn.delete_account`, `module6.btn.rename_account`
- 服务商选项：`module6.provider_option.google`, `module6.provider_option.apple`, `module6.provider_option.huawei`, `module6.provider_option.custom`
- 环境选项：`module2.env_option.sandbox`, `module2.env_option.production`

---

## 📦 模块 7：验单测试工具区

**节点路径：** `MainVBox/Module7_Verification`

```
Module7_Verification (VBoxContainer)
├── TitleRow7 (HBoxContainer)
│   ├── Title7 (Label) - 模块标题
│   └── module7_info (Label) - 信息图标 ⓘ
├── ProviderRow (HBoxContainer) - 服务商选择
│   ├── ProviderLabel (Label) - "服务商:"
│   └── test_provider (OptionButton) - 服务商选择
├── test_google_container (VBoxContainer) - Google 测试配置
│   ├── GoogleRow1 (HBoxContainer)
│   │   ├── GoogleLabel1 (Label) - "商品 ID:"
│   │   └── test_google_product_id (LineEdit)
│   ├── GoogleRow2 (HBoxContainer)
│   │   ├── GoogleLabel2 (Label) - "购买令牌:"
│   │   └── test_google_purchase_token (LineEdit)
│   └── GoogleRow3 (HBoxContainer)
│       ├── GoogleLabel3 (Label) - "订单 ID(可选):"
│       └── test_google_order_id (LineEdit)
├── test_apple_container (VBoxContainer) - Apple 测试配置
│   ├── AppleRow1 (HBoxContainer)
│   │   ├── AppleLabel1 (Label) - "商品 ID:"
│   │   └── test_apple_product_id (LineEdit)
│   ├── AppleRow2 (HBoxContainer)
│   │   ├── AppleLabel2 (Label) - "交易 ID:"
│   │   └── test_apple_transaction_id (LineEdit)
│   ├── AppleRow3 (HBoxContainer)
│   │   ├── AppleLabel3 (Label) - "原始交易 ID:"
│   │   └── test_apple_original_transaction_id (LineEdit)
│   └── AppleRow4 (HBoxContainer)
│       ├── AppleLabel4 (Label) - "订单 ID(可选):"
│       └── test_apple_order_id (LineEdit)
├── test_huawei_container (VBoxContainer) - 华为测试配置
│   ├── HuaweiRow1 (HBoxContainer)
│   │   ├── HuaweiLabel1 (Label) - "商品 ID:"
│   │   └── test_huawei_product_id (LineEdit)
│   ├── HuaweiRow2 (HBoxContainer)
│   │   ├── HuaweiLabel2 (Label) - "购买令牌:"
│   │   └── test_huawei_purchase_token (LineEdit)
│   └── HuaweiRow3 (HBoxContainer)
│       ├── HuaweiLabel3 (Label) - "订单 ID(可选):"
│       └── test_huawei_order_id (LineEdit)
├── ButtonRow (HBoxContainer) - 操作按钮
│   ├── btn_test_verification (Button) - 模拟验单
│   └── btn_clear_test_response (Button) - 清除结果
└── test_response_display (TextEdit) - 响应结果显示框（只读）
```

### 功能说明
- 模拟向各商店发起验单请求
- 显示模拟响应数据
- 输入字段随选中服务商动态切换
- 支持 Google/Apple/华为三平台

### 本地化键位
- 标题：`module7.title`
- 工具提示：`module7.tooltip`
- 标签：`module7.label.product_id`, `module7.label.token`, `module7.label.order_id`, `module7.label.response`
- 按钮：`module7.btn.simulate_verify`, `module7.btn.clear_response`
- 服务商选项：复用 `module6.provider_option.*`

---

## 🔧 对话框组件

### 输入对话框
**节点路径：** `MainVBox/Module6_ServerConfig/input_dialog`
```
input_dialog (AcceptDialog)
└── input_field (LineEdit) - 输入框
```

### 确认对话框
**节点路径：** `MainVBox/Module6_ServerConfig/confirm_dialog`
```
confirm_dialog (AcceptDialog)
```

### 验证失败对话框
**节点路径：** `MainVBox/Module6_ServerConfig/validation_warning_dialog`
```
validation_warning_dialog (AcceptDialog)
```

### 本地化键位
- 文件对话框标题：`filedialog.title.select_google_key`, `filedialog.title.save_server_config` 等
- 确认对话框：`dialog.confirm_delete_account`, `dialog.confirm_deactivate_sku` 等

---

## 📊 UI 元素统计

| 类别 | 数量 | 说明 |
|------|------|------|
| **模块总数** | 7 个 | 基础 IAP、计费服务、SKU 管理、测试模拟、日志、服务端配置、验单工具 |
| **按钮 (Button)** | 35+ 个 | 查询、保存、导入导出、模拟等 |
| **标签 (Label)** | 50+ 个 | 标题、说明、字段名等 |
| **输入框 (LineEdit)** | 25+ 个 | 订单 ID、SKU 信息、配置参数等 |
| **下拉框 (OptionButton)** | 10+ 个 | 语言、服务商、环境选择等 |
| **复选框 (CheckBox)** | 3 个 | 显示已停用、调试模式等 |
| **Tree** | 1 个（5 列） | SKU 列表展示 |
| **TextEdit** | 3 个 | 日志显示、响应结果显示 |
| **对话框 (Dialog)** | 4 个 | 输入、确认、验证失败等 |
| **分隔符 (Separator)** | 6 个 | 模块间分隔 |
| **信息图标 (ℹ)** | 7 个 | 每个模块的说明提示 |

---

## 🌐 本地化覆盖范围

### ✅ 已本地化的元素

- **所有按钮文本** - 查询、保存、删除、导入导出等
- **所有标签文本** - 模块标题、字段标签、状态标签等
- **所有输入框占位符** - 订单 ID、商品名称、价格、配置参数等
- **所有工具提示** - 按钮、输入框、状态标签、信息图标等
- **所有下拉框选项** - 语言、服务商、环境、筛选器等
- **Tree 列标题** - ID、名称、价格、服务商、状态
- **对话框标题和内容** - 输入、确认、验证失败等
- **日志消息** - 所有操作日志、错误提示、成功消息等
- **状态文本** - 就绪、成功、失败、生效中等

### 📁 语言文件位置

- **中文：** `res://addons/google_iap/locales/zh.json`
- **英文：** `res://addons/google_iap/locales/en.json`

### 🔑 键名命名规范

采用模块化嵌套结构：
```
模块号.类别.具体项
例如：
- module1.btn.check_order
- module3.label.sku_id
- module6.provider_option.google
- log.sku_added_success
- status.active
```

---

## 📝 使用说明

### 添加新的 UI 元素

1. 在场景文件中添加节点
2. 在语言文件中添加对应的键值对（中英文）
3. 在 `_apply_localization()` 函数中添加文本绑定
4. 确保在 `_on_language_changed()` 时能够刷新

### 修改现有文本

1. 在语言文件中修改对应键的值
2. 不要直接在脚本或场景中硬编码文本
3. 保持中英文语言文件同步更新

### 调试本地化问题

1. 检查语言文件 JSON 格式是否正确
2. 确认键名拼写与代码中一致
3. 验证 `_t()` 函数是否能正确访问嵌套键
4. 测试语言切换时所有文本是否正确更新

---

**文档版本：** 1.0  
**最后更新：** 2026-03-13  
**适用插件版本：** Google IAP Plugin v1.0+
