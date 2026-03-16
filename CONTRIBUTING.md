# 贡献指南

感谢您对 Google IAP Ultimate 项目的关注！我们欢迎各种形式的贡献。

## 📋 贡献方式

### 1. 报告 Bug
如果您发现了bug，请通过以下方式报告：

**Bug报告模板：**
```markdown
## 问题描述
清晰描述遇到的问题

## 重现步骤
1. 第一步
2. 第二步
3. ...

## 期望行为
描述期望的正常行为

## 实际行为
描述实际发生的错误行为

## 环境信息
- Godot版本：
- 插件版本：
- 操作系统：
- 设备信息：

## 截图/日志
如果有相关截图或日志，请附上
```

### 2. 功能请求
如果您有新的功能想法，请提交功能请求：

**功能请求模板：**
```markdown
## 功能描述
详细描述您希望添加的功能

## 使用场景
说明这个功能在什么场景下有用

## 可能的实现方案
如果您有实现思路，可以在这里描述

## 替代方案
是否有现有的替代方案
```

### 3. 代码贡献
如果您想贡献代码，请遵循以下流程：

## 🔧 开发环境设置

### 前置要求
- Godot Engine 4.0+
- Git
- 基本的GDScript知识

### 设置开发环境

1. **Fork仓库**
   ```bash
   # Fork项目到您的GitHub账户
   # 然后克隆到本地
   git clone https://github.com/your-username/google-iap-ultimate.git
   cd google-iap-ultimate
   ```

2. **创建开发分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **安装依赖**
   ```bash
   # 确保Godot项目正确设置
   # 打开项目并启用插件
   ```

## 📝 代码规范

### GDScript编码规范

**命名约定：**
- 类名：`PascalCase` (例如：`GoogleIAP`)
- 函数名：`snake_case` (例如：`init_iap_service`)
- 变量名：`snake_case` (例如：`user_config`)
- 常量名：`SCREAMING_SNAKE_CASE` (例如：`MAX_RETRY_COUNT`)

**代码格式：**
```gdscript
# 正确的格式
extends Node

# 类变量
var class_variable: String = "default"

# 信号定义
signal purchase_completed(product_id: String)

func _ready() -> void:
    # 函数实现
    pass

# 私有函数使用下划线前缀
func _private_method() -> void:
    pass
```

### 文档规范

**函数文档：**
```gdscript
## 初始化IAP服务
##
## @param config_path: 配置文件路径
## @return: 初始化是否成功
func init_iap_service(config_path: String) -> bool:
    # 实现...
    return true
```

### 提交信息规范

**提交信息格式：**
```
类型(范围): 简短描述

详细描述（可选）

关闭 #Issue编号（可选）
```

**类型说明：**
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构代码
- `test`: 测试相关
- `chore`: 构建工具或依赖更新

**示例：**
```
feat(sku): 添加SKU批量导入功能

- 支持CSV格式批量导入
- 添加数据验证机制
- 优化导入性能

关闭 #123
```

## 🧪 测试要求

### 单元测试
所有新功能必须包含单元测试：

```gdscript
# 在 test/ 目录下创建对应的测试文件
extends GutTest

func test_sku_validation():
    var iap = GoogleIAP.new()
    assert_true(iap.validate_sku("valid_product_id"))
    assert_false(iap.validate_sku(""))
```

### 集成测试
重要功能需要集成测试：
- 多平台兼容性测试
- 端到端流程测试
- 性能测试

## 🔍 代码审查流程

### 提交Pull Request

1. **确保代码质量**
   - 通过所有测试
   - 符合编码规范
   - 包含必要的文档

2. **创建PR**
   ```markdown
   ## 变更描述
   详细描述本次PR的变更内容
   
   ## 相关Issue
   关联的Issue编号
   
   ## 测试结果
   描述测试情况和结果
   
   ## 截图
   如果有UI变更，请附上截图
   ```

3. **代码审查**
   - 至少需要1名核心维护者审查
   - 审查通过后合并

## 📚 文档贡献

### 文档类型
- **使用文档**: 用户指南、教程
- **技术文档**: API参考、架构说明
- **开发文档**: 贡献指南、开发说明

### 文档规范
- 使用Markdown格式
- 包含清晰的目录结构
- 提供实际代码示例
- 保持中英文版本同步

## 🏆 贡献者奖励

### 贡献者名单
所有贡献者将被列入项目贡献者名单。

### 特殊贡献
重大贡献者可能获得：
- 项目维护者权限
- 特殊感谢标识
- 优先技术支持

## ❓ 常见问题

### Q: 如何开始贡献？
A: 从简单的bug修复或文档改进开始，熟悉项目结构后再进行功能开发。

### Q: 代码审查需要多长时间？
A: 通常1-3个工作日，复杂变更可能需要更长时间。

### Q: 如何联系维护团队？
A: 通过GitHub Issues或Discord社区联系。

## 📞 联系方式

- **GitHub Issues**: 问题报告和讨论
- **Discord社区**: 实时交流和技术支持
- **邮件支持**: 企业级技术支持

---

**感谢您的贡献！** 🎉

---

*最后更新: 2026-03-16*  
*维护者: zyuanhua*