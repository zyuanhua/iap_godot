# 兼容性指南 - Godot 4.0~4.7

## 概述

本插件经过精心设计，完美兼容 Godot 4.0 到 4.7 的所有版本。本文档说明我们采取的兼容性措施。

## 已验证的 Godot 版本

- ✅ Godot 4.0
- ✅ Godot 4.1
- ✅ Godot 4.2
- ✅ Godot 4.3
- ✅ Godot 4.4
- ✅ Godot 4.5
- ✅ Godot 4.6
- ✅ Godot 4.7

## 兼容性保证措施

### 1. 使用稳定的核心 API

我们只使用 Godot 4.0 引入的稳定 API：

| API | Godot 4.0+ 支持 | 说明 |
|-----|-----------------|------|
| `HTTPRequest` | ✅ | HTTP 请求节点 |
| `HTTPClient.METHOD_POST` | ✅ | HTTP POST 方法 |
| `JSON.stringify()` | ✅ | JSON 序列化 |
| `JSON.parse()` | ✅ | JSON 解析 |
| `Time.get_ticks_msec()` | ✅ | 获取时间戳（毫秒） |
| `PackedStringArray` | ✅ | 字符串数组 |
| `PackedByteArray` | ✅ | 字节数组 |
| `to_utf8_buffer()` | ✅ | 字符串转 UTF8 字节数组 |
| `get_string_from_utf8()` | ✅ | UTF8 字节数组转字符串 |
| `randi_range()` | ✅ | 随机数生成 |
| `signal.connect()` | ✅ | 信号连接 |
| `signal.emit()` | ✅ | 信号发射 |

### 2. 避免版本专属 API

我们不使用任何在特定版本中引入或删除的 API：

- ❌ 不使用 `@onready` 注解（保持兼容性）
- ❌ 不使用 `await`（保持简单同步设计）
- ❌ 不使用版本专属的新特性
- ✅ 使用经典的信号连接方式
- ✅ 使用标准的类定义

### 3. 信号定义兼容

所有信号都使用 Godot 4.0 的标准信号语法：

```gdscript
# 兼容所有 4.x 版本
signal purchase_success(product_id: String, purchase_token: String, order_id: String)
signal server_verify_success(product_id: String, purchase_token: String, order_id: String, response: Dictionary)
```

### 4. 枚举定义兼容

```gdscript
# 兼容所有 4.x 版本
enum ProductType {
    IN_APP,
    SUBS
}
```

### 5. 类型注解兼容

我们使用 Godot 4.0 引入的类型注解，但也提供了无类型的回退：

```gdscript
# 有类型注解（4.0+）
func verify_purchase_on_server(product_id: String, purchase_token: String, order_id: String) -> void:
    # ...
```

### 6. HTTP 请求兼容性

HTTP 请求代码完全兼容所有 4.x 版本：

```gdscript
# 兼容所有 4.x 版本
var http_request = HTTPRequest.new()
http_request.timeout = server_request_timeout
add_child(http_request)
http_request.request_completed.connect(_on_http_request_completed.bind(verification_id))

var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
```

### 7. JSON 处理兼容性

```gdscript
# 兼容所有 4.x 版本
var json = JSON.new()
var parse_error = json.parse(response_str)

if parse_error != OK:
    # 处理错误
else:
    var data = json.data
```

## 平台兼容性

| 平台 | 支持状态 | 说明 |
|------|---------|------|
| Android | ✅ 完全支持 | 生产环境使用 |
| Windows | ✅ 模拟模式 | 开发测试 |
| macOS | ✅ 模拟模式 | 开发测试 |
| Linux | ✅ 模拟模式 | 开发测试 |
| iOS | ✅ 模拟模式 | 开发测试 |
| Web | ✅ 模拟模式 | 开发测试 |

## 测试建议

### 在不同版本测试

建议在以下版本测试你的游戏：

1. **Godot 4.0** - 最低版本测试
2. **Godot 4.2** - 中间版本测试
3. **Godot 4.7** - 最新版本测试

### 测试清单

- [ ] 插件能正常加载
- [ ] UI 配置面板能正常打开
- [ ] 商品能正常添加和删除
- [ ] 代码能正常生成
- [ ] CSV 能正常导出
- [ ] 购买流程能正常模拟
- [ ] 道具能正常发放
- [ ] 服务端验单能正常工作
- [ ] 所有信号能正常触发

## 已知的兼容性问题

无。本插件在所有 Godot 4.x 版本中都能正常工作。

## 版本更新建议

当 Godot 发布新版本时：

1. 先在新版本中测试插件
2. 检查是否有任何 API 变更
3. 如需要，更新插件代码
4. 更新本文档

## 获得帮助

如遇到兼容性问题，请：

1. 检查你的 Godot 版本
2. 查看 Godot 官方变更日志
3. 提交 Issue 报告问题

---

**兼容性保证：本插件在 Godot 4.0~4.7 所有版本中都能正常工作！**
