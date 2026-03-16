# 模块 7 语言切换调试指南

## 🎯 问题

切换英文后，模块 7 的 Label 仍然显示中文，虽然日志显示获取了英文文本。

## 🔧 已添加调试功能

已添加详细的调试日志，帮助诊断问题：

### 1. 语言切换日志
```gdscript
=== 开始切换语言到：English ===
当前语言代码：en
✓ 语言文件加载完成
✓ UI 文本应用完成
=== 语言切换完成 ===
```

### 2. _apply_localization() 执行日志
```gdscript
>>> _apply_localization() 开始执行
>>> 当前语言：en
...
<<< _apply_localization() 执行完成
```

### 3. Label 设置详情
```gdscript
✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
  节点引用：Label:module7_product_id_label
  设置后文本：Product ID:
✓ [Huawei] 商品 ID 标签已设置：Product ID (语言：en)
  节点引用：Label:module7_huawei_product_id_label
  设置后文本：Product ID:
```

## 📋 测试步骤

### 步骤 1：重新加载 Godot 项目

1. **保存所有文件**
   ```
   按 Ctrl + S
   ```

2. **强制重新加载场景**
   ```
   按 Ctrl + Shift + R
   ```

### 步骤 2：查看初始状态

1. **打开 Godot 输出面板**
   - 点击底部的"输出"标签
   - 确保能看到日志输出

2. **查看插件加载日志**
   ```
   >>> _apply_localization() 开始执行
   >>> 当前语言：zh
   ✓ [Google] 商品 ID 标签已设置：商品 ID (语言：zh)
   ```

3. **确认初始语言是中文**
   - 模块 7 应该显示中文标签

### 步骤 3：切换语言到 English

1. **在插件界面切换语言**
   - 找到语言选择器（右上角）
   - 选择"English"

2. **立即查看输出日志**
   
   **应该看到：**
   ```
   === 开始切换语言到：English ===
   当前语言代码：en
   >>> _apply_localization() 开始执行
   >>> 当前语言：en
   ✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
     节点引用：Label:module7_product_id_label
     设置后文本：Product ID:
   ✓ [Huawei] 商品 ID 标签已设置：Product ID (语言：en)
     节点引用：Label:module7_huawei_product_id_label
     设置后文本：Product ID:
   <<< _apply_localization() 执行完成
   ✓ UI 文本应用完成
   === 语言切换完成 ===
   ```

3. **检查 UI 显示**
   - 模块 7 → Google 容器 → 应该显示 "Product ID:"
   - 模块 7 → Apple 容器 → 应该显示 "Product ID:"
   - 模块 7 → Huawei 容器 → 应该显示 "Product ID:"

### 步骤 4：切换回中文

1. **切换语言到"中文"**

2. **查看日志**
   ```
   === 开始切换语言到：中文 ===
   当前语言代码：zh
   ✓ [Google] 商品 ID 标签已设置：商品 ID (语言：zh)
   ```

3. **检查 UI**
   - 所有标签应该变回中文

## 🔍 诊断问题

### 情况 1：日志显示设置成功，但 UI 显示错误

**症状：**
```
✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
  设置后文本：Product ID:
```
但 UI 上显示的是中文"商品 ID:"

**原因：** Godot 缓存了旧的场景实例

**解决：**
1. 关闭 Godot
2. 删除 `d:\work\trae\plug-in\iap\.godot` 文件夹
3. 重新打开 Godot
4. 再次测试

### 情况 2：日志显示节点未找到

**症状：**
```
✗ [错误] module7_product_id_label 未找到!
```

**原因：** 节点绑定失败

**解决：**
1. 检查 TSCN 中节点是否有 `unique_name_in_owner = true`
2. 检查是否有节点名称冲突
3. 查看 Godot 输出中的 WARNING 信息

### 情况 3：日志显示设置后文本是中文

**症状：**
```
✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
  设置后文本：商品 ID:
```

**原因：** `_t()` 函数返回了错误的值

**解决：**
1. 检查语言文件是否正确加载
2. 检查 `current_language` 变量是否正确
3. 检查 `_load_localization()` 函数

### 情况 4：根本没有日志输出

**症状：** 切换语言时没有任何日志

**原因：** `_on_language_changed()` 函数未被调用

**解决：**
1. 检查语言选择器的信号连接
2. 确认信号名称是 `item_selected`
3. 检查 `_connect_signals()` 函数

## 📊 预期日志输出

### 完整示例（切换英文）

```
[GoogleIAPEditor] === 插件开始加载 ===
[GoogleIAPEditor] 正在加载 UI 场景...
>>> _apply_localization() 开始执行
>>> 当前语言：zh
✓ [Google] 商品 ID 标签已设置：商品 ID (语言：zh)
  节点引用：Label:module7_product_id_label
  设置后文本：商品 ID:
✓ [Huawei] 商品 ID 标签已设置：商品 ID (语言：zh)
  节点引用：Label:module7_huawei_product_id_label
  设置后文本：商品 ID:
<<< _apply_localization() 执行完成
[GoogleIAPEditor] UI 场景实例化成功
[GoogleIAPEditor] === 插件加载完成 ===

--- 用户切换语言到 English ---

=== 开始切换语言到：English ===
当前语言代码：en
>>> _apply_localization() 开始执行
>>> 当前语言：en
✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
  节点引用：Label:module7_product_id_label
  设置后文本：Product ID:
✓ [Huawei] 商品 ID 标签已设置：Product ID (语言：en)
  节点引用：Label:module7_huawei_product_id_label
  设置后文本：Product ID:
<<< _apply_localization() 执行完成
✓ UI 文本应用完成
=== 语言切换完成 ===
```

## 🛠️ 如果问题仍然存在

### 方案 1：完全清理缓存

```bash
# 关闭 Godot 后执行
cd d:\work\trae\plug-in\iap
rmdir /s /q .godot
```

### 方案 2：检查语言文件

```bash
cd d:\work\trae\plug-in\iap\addons\google_iap\locales
python verify_module7_labels.py
```

### 方案 3：手动检查节点

在 Godot 编辑器中：
1. 打开 GoogleIAPConfigPanel.tscn 场景
2. 选择 `Module7_Verification/test_google_container/GoogleRow1/module7_product_id_label`
3. 检查属性面板：
   - Unique Name In Owner = true
   - Text 属性应该为空（没有硬编码文本）

### 方案 4：添加更多调试

在 GDScript 中添加：

```gdscript
func _process(delta):
    # 每秒检查一次 Label 文本
    if module7_product_id_label:
        if module7_product_id_label.text != "Product ID:" and current_language == "en":
            _append_log("⚠ 警告：Label 文本被修改！当前值：" + module7_product_id_label.text)
```

## ✅ 成功标志

当看到以下日志时，说明问题已解决：

```
✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
  设置后文本：Product ID:
```

并且 UI 上确实显示 "Product ID:"

---

**请按照上述步骤测试，并告诉我日志输出！** 🎯
