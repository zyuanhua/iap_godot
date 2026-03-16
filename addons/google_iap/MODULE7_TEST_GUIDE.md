# 模块 7 测试指南

## 问题说明
根据截图，当切换到 Huawei 服务商时显示英文而不是中文，这可能是由于 Godot 编辑器缓存了旧的语言文件。

## 解决步骤

### 1. 确保语言文件已保存
- 检查 `zh.json` 和 `en.json` 是否已保存最新版本
- 确认文件中有 `module7.huawei.*` 相关键

### 2. 重新加载 Godot 项目
在 Godot 编辑器中：
1. 点击菜单栏的 **场景 (Scene)** → **重新加载当前场景 (Reload Current Scene)**
2. 或者点击 **项目 (Project)** → **重新加载项目 (Reload Project)**

### 3. 测试步骤

#### 测试 1：默认状态（中文）
1. 启动插件
2. 确保当前语言是中文
3. 模块 7 应该默认显示 Google 容器
4. 检查标签是否显示：
   - "商品 ID:"
   - "购买令牌:"
   - "订单 ID(可选):"

#### 测试 2：切换到 Huawei（中文）
1. 在服务商下拉框中选择"华为"
2. 检查标签是否显示：
   - "商品 ID:"
   - "购买令牌:"
   - "订单 ID(可选):"
3. 输入框的占位符应该是：
   - "请输入商品 ID"
   - "请输入购买令牌"
   - "请输入订单 ID(可选)"

#### 测试 3：切换到英文
1. 将语言切换到英文
2. 选择 Google 服务商
3. 检查标签是否显示：
   - "Product ID:"
   - "Purchase Token:"
   - "Order ID (Optional):"

#### 测试 4：切换到 Huawei（英文）
1. 在服务商下拉框中选择"Huawei"
2. 检查标签是否显示：
   - "Product ID:"
   - "Purchase Token:"
   - "Order ID (Optional):"
3. 输入框的占位符应该是：
   - "Enter product ID"
   - "Enter purchase token"
   - "Enter order ID (Optional)"

### 4. 如果问题仍然存在

#### 方法 1：清除 Godot 缓存
1. 关闭 Godot 编辑器
2. 删除项目目录下的 `.godot` 文件夹
3. 重新打开 Godot 项目

#### 方法 2：手动检查 TSCN 文件
打开 `GoogleIAPConfigPanel.tscn`，找到第 966-976 行，确认：
```ini
[node name="module7_huawei_product_id_label" type="Label" parent="MainVBox/Module7_Verification/test_huawei_container/HuaweiRow1"]
layout_mode = 2
custom_minimum_size = Vector2(150, 0)
unique_name_in_owner = true
# 注意：这里没有 text 属性，因为文本会在运行时通过 GDScript 设置

[node name="module7_huawei_product_id_edit" type="LineEdit" parent="MainVBox/Module7_Verification/test_huawei_container/HuaweiRow1"]
layout_mode = 2
custom_minimum_size = Vector2(250, 30)
unique_name_in_owner = true
placeholder_text = "商品 ID"
tooltip_text = "输入商品 ID"
```

#### 方法 3：检查 GDScript 是否执行
在 `_update_ui_texts()` 函数中添加调试日志：
```gdscript
if module7_huawei_product_id_label:
    var text = _t("module7.huawei.label.product_id")
    _append_log("更新华为商品 ID 标签：" + text)
    module7_huawei_product_id_label.text = text + ":"
```

### 5. 验证语言键访问

运行以下 Python 脚本验证语言键：
```bash
cd d:\work\trae\plug-in\iap\addons\google_iap\locales
python test_huawei_keys.py
```

应该输出正确的中英文文本。

## 新增功能

### 清空输入框功能
现在切换服务商时会自动清空所有输入框，避免数据混淆。

## 预期行为

- ✅ 启动插件时默认显示 Google 容器（中文）
- ✅ 切换服务商时，只显示对应服务商的输入框
- ✅ 切换语言时，所有标签和占位符立即更新
- ✅ 切换服务商时，所有输入框被清空
- ✅ 每个服务商的输入字段完全独立

## 联系支持

如果问题仍然存在，请检查：
1. Godot 编辑器版本
2. 项目语言设置
3. 语言文件加载顺序
4. GDScript 控制台是否有错误信息
