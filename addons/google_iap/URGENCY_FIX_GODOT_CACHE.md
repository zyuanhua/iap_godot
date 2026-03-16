# 🚨 紧急修复：Godot 缓存导致语言切换失效

## 问题诊断

**症状：**
- ✅ 日志显示获取了英文文本：`✓ [Google] 商品 ID 标签已设置：Product ID:`
- ❌ UI 显示仍然是中文："商品 ID:"

**根本原因：**
Godot 4.x 有**严重的缓存问题**，当：
1. TSCN 场景文件被修改
2. GDScript 文件被修改
3. 但 Godot 仍然使用缓存的旧版本

## 🎯 立即执行的解决方案

### 步骤 1：完全关闭 Godot

```
保存所有工作
完全退出 Godot 编辑器
```

### 步骤 2：删除所有 Godot 缓存

**在 PowerShell 中执行：**

```powershell
cd d:\work\trae\plug-in\iap
Remove-Item -Recurse -Force .godot -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .import -ErrorAction SilentlyContinue
```

**或者手动删除：**
1. 打开文件资源管理器
2. 进入 `d:\work\trae\plug-in\iap`
3. 删除 `.godot` 文件夹（如果存在）
4. 删除 `.import` 文件夹（如果存在）

### 步骤 3：清理临时文件

**删除所有备份文件：**

```powershell
cd d:\work\trae\plug-in\iap\addons\google_iap
Remove-Item *.backup* -ErrorAction SilentlyContinue
Remove-Item *.py -ErrorAction SilentlyContinue
```

### 步骤 4：重新打开 Godot

```
打开 Godot
选择项目 d:\work\trae\plug-in\iap
等待 Godot 重新导入所有资源
```

### 步骤 5：测试语言切换

1. **等待 Godot 完全加载**
   - 查看底部进度条
   - 确保所有资源导入完成

2. **打开输出面板**
   - 点击底部"输出"标签

3. **查看初始加载日志**
   ```
   >>> 加载语言文件：zh
     文件路径：res://addons/google_iap/locales/zh.json
     ✓ 语言文件加载成功：zh
   ```

4. **切换语言到 English**
   - 找到语言选择器
   - 选择"English"

5. **查看日志**
   ```
   === 开始切换语言到：English ===
   当前语言代码：en
   LOCALES_PATH: res://addons/google_iap/locales/
   >>> 加载语言文件：en
     文件路径：res://addons/google_iap/locales/en.json
     ✓ 语言文件加载成功：en
   >>> _apply_localization() 开始执行
   >>> 当前语言：en
   ✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
     节点引用：Label:module7_product_id_label
     设置后文本：Product ID:
   ```

6. **检查 UI 显示**
   - 模块 7 的所有标签应该显示**英文**
   - 按钮文本应该是"Simulate Verification"

## 🔍 验证步骤

### 验证 1：检查语言文件路径

在 Godot 输出中应该看到：
```
LOCALES_PATH: res://addons/google_iap/locales/
```

### 验证 2：检查语言文件加载

应该看到：
```
>>> 加载语言文件：en
  文件路径：res://addons/google_iap/locales/en.json
  文件存在，开始读取...
  ✓ 语言文件加载成功：en
  ✓ module7 键存在
  ✓ module7.google.label.product_id = Product ID
```

### 验证 3：检查 UI 更新

应该看到：
```
✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
  设置后文本：Product ID:
```

并且**UI 上确实显示 "Product ID:"**

## ⚠️ 如果问题仍然存在

### 方案 A：检查 Godot 版本

```
帮助 → 关于
```

确保使用 **Godot 4.x** 最新版本。

### 方案 B：强制重新导入所有资源

1. **关闭 Godot**
2. **删除 .import 文件夹**
   ```
   d:\work\trae\plug-in\iap\.import
   ```
3. **重新打开 Godot**
4. **等待重新导入**（可能需要几分钟）

### 方案 C：检查场景文件

1. **打开 GoogleIAPConfigPanel.tscn**
2. **搜索 `text =`**
3. **确认模块 7 的 Label 没有硬编码文本**

例如，应该看到：
```ini
[node name="module7_product_id_label" type="Label"]
layout_mode = 2
custom_minimum_size = Vector2(150, 0)
unique_name_in_owner = true
# 没有 text 属性
```

**不应该看到：**
```ini
[node name="module7_product_id_label" type="Label"]
text = "商品 ID"  # ❌ 硬编码文本
```

### 方案 D：检查脚本编译

1. **打开 Godot 菜单**
   ```
   编辑器 → 编辑器设置 → 文本编辑器 → GDScript
   ```

2. **禁用"编译热重载"**（如果有）

3. **重启 Godot**

## 📊 预期完整日志

### 插件加载时
```
[GoogleIAPEditor] === 插件开始加载 ===
>>> 加载语言文件：zh
  文件路径：res://addons/google_iap/locales/zh.json
  ✓ 语言文件加载成功：zh
>>> _apply_localization() 开始执行
>>> 当前语言：zh
✓ [Google] 商品 ID 标签已设置：商品 ID (语言：zh)
  设置后文本：商品 ID:
[GoogleIAPEditor] === 插件加载完成 ===
```

### 切换语言到 English
```
=== 开始切换语言到：English ===
当前语言代码：en
LOCALES_PATH: res://addons/google_iap/locales/
>>> 加载语言文件：en
  文件路径：res://addons/google_iap/locales/en.json
  文件存在，开始读取...
  ✓ 语言文件加载成功：en
  ✓ module7 键存在
  ✓ module7.google.label.product_id = Product ID
>>> _apply_localization() 开始执行
>>> 当前语言：en
✓ [Google] 商品 ID 标签已设置：Product ID (语言：en)
  节点引用：Label:module7_product_id_label
  设置后文本：Product ID:
✓ UI 文本应用完成
=== 语言切换完成 ===
```

## 🎯 关键点

1. **必须完全关闭 Godot**
2. **必须删除 .godot 缓存**
3. **必须等待 Godot 重新导入所有资源**
4. **日志显示"设置后文本"必须与 UI 显示一致**

## ✅ 成功标志

当满足以下条件时，说明问题已解决：

- ✅ 日志显示：`设置后文本：Product ID:`
- ✅ UI 显示：`Product ID:`
- ✅ 两者完全一致

---

**立即执行上述步骤，然后告诉我结果！** 🚀
