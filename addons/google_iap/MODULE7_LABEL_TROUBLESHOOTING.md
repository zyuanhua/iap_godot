# 模块 7 Label 不显示文本问题 - 完整解决方案

## 问题现象

移除 TSCN 中的硬编码文本后，模块 7 的 Label 在运行时不显示任何文本。

## 根本原因

**Godot 编辑器缓存了旧的 TSCN 场景文件**，导致：
1. 旧的 TSCN 版本中 Label 有 `text` 属性
2. 新的 TSCN 版本移除了 `text` 属性
3. Godot 仍然使用缓存的旧版本
4. GDScript 的 `_apply_localization()` 可能未执行或节点绑定失败

## 验证步骤

### 1. 确认语言文件正确 ✅

已验证，所有语言键都正确：
- `module7.google.label.product_id` = "商品 ID" / "Product ID"
- `module7.google.label.purchase_token` = "购买令牌" / "Purchase Token"
- `module7.huawei.label.product_id` = "商品 ID" / "Product ID"
- 等等...

### 2. 确认 TSCN 节点配置正确 ✅

已验证，所有模块 7 的 Label 节点都有：
- `unique_name_in_owner = true`
- 正确的节点路径
- 没有硬编码的 `text` 属性

### 3. 确认 GDScript 代码正确 ✅

已验证，`_apply_localization()` 函数中有：
```gdscript
if module7_product_id_label:
    module7_product_id_label.text = _t("module7.google.label.product_id") + ":"
```

## 解决方案

### 方法 1：强制重新加载场景（推荐）

在 Godot 编辑器中：

1. **保存所有文件**
   - 按 `Ctrl + S` 保存所有修改

2. **重新加载场景**
   - 按 `Ctrl + Shift + R` (强制重新加载场景)
   - 或者点击菜单：**场景 (Scene)** → **重新加载当前场景 (Reload Current Scene)**

3. **重启 Godot 编辑器**
   - 完全关闭 Godot
   - 重新打开项目

4. **查看输出日志**
   - 打开 Godot 底部的"输出"面板
   - 查看是否有错误信息
   - 查找日志："更新 Google 商品 ID 标签：商品 ID"

### 方法 2：清除 Godot 缓存

如果方法 1 无效：

1. **关闭 Godot 编辑器**

2. **删除缓存文件夹**
   ```
   删除：d:\work\trae\plug-in\iap\.godot
   ```

3. **重新打开 Godot 项目**
   - Godot 会重新导入所有资源

4. **测试模块 7**
   - 检查 Label 是否显示文本

### 方法 3：手动检查节点绑定

在 Godot 中添加调试代码：

1. **打开 GoogleIAPConfigPanel.gd**

2. **在 `_ready()` 函数末尾添加**：
   ```gdscript
   func _ready():
       # ... 现有代码 ...
       
       # 调试：检查模块 7 节点绑定
       _append_log("=== 模块 7 节点绑定检查 ===")
       _append_log("module7_product_id_label: " + str(module7_product_id_label))
       _append_log("module7_token_label: " + str(module7_token_label))
       _append_log("module7_huawei_product_id_label: " + str(module7_huawei_product_id_label))
   ```

3. **在 `_apply_localization()` 函数中添加**：
   ```gdscript
   # Google 输入框
   if module7_product_id_label:
       var text = _t("module7.google.label.product_id")
       _append_log("更新 Google 商品 ID 标签：" + text)
       _append_log("Label 对象：" + str(module7_product_id_label))
       module7_product_id_label.text = text + ":"
   else:
       _append_log("错误：module7_product_id_label 未绑定!")
   ```

4. **重新加载项目并查看日志**

### 方法 4：检查节点唯一名称

在 Godot 编辑器中：

1. **打开 GoogleIAPConfigPanel.tscn 场景**

2. **选择任意模块 7 的 Label**
   - 例如：`test_google_container/GoogleRow1/module7_product_id_label`

3. **检查节点属性**
   - 确认 `Unique Name In Owner` = `true`
   - 确认节点名称是 `module7_product_id_label`

4. **对所有模块 7 的 Label 执行相同检查**

## 预期结果

修复后，应该看到：

### 中文环境
- ✅ Google 容器：
  - "商品 ID:"
  - "购买令牌:"
  - "订单 ID(可选):"
- ✅ Apple 容器：
  - "商品 ID:"
  - "交易 ID:"
  - "原始交易 ID(可选):"
  - "订单 ID(可选):"
- ✅ 华为容器：
  - "商品 ID:"
  - "购买令牌:"
  - "订单 ID(可选):"

### 英文环境
- ✅ Google 容器：
  - "Product ID:"
  - "Purchase Token:"
  - "Order ID (Optional):"
- ✅ Apple 容器：
  - "Product ID:"
  - "Transaction ID:"
  - "Original Transaction ID (Optional):"
  - "Order ID (Optional):"
- ✅ Huawei 容器：
  - "Product ID:"
  - "Purchase Token:"
  - "Order ID (Optional):"

## 技术说明

### 为什么需要移除 TSCN 中的 text 属性？

1. **避免冲突**
   - TSCN 中的硬编码文本会与 GDScript 设置的文本冲突
   - Godot 可能优先使用 TSCN 中的初始值

2. **确保完全本地化**
   - 所有文本应由语言文件控制
   - 运行时动态设置，支持热切换

3. **符合最佳实践**
   - 数据（语言文件）与表现（场景）分离
   - 代码（GDScript）控制逻辑

### @onready 变量绑定机制

```gdscript
@onready var module7_product_id_label: Label = %module7_product_id_label
```

- `%` 前缀表示使用唯一名称查找节点
- Godot 在 `_ready()` 调用前完成绑定
- 如果节点不存在或没有唯一名称，变量为 `null`
- GDScript 中的 `if module7_product_id_label:` 检查确保节点存在

## 快速测试脚本

运行以下 Python 脚本验证所有配置：

```bash
cd d:\work\trae\plug-in\iap\addons\google_iap\locales
python verify_module7_labels.py
```

应该输出所有语言键的正确值。

## 联系支持

如果以上方法都无效，请检查：

1. **Godot 版本**
   - 确保使用 Godot 4.x
   - 旧版本可能有不同的行为

2. **项目设置**
   - 检查语言设置是否正确
   - 确认 zh.json 和 en.json 已正确加载

3. **控制台错误**
   - 查看 Godot 输出面板的错误信息
   - 检查是否有节点找不到的错误

## 总结

✅ 语言文件正确  
✅ TSCN 配置正确  
✅ GDScript 代码正确  
⚠️ **需要强制重新加载 Godot 场景**  

**最可能的原因：Godot 缓存了旧的 TSCN 文件**

**解决方案：按 `Ctrl + Shift + R` 强制重新加载场景**
