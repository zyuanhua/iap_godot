# 模块 7 完全本地化修复说明

## 问题说明

之前的实现中，TSCN 文件中的 Label 节点使用了硬编码的中文文本（如 `text = "商品 ID:"`），这违反了本地化的最佳实践：

❌ **错误做法**：
```ini
[node name="module7_huawei_product_id_label" type="Label" ...]
text = "商品 ID:"  # 硬编码中文
```

✅ **正确做法**：
```ini
[node name="module7_huawei_product_id_label" type="Label" ...]
# 不设置 text 属性，由 GDScript 运行时动态设置
```

## 已修复内容

### 1. 移除 TSCN 中的所有硬编码文本

已移除以下 Label 的 `text` 属性：

**Google 容器（3 个）**
- ✅ `module7_product_id_label` - 移除 `text = "商品 ID:"`
- ✅ `module7_token_label` - 移除 `text = "购买令牌:"`
- ✅ `module7_order_id_label` - 移除 `text = "订单 ID(可选):"`

**Apple 容器（4 个）**
- ✅ `module7_apple_product_id_label` - 移除 `text = "商品 ID:"`
- ✅ `module7_transaction_id_label` - 移除 `text = "交易 ID:"`
- ✅ `module7_original_transaction_id_label` - 移除 `text = "原始交易 ID(可选):"`
- ✅ `module7_apple_order_id_label` - 移除 `text = "订单 ID(可选):"`

**华为容器（3 个）**
- ✅ `module7_huawei_product_id_label` - 移除 `text = "商品 ID:"`
- ✅ `module7_huawei_token_label` - 移除 `text = "购买令牌:"`
- ✅ `module7_huawei_order_id_label` - 移除 `text = "订单 ID(可选):"`

### 2. GDScript 完全控制文本

所有 Label 的文本现在完全由 GDScript 通过语言文件动态设置：

```gdscript
# 在 _apply_localization() 函数中

# Google 容器
if module7_product_id_label:
    module7_product_id_label.text = _t("module7.google.label.product_id") + ":"

if module7_token_label:
    module7_token_label.text = _t("module7.google.label.purchase_token") + ":"

if module7_order_id_label:
    module7_order_id_label.text = _t("module7.google.label.order_id") + ":"

# Apple 容器
if module7_apple_product_id_label:
    module7_apple_product_id_label.text = _t("module7.apple.label.product_id") + ":"

if module7_transaction_id_label:
    module7_transaction_id_label.text = _t("module7.apple.label.transaction_id") + ":"

# ... 其他标签

# 华为容器
if module7_huawei_product_id_label:
    module7_huawei_product_id_label.text = _t("module7.huawei.label.product_id") + ":"

if module7_huawei_token_label:
    module7_huawei_token_label.text = _t("module7.huawei.label.purchase_token") + ":"

if module7_huawei_order_id_label:
    module7_huawei_order_id_label.text = _t("module7.huawei.label.order_id") + ":"
```

### 3. 语言文件支持

**中文 (zh.json)**:
```json
{
  "module7": {
    "google": {
      "label": {
        "product_id": "商品 ID",
        "purchase_token": "购买令牌",
        "order_id": "订单 ID(可选)"
      }
    },
    "apple": {
      "label": {
        "product_id": "商品 ID",
        "transaction_id": "交易 ID",
        "original_transaction_id": "原始交易 ID(可选)",
        "order_id": "订单 ID(可选)"
      }
    },
    "huawei": {
      "label": {
        "product_id": "商品 ID",
        "purchase_token": "购买令牌",
        "order_id": "订单 ID(可选)"
      }
    }
  }
}
```

**英文 (en.json)**:
```json
{
  "module7": {
    "google": {
      "label": {
        "product_id": "Product ID",
        "purchase_token": "Purchase Token",
        "order_id": "Order ID (Optional)"
      }
    },
    "apple": {
      "label": {
        "product_id": "Product ID",
        "transaction_id": "Transaction ID",
        "original_transaction_id": "Original Transaction ID (Optional)",
        "order_id": "Order ID (Optional)"
      }
    },
    "huawei": {
      "label": {
        "product_id": "Product ID",
        "purchase_token": "Purchase Token",
        "order_id": "Order ID (Optional)"
      }
    }
  }
}
```

