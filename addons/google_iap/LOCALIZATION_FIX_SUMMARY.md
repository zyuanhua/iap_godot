# TSCN 场景与中英文切换功能修复总结

## 修复完成时间
2026-03-13

## 核心问题
TSCN 文件中所有 Label 标签的文本被清空，中英文切换无效。

## 已完成的修复工作

### 一、TSCN 场景文件修复

#### 1. 节点文本设置
✅ 为所有需要文本的节点添加了初始中文文本：
- **Title 节点**：模块 1-7 的标题
- **Label 节点**：所有标签文本（带冒号）
- **Button 节点**：所有按钮文本
- **CheckBox 节点**：所有复选框文本

#### 2. 工具提示设置
✅ 为所有信息图标（ⓘ）和 UI 元素添加了 tooltip_text：
- 模块描述信息图标
- 按钮工具提示
- 输入框工具提示
- 状态标签工具提示

#### 3. 占位符文本设置
✅ 为所有 LineEdit 和 TextEdit 节点添加了 placeholder_text：
- 订单 ID 输入框
- SKU ID/名称/价格输入框
- 各种配置输入框

#### 4. 节点唯一名称设置
✅ 为所有需要动态更新文本的节点添加了 `unique_name_in_owner = true`：
- 所有 Title 节点
- 所有 Label 节点
- 所有信息图标节点
- 所有需要脚本引用的节点

#### 5. OptionButton 选项设置
✅ 为所有 OptionButton 节点添加了初始中文选项：
- **env_option**：沙盒、生产
- **sku_provider_filter**：全部、Google、Apple、华为
- **sku_provider_option**：Google、Apple、华为
- **server_provider**：Google、Apple、华为、自定义
- **server_env**：沙盒、生产
- **test_provider**：Google、Apple、华为

#### 6. Tree 列标题设置
✅ 为 sku_tree 节点添加了列标题：
- ID、名称、价格、服务商、状态

### 二、语言文件完善

#### 1. 中文语言文件 (zh.json)
✅ 新增/完善的键值：
- `module3.provider_option`：服务商选项
- `module6.env_option`：环境选项
- `module7.provider_option`：测试服务商选项
- `status.not_initialized/initializing/connected/refreshing/disconnecting`：服务状态文本

#### 2. 英文语言文件 (en.json)
✅ 同步新增了对应的英文翻译键值

### 三、GDScript 脚本修复

#### 1. OptionButton 选项本地化
✅ 修复了所有硬编码的 OptionButton 选项：
- `_ready()` 函数中的所有 add_item 调用
- 使用 `_t()` 函数获取本地化文本

#### 2. 状态文本本地化
✅ 修复了所有状态文本的键名：
- 使用嵌套键名格式：`status.not_initialized` 等
- 服务状态标签动态更新

#### 3. 语言切换功能
✅ 完整的语言切换流程：
- `_load_localization()`：加载语言文件
- `_apply_localization()`：应用所有 UI 文本
- `_on_language_changed()`：语言切换处理
- `_save_language_preference()`：保存语言设置

### 四、验证与测试

#### 1. 静态文本验证
✅ 所有 TSCN 节点文本已设置：
- 标题、标签、按钮、复选框
- 工具提示、占位符

#### 2. 动态文本验证
✅ 所有动态更新的文本已本地化：
- OptionButton 选项
- Tree 列标题
- 状态标签文本
- 日志文本

#### 3. 语言切换验证
✅ 语言切换功能完整：
- 中文 → 英文切换
- 英文 → 中文切换
- 语言设置持久化

## 备份文件
所有修改的文件都已创建备份：
- `GoogleIAPConfigPanel.tscn.backup` ~ `.backup6`
- `GoogleIAPConfigPanel.gd.backup` ~ `.backup2`

## 使用的修复脚本
1. `fix_tscn_texts.py` - 修复 TSCN 节点文本
2. `cleanup_tscn.py` - 清理重复的 text 行
3. `add_optionbutton_items.py` - 添加 OptionButton 选项
4. `add_tree_columns.py` - 添加 Tree 列标题
5. `fix_optionbutton_code.py` - 修复 GDScript 中的硬编码选项
6. `fix_status_keys.py` - 修复状态文本键名
7. `fix_duplicate_text.py` - 清理重复文本

## 预期效果
✅ 启动插件时：
- 默认显示中文界面
- 所有 UI 元素文本正确显示
- 工具提示正常显示

✅ 切换语言时：
- 所有文本即时切换
- OptionButton 选项更新
- Tree 列标题更新
- 状态标签更新

✅ 重启编辑器后：
- 语言设置保持
- 界面状态恢复

## 注意事项
1. 所有新增的 UI 文本都必须添加到语言文件
2. 动态生成的文本必须使用 `_t()` 函数
3. OptionButton 选项在 `_ready()` 和 `_apply_localization()` 中都需要更新
4. Tree 列标题在语言切换时需要重新设置

## 相关文件
- `addons/google_iap/GoogleIAPConfigPanel.tscn` - 场景文件
- `addons/google_iap/GoogleIAPConfigPanel.gd` - 脚本文件
- `addons/google_iap/locales/zh.json` - 中文语言文件
- `addons/google_iap/locales/en.json` - 英文语言文件
- `addons/google_iap/iap_config.json` - 配置文件（包含语言设置）
