# 彻底解决模块 7 语言切换问题

## 问题现象

切换英文后，模块 7 的 Label 仍然显示中文，虽然日志显示获取了英文文本：

```
[2026-03-13T23:44:50] 更新华为商品 ID 标签：Product ID
```

## 根本原因

**Godot 编辑器缓存了旧的场景实例**，导致：
1. GDScript 正确获取了英文文本
2. 但是 UI 显示仍然使用缓存的中文文本
3. `_apply_localization()` 函数虽然被调用，但没有生效

## 解决方案

### 方法 1：完全重启 Godot（推荐）

1. **保存所有文件**
   ```
   Ctrl + S
   ```

2. **关闭 Godot 编辑器**
   ```
   完全退出 Godot
   ```

3. **删除 Godot 缓存**
   ```
   删除文件夹：d:\work\trae\plug-in\iap\.godot
   ```

4. **重新打开 Godot 项目**

5. **测试语言切换**
   - 默认应该是中文
   - 切换到 English
   - 检查模块 7 的标签是否全部变为英文

### 方法 2：强制重新加载场景

如果不想重启 Godot：

1. **保存所有文件**
   ```
   Ctrl + S
   ```

2. **强制重新加载场景**
   ```
   Ctrl + Shift + R
   ```

3. **重新插拔插件**
   - 打开 Godot 菜单：**编辑器 (Editor)** → **编辑器插件 (Editor Plugins)**
   - 取消勾选 Google IAP 插件
   - 重新勾选 Google IAP 插件

4. **测试语言切换**

### 方法 3：添加调试确认

在 GDScript 中添加更详细的日志来确认文本是否真的被设置：

**修改 `_apply_localization()` 函数：**

```gdscript
# Google 输入框
if module7_product_id_label:
    var text = _t("module7.google.label.product_id")
    module7_product_id_label.text = text + ":"
    _append_log("✓ 设置 Google 商品 ID 标签：" + text + " (当前语言：" + current_language + ")")
else:
    _append_log("✗ 错误：module7_product_id_label 未找到")

# 华为输入框
if module7_huawei_product_id_label:
    var text = _t("module7.huawei.label.product_id")
    module7_huawei_product_id_label.text = text + ":"
    _append_log("✓ 设置华为商品 ID 标签：" + text + " (当前语言：" + current_language + ")")
else:
    _append_log("✗ 错误：module7_huawei_product_id_label 未找到")
```

**修改 `_on_language_changed()` 函数：**

```gdscript
func _on_language_changed(index: int):
    if index == 0:
        current_language = "zh"
    else:
        current_language = "en"
    
    _append_log("=== 开始切换语言到：" + _t("language_name") + " ===")
    
    _load_localization(current_language)
    _append_log("✓ 语言文件加载完成")
    
    _apply_localization()
    _append_log("✓ UI 文本应用完成")
    
    _save_language_preference()
    _append_log(_log("log_language_changed", [_t("language_name")]))
    
    _append_log("=== 语言切换完成 ===")
```

### 方法 4：检查节点是否真的被更新

添加运行时检查：

```gdscript
func _on_language_changed(index: int):
    # ... 现有代码 ...
    
    # 检查节点是否真的存在
    _append_log("module7_product_id_label: " + str(module7_product_id_label))
    _append_log("module7_huawei_product_id_label: " + str(module7_huawei_product_id_label))
    
    # 检查文本是否真的被设置
    if module7_product_id_label:
        _append_log("Google 商品 ID 标签实际文本：" + module7_product_id_label.text)
    if module7_huawei_product_id_label:
        _append_log("华为商品 ID 标签实际文本：" + module7_huawei_product_id_label.text)
```

## 验证步骤

### 在 Godot 中执行：

1. **打开输出面板**
   - 点击 Godot 底部的"输出"标签

2. **切换语言到 English**

3. **查看日志输出**
   ```
   === 开始切换语言到：English ===
   ✓ 语言文件加载完成
   ✓ 设置 Google 商品 ID 标签：Product ID (当前语言：en)
   ✓ 设置华为商品 ID 标签：Product ID (当前语言：en)
   ✓ UI 文本应用完成
   === 语言切换完成 ===
   ```

4. **检查 UI 显示**
   - 模块 7 → Google 容器 → 应显示 "Product ID:"
   - 模块 7 → Apple 容器 → 应显示 "Product ID:"
   - 模块 7 → Huawei 容器 → 应显示 "Product ID:"

## 可能的问题

### 问题 1：节点绑定失败

**症状**：日志显示 "module7_product_id_label 未找到"

**原因**：节点名称冲突或 unique_name_in_owner 未设置

**解决**：
- 确认 TSCN 中所有模块 7 节点都有 `unique_name_in_owner = true`
- 确认没有节点名称冲突（查看 Godot 输出中的 WARNING）

### 问题 2：_apply_localization() 未执行

**症状**：日志中没有"设置 XXX 标签"的记录

**原因**：函数调用路径有问题

**解决**：
- 检查 `_on_language_changed()` 是否被调用
- 检查 `_ready()` 中是否调用了 `_apply_localization()`

### 问题 3：文本被其他代码覆盖

**症状**：日志显示设置了英文，但 UI 显示中文

**原因**：其他地方又设置了中文文本

**解决**：
- 搜索所有修改 module7_label.text 的代码
- 确保没有其他函数修改这些 Label

### 问题 4：Godot 缓存问题

**症状**：代码正确但 UI 不更新

**原因**：Godot 缓存了旧的场景或脚本

**解决**：
- 删除 `.godot` 缓存文件夹
- 重启 Godot 编辑器

## 预期结果

修复后，应该看到：

### 中文环境
```
=== 开始切换语言到：中文 ===
✓ 设置 Google 商品 ID 标签：商品 ID (当前语言：zh)
✓ 设置华为商品 ID 标签：商品 ID (当前语言：zh)
=== 语言切换完成 ===
```

UI 显示：
- Google 容器："商品 ID:"、"购买令牌:"、"订单 ID(可选):"
- Apple 容器："商品 ID:"、"交易 ID:"等
- Huawei 容器："商品 ID:"、"购买令牌:"等

### 英文环境
```
=== 开始切换语言到：English ===
✓ 设置 Google 商品 ID 标签：Product ID (当前语言：en)
✓ 设置华为商品 ID 标签：Product ID (当前语言：en)
=== 语言切换完成 ===
```

UI 显示：
- Google 容器："Product ID:"、"Purchase Token:"、"Order ID (Optional):"
- Apple 容器："Product ID:"、"Transaction ID:"等
- Huawei 容器："Product ID:"、"Purchase Token:"等

## 快速测试脚本

运行以下 Python 脚本验证语言文件：

```bash
cd d:\work\trae\plug-in\iap\addons\google_iap\locales
python verify_module7_labels.py
```

应该输出所有语言键的正确值。

## 总结

**最可能的原因：Godot 缓存问题**

**最佳解决方案：**
1. 关闭 Godot
2. 删除 `.godot` 缓存文件夹
3. 重新打开 Godot
4. 测试语言切换

**如果仍然无效，添加调试日志查看详细执行流程。**