## 工作流程

### 1. 场景加载时
```
TSCN 加载
  ↓
@onready 变量绑定
  ↓
所有 Label 初始为空（没有 text 属性）
```

### 2. 插件初始化时
```
_ready() 函数执行
  ↓
_load_localization(current_language)
  ↓
_apply_localization()
  ↓
遍历所有 Label，使用 _t() 从语言文件获取文本
  ↓
设置 Label.text = _t("module7.*.*.*") + ":"
```

### 3. 切换语言时
```
用户切换语言
  ↓
_on_language_changed()
  ↓
_load_localization(new_language)
  ↓
_apply_localization()
  ↓
所有 Label 文本立即更新为新语言
```

### 4. 切换服务商时
```
用户选择服务商
  ↓
_on_module7_provider_option_selected(index)
  ↓
设置容器可见性
  ↓
调用 _clear_module7_inputs() 清空输入框
  ↓
Label 文本保持不变（已经是正确的语言）
```

## 优势

### ✅ 完全本地化
- 所有文本都来自语言文件
- 支持任意数量的语言
- 易于添加新语言

### ✅ 运行时切换
- 无需重新加载场景
- 即时更新所有文本
- 用户体验流畅

### ✅ 代码维护
- 文本与代码分离
- 翻译工作独立进行
- 易于审查和更新

### ✅ 一致性
- 所有模块使用相同的本地化模式
- 遵循 Godot 最佳实践
- 代码结构清晰

## 测试步骤

### 在 Godot 编辑器中：

1. **重新加载项目**
   ```
   按 Ctrl + Shift + R
   或关闭项目后重新打开
   ```

2. **测试中文环境**
   - 确保语言选择器显示"中文"
   - 选择 Google → 检查标签：
     - "商品 ID:"
     - "购买令牌:"
     - "订单 ID(可选):"
   - 选择 Apple → 检查标签：
     - "商品 ID:"
     - "交易 ID:"
     - "原始交易 ID(可选):"
     - "订单 ID(可选):"
   - 选择华为 → 检查标签：
     - "商品 ID:"
     - "购买令牌:"
     - "订单 ID(可选):"

3. **测试英文环境**
   - 切换语言到"English"
   - 重复步骤 2 的检查
   - 所有标签应显示对应的英文

4. **测试语言切换**
   - 在 Google、Apple、华为之间切换
   - 切换语言
   - 所有可见的标签应立即更新

5. **测试输入框清空**
   - 在任意服务商下输入内容
   - 切换到另一个服务商
   - 输入框应被清空

## 预期结果

✅ 所有 Label 初始为空，由 GDScript 动态设置  
✅ 插件加载时，所有标签显示正确的中文  
✅ 切换语言时，所有文本立即更新  
✅ 切换服务商时，只显示对应容器的输入框  
✅ 切换服务商时，所有输入框被清空  
✅ 无任何硬编码文本  
✅ 所有文本都来自语言文件  

## 技术要点

### 1. @onready 变量绑定
```gdscript
@onready var module7_huawei_product_id_label: Label = %module7_huawei_product_id_label
```
- 使用 `%` 前缀访问唯一名称节点
- 节点在场景树中必须有 `unique_name_in_owner = true`

### 2. 语言键访问
```gdscript
_t("module7.huawei.label.product_id")
```
- `_t()` 函数从当前语言文件获取文本
- 键名结构：`模块。服务商。类型。字段`

### 3. 文本格式化
```gdscript
label.text = _t("module7.huawei.label.product_id") + ":"
```
- 语言文件不包含标点符号
- 标点符号在代码中添加，便于统一格式

## 文件修改清单

- ✅ `GoogleIAPConfigPanel.tscn` - 移除 11 个 Label 的硬编码文本
- ✅ `GoogleIAPConfigPanel.gd` - 完整的本地化代码
- ✅ `zh.json` - 所有服务商分组的中文语言键
- ✅ `en.json` - 所有服务商分组的英文语言键

## 下一步

**请在 Godot 编辑器中重新加载项目并测试！**

如果问题仍然存在：
1. 关闭 Godot
2. 删除 `.godot` 缓存文件夹
3. 重新打开项目
4. 再次测试所有功能
