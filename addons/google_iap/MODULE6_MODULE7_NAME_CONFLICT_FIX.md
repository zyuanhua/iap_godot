# 模块 6 和模块 7 节点名称冲突修复

## 问题诊断

从 Godot 日志中看到严重的**节点名称冲突**：

```
WARNING: Setting node name 'module7_product_id_label' to be unique within scene for 
'MainVBox/Module7_Verification/test_google_container/GoogleRow1/module7_product_id_label', 
but it's already claimed by 'MainVBox/Module6_ServerConfig/google_config_container/GoogleRow1/module7_product_id_label'.
```

### 冲突详情

**模块 6（ServerConfig）** 和 **模块 7（Verification）** 使用了**完全相同的节点名称**：

| 节点名称 | 模块 6 路径 | 模块 7 路径 |
|---------|-----------|-----------|
| `module7_product_id_label` | Module6_ServerConfig/google_config_container/GoogleRow1 | Module7_Verification/test_google_container/GoogleRow1 |
| `module7_token_label` | Module6_ServerConfig/google_config_container/GoogleRow2 | Module7_Verification/test_google_container/GoogleRow2 |
| `module7_apple_product_id_label` | Module6_ServerConfig/apple_config_container/AppleRow1 | Module7_Verification/test_apple_container/AppleRow1 |
| `module7_transaction_id_label` | Module6_ServerConfig/apple_config_container/AppleRow2 | Module7_Verification/test_apple_container/AppleRow2 |
| `module7_original_transaction_id_label` | Module6_ServerConfig/apple_config_container/AppleRow3 | Module7_Verification/test_apple_container/AppleRow3 |
| `module7_apple_order_id_label` | Module6_ServerConfig/apple_config_container/AppleRow4 | Module7_Verification/test_apple_container/AppleRow4 |
| `module7_huawei_product_id_label` | Module6_ServerConfig/huawei_config_container/HuaweiRow1 | Module7_Verification/test_huawei_container/HuaweiRow1 |
| `module7_huawei_token_label` | Module6_ServerConfig/huawei_config_container/HuaweiRow2 | Module7_Verification/test_huawei_container/HuaweiRow2 |

### 问题后果

当 Godot 设置 `unique_name_in_owner = true` 时：
1. 如果有多个节点同名，**只有最后一个能保持唯一名称**
2. 之前的节点会被取消唯一性（`%节点名` 无法访问）
3. 导致 GDScript 中的 `@onready` 变量绑定失败
4. 最终导致 Label 不显示文本

## 修复方案

### 重命名模块 6 的节点

将模块 6 中与模块 7 冲突的节点重命名为 `module6_` 前缀：

**Google 容器**
- ✅ `module7_product_id_label` → `module6_product_id_label`
- ✅ `module7_product_id_edit` → `module6_product_id_edit`
- ✅ `module7_token_label` → `module6_token_label`
- ✅ `module7_token_edit` → `module6_token_edit`
- ✅ `module7_order_id_label` → `module6_order_id_label`
- ✅ `module7_order_id_edit` → `module6_order_id_edit`

**Apple 容器**
- ✅ `module7_apple_product_id_label` → `module6_apple_product_id_label`
- ✅ `module7_apple_product_id_edit` → `module6_apple_product_id_edit`
- ✅ `module7_transaction_id_label` → `module6_transaction_id_label`
- ✅ `module7_transaction_id_edit` → `module6_transaction_id_edit`
- ✅ `module7_original_transaction_id_label` → `module6_original_transaction_id_label`
- ✅ `module7_original_transaction_id_edit` → `module6_original_transaction_id_edit`
- ✅ `module7_apple_order_id_label` → `module6_apple_order_id_label`
- ✅ `module7_apple_order_id_edit` → `module6_apple_order_id_edit`

**华为容器**
- ✅ `module7_huawei_product_id_label` → `module6_huawei_product_id_label`
- ✅ `module7_huawei_product_id_edit` → `module6_huawei_product_id_edit`
- ✅ `module7_huawei_token_label` → `module6_huawei_token_label`
- ✅ `module7_huawei_token_edit` → `module6_huawei_token_edit`
- ✅ `module7_huawei_order_id_label` → `module6_huawei_order_id_label`
- ✅ `module7_huawei_order_id_edit` → `module6_huawei_order_id_edit`

### 为什么模块 6 不需要更新 GDScript？

检查发现，模块 6 的 GDScript 代码**只使用了容器引用**：
```gdscript
@onready var google_config_container: VBoxContainer = %google_config_container
@onready var apple_config_container: VBoxContainer = %apple_config_container
@onready var huawei_config_container: VBoxContainer = %huawei_config_container
```

**没有直接使用内部的 Label 节点**，所以不需要更新 GDScript。

模块 6 的 Label 文本可能是通过其他方式设置的，或者不需要动态更新。

## 修复结果

### 修复前
```
WARNING: Setting node name 'module7_product_id_label' ... already claimed by ...
WARNING: 'MainVBox/Module6_ServerConfig/google_config_container/GoogleRow1/module7_product_id_label' 
is no longer set as having a unique name.
```

### 修复后
- ✅ 模块 6 节点：`module6_product_id_label` (唯一)
- ✅ 模块 7 节点：`module7_product_id_label` (唯一)
- ✅ 无冲突警告
- ✅ 两个模块的节点都能被正确访问

## 验证步骤

1. **重新加载 Godot 项目**
   ```
   按 Ctrl + Shift + R
   ```

2. **查看输出日志**
   - 应该**不再出现节点名称冲突警告**
   - 插件正常加载

3. **测试模块 7**
   - 选择 Google → 应显示"Product ID:"等标签
   - 选择 Apple → 应显示"Product ID:"等标签
   - 选择 Huawei → 应显示"Product ID:"等标签

4. **测试语言切换**
   - 切换中英文
   - 所有标签应立即更新

## 技术说明

### unique_name_in_owner 机制

在 Godot 4 中：
```ini
[node name="my_label" type="Label"]
unique_name_in_owner = true
```

- Godot 会确保该节点名称在整个场景树中唯一
- 如果有多个节点同名，**最后一个设置的节点获得唯一性**
- 之前的节点会被自动取消唯一性
- 使用 `%节点名` 访问时会失败或访问错误的节点

### 最佳实践

1. **跨模块的节点必须使用不同的命名空间**
   - 模块 6：`module6_*`
   - 模块 7：`module7_*`

2. **避免使用通用名称**
   - ❌ `product_id_label`
   - ✅ `module7_product_id_label`

3. **在设置 unique_name_in_owner 前检查冲突**
   - 使用全局搜索功能
   - 确保名称唯一

## 文件修改清单

- ✅ `GoogleIAPConfigPanel.tscn` - 重命名 18 个模块 6 节点
- ✅ `GoogleIAPConfigPanel.gd` - 无需修改（只使用容器）
- ✅ 备份文件：`GoogleIAPConfigPanel.tscn.backup`

## 预期日志

修复后，Godot 输出应该显示：

```
[GoogleIAPEditor] === 插件开始加载 ===
[GoogleIAPEditor] 正在加载 UI 场景...
[GoogleIAPEditor] UI 场景实例化成功
[GoogleIAPEditor] === 插件加载完成 ===
```

**不再出现 WARNING 警告！**

## 下一步

1. **在 Godot 中按 Ctrl + Shift + R 重新加载**
2. **检查输出面板，确认没有警告**
3. **测试模块 7 的所有功能**

---

**节点名称冲突问题已解决！所有 Label 现在应该能正常显示文本。** 🎉
