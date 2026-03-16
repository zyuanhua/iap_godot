# Google IAP 完整示例项目

## 项目简介

这是一个可直接运行的Godot示例项目，展示如何使用Google IAP商用终极版插件。

## 项目结构

```
example_project/
├── project.godot          # Godot项目配置
├── Main.tscn              # 主场景
├── icon.svg               # 项目图标
├── README.md              # 本文件
├── addons/                # 插件目录（需要复制）
│   └── google_iap/        # Google IAP插件
├── scripts/               # 脚本目录
│   ├── Main.gd            # 主场景脚本
│   └── PlayerData.gd      # 玩家数据管理
└── autoload/              # 自动加载脚本
    └── Global.gd          # 全局脚本
```

## 快速开始

### 1. 复制插件

将主项目的`addons/google_iap`文件夹复制到本项目的`addons/`目录下。

### 2. 打开项目

使用Godot 4.0~4.7打开本项目。

### 3. 启用插件

1. 进入：项目 → 项目设置 → 插件
2. 找到"Google IAP Ultimate"
3. 勾选启用

### 4. 配置自动加载

1. 进入：项目 → 项目设置 → 自动加载
2. 添加：
   - 名称：`PlayerData`
   - 路径：`res://scripts/PlayerData.gd`

### 5. 运行项目

点击Godot编辑器右上角的"运行项目"按钮即可。

## 功能演示

### 主界面

项目包含以下功能按钮：

- **购买100金币** - 测试一次性购买商品
- **购买500金币** - 测试大额金币购买
- **购买30天VIP** - 测试VIP订阅（示例中作为一次性购买）
- **购买1年VIP** - 测试长期VIP
- **购买永久无广告** - 测试永久商品
- **购买传说之剑** - 测试道具商品
- **重置玩家数据** - 清空所有数据重新测试

### 玩家数据

玩家数据会自动保存到本地：

- 金币数量
- VIP天数
- 无广告状态
- 拥有的道具列表

### 支付流程

1. 点击购买按钮
2. 触发Google Play支付（模拟器中为模拟）
3. 支付成功后自动发放道具
4. 显示成功提示弹窗
5. 更新玩家数据显示

## 代码说明

### Main.gd

主场景脚本，包含：
- UI元素引用
- 商品常量定义
- 按钮点击处理
- Google IAP信号连接
- 道具发放逻辑

### PlayerData.gd

玩家数据管理单例，包含：
- 数据持久化
- 金币管理
- VIP管理
- 广告管理
- 道具管理

## 自定义配置

### 修改商品

在`Main.gd`的`_setup_product_mapping()`函数中修改：

```gdscript
GoogleIAP.product_item_mapping = {
    "your.product.id": {
        "item_type": "coins",
        "item_amount": 100,
        "item_name": "100金币"
    }
}
```

### 启用服务端验单

```gdscript
GoogleIAP.require_server_verification = true
GoogleIAP.server_verification_url = "https://your-server.com/api/verify"
```

### 配置日志

```gdscript
GoogleIAP.log_level = GoogleIAP.LogLevel.DEBUG
GoogleIAP.enable_logging = true
```

## 导出到Android

### 1. 配置导出

1. 项目 → 导出 → 添加… → Android
2. 填写应用信息：
   - 唯一名称：com.yourcompany.yourgame
   - 版本：1.0.0
   - 版本代码：1

### 2. 配置签名

1. 勾选"使用自定义发布构建"
2. 配置Keystore信息
3. 使用Release签名

### 3. 添加权限

确保`AndroidManifest.xml`包含：
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="com.android.vending.BILLING" />
```

### 4. 导出APK

点击"导出项目"生成APK文件。

## 测试说明

### 模拟器测试

在非Android平台运行时，插件使用模拟模式：
- 购买自动成功
- 道具自动发放
- 可用于测试UI和逻辑

### 真机测试

1. 将APK安装到Android设备
2. 使用Google Play测试账号登录
3. 测试真实支付流程

## 常见问题

### Q: 插件没有显示？
A: 确保已将插件复制到`addons/`目录并在项目设置中启用。

### Q: 自动加载报错？
A: 检查自动加载配置中的路径是否正确。

### Q: 如何添加更多商品？
A: 修改`Main.gd`中的商品映射和UI按钮。

## 更多帮助

- 查看项目根目录的`FAQ.md`了解更多常见问题
- 查看`README.md`了解插件完整功能
- 查看`examples/`目录下的其他示例

## 技术支持

如遇问题，请：
1. 查看日志输出
2. 检查FAQ文档
3. 确认Godot版本兼容（4.0~4.7）

---

**祝你使用愉快！** 🎮
