# 模块 7 Label 初始文本修复说明

## 问题根源

在 TSCN 场景文件中，模块 7 的所有 Label 节点都**没有设置初始 `text` 属性**，导致：
1. Godot 加载场景时，这些标签是空的
2. 切换语言时，GDScript 的 `_update_ui_texts()` 函数虽然会更新文本，但如果 Godot 缓存了旧版本，就会显示错误
3. 特别是华为容器，在中文环境下显示英文

## 已修复的内容

### Google 容器 Label
- ✅ `module7_product_id_label` → `text = "商品 ID:"`
- ✅ `module7_token_label` → `text = "购买令牌:"`
- ✅ `module7_order_id_label` → `text = "订单 ID(可选):"`

### Apple 容器 Label
- ✅ `module7_apple_product_id_label` → `text = "商品 ID:"`
- ✅ `module7_transaction_id_label` → `text = "交易 ID:"`
- ✅ `module7_original_transaction_id_label` → `text = "原始交易 ID(可选):"`
- ✅ `module7_apple_order_id_label` → `text = "订单 ID(可选):"`

### 华为容器 Label
- ✅ `module7_huawei_product_id_label` → `text = "商品 ID:"`
- ✅ `module7_huawei_token_label` → `text = "购买令牌:"`
- ✅ `module7_huawei_order_id_label` → `text = "订单 ID(可选):"`

## 修复原理

### 1. TSCN 中的初始文本
```ini
[node name="module7_huawei_product_id_label" type="Label" ...]
layout_mode = 2
custom_minimum_size = Vector2(150, 0)
unique_name_in_owner = true
text = "商品 ID:"  # ← 新增这行
```

### 2. GDScript 运行时更新
```gdscript
if module7_huawei_product_id_label:
    module7_huawei_product_id_label.text = _t("module7.huawei.label.product_id") + ":"
```

### 3. 工作流程
1. **场景加载时**：使用 TSCN 中的初始中文文本
2. **插件初始化时**：`_update_ui_texts()` 根据当前语言更新所有文本
3. **切换语言时**：再次调用 `_update_ui_texts()` 刷新文本
4. **切换服务商时**：容器可见性切换，但文本已正确更新

## 验证步骤

### 在 Godot 中测试：

1. **重新加载项目**
   - 按 `Ctrl + Shift + R` 或关闭后重新打开

2. **测试中文环境**
   - 确保语言是中文
   - 选择 Google → 应显示"商品 ID:"、"购买令牌:"等
   - 选择 Apple → 应显示"商品 ID:"、"交易 ID:"等
   - 选择华为 → 应显示"商品 ID:"、"购买令牌:"等

3. **测试英文环境**
   - 切换到英文语言
   - 选择 Google → 应显示"Product ID:"、"Purchase Token:"等
   - 选择 Apple → 应显示"Product ID:"、"Transaction ID:"等
   - 选择 Huawei → 应显示"Product ID:"、"Purchase Token:"等

4. **测试切换服务商**
   - 在中文环境下，从 Google 切换到华为
   - 输入框应该被清空
   - 标签应保持中文显示

## 预期结果

✅ 所有 Label 在场景加载时显示正确的中文初始文本  
✅ 切换语言时，所有文本立即更新  
✅ 切换服务商时，只显示对应容器的输入框  
✅ 切换服务商时，所有输入框被清空  
✅ 无任何文本显示错误  

## 技术说明

### 为什么需要初始文本？

1. **视觉反馈**：在编辑器中就能看到正确的初始状态
2. **避免空标签**：防止 Godot 缓存导致显示问题
3. **调试友好**：即使 GDScript 执行失败，也能看到中文而非空白
4. **一致性**：与 Godot 最佳实践保持一致

### 文本更新流程

```
场景加载 → TSCN 初始文本（中文）
    ↓
插件初始化 → _update_ui_texts() → 根据当前语言更新
    ↓
用户切换语言 → _update_ui_texts() → 刷新所有文本
    ↓
用户切换服务商 → _on_module7_provider_option_selected() 
              → 切换容器可见性 + 清空输入框
```

## 文件修改清单

- ✅ `GoogleIAPConfigPanel.tscn` - 为 11 个 Label 添加初始文本
- ✅ `GoogleIAPConfigPanel.gd` - 添加 `_clear_module7_inputs()` 函数
- ✅ `zh.json` - 包含所有服务商分组的语言键
- ✅ `en.json` - 包含所有服务商分组的语言键

## 下一步

**请在 Godot 编辑器中重新加载项目并测试！**

如果问题仍然存在：
1. 关闭 Godot
2. 删除 `.godot` 缓存文件夹
3. 重新打开项目
4. 再次测试所有功能
