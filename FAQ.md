# Google IAP 商用终极版 - 常见问题FAQ

## 目录
1. [支付白屏排查](#支付白屏排查)
2. [验单失败处理](#验单失败处理)
3. [Godot打包配置](#godot打包配置)
4. [华为/小米渠道适配](#华为小米渠道适配)
5. [其他常见问题](#其他常见问题)

---

## 支付白屏排查

### 问题现象
点击购买按钮后，Google Play支付页面不显示，或显示空白/加载中。

### 排查步骤

#### 1. 检查Google Play服务
```
确认设备已安装并启用Google Play服务
- Android 9及以下：设置 → 应用 → Google Play服务
- Android 10及以上：设置 → 应用 → 查看全部应用 → Google Play服务
```

#### 2. 检查网络连接
```
- 确保设备可访问Google服务
- 尝试使用VPN或切换网络环境
- 验证网络防火墙设置
```

#### 3. 检查应用签名
```
重要：Google IAP要求应用签名必须与Google Play Console中配置的一致

检查步骤：
1. 确认使用的是Release签名而非Debug签名
2. 确认签名文件（keystore）正确
3. 在Godot导出设置中配置正确的签名：
   - 项目 → 导出 → Android → 签名
   - 勾选"使用自定义发布构建"
   - 配置Keystore路径、密码、别名
```

#### 4. 检查Google Play Console配置
```
1. 确认应用已在Google Play Console中创建
2. 确认应用已发布到内部测试/封闭测试轨道
3. 确认商品已创建并激活
4. 确认测试账号已添加到许可测试列表

许可测试配置：
Google Play Console → 设置 → 许可测试
添加测试者的Google账号邮箱
```

#### 5. 检查应用版本号
```
确保：
- Google Play Console中的应用版本号 ≥ 本地打包的版本号
- 版本名称格式一致（如1.0.0）
```

#### 6. 查看日志
```
在Godot中启用日志：
GoogleIAP.log_level = GoogleIAP.LogLevel.DEBUG
GoogleIAP.enable_logging = true

查看Android日志：
adb logcat -s Godot:I *:E
```

---

## 验单失败处理

### 问题现象
支付成功，但服务端验单失败，道具未发放。

### 排查步骤

#### 1. 检查服务端URL配置
```gdscript
// 确保服务端URL正确配置
GoogleIAP.server_verification_url = "https://your-server.com/api/verify-purchase"
```

#### 2. 检查网络连接
```
- 确认服务端可访问
- 检查HTTPS证书是否有效
- 确认没有防火墙/CDN拦截
```

#### 3. 使用降级模式（推荐）
```gdscript
// 启用降级模式：验单失败时先发放道具
GoogleIAP.fallback_on_verify_failed = true

// 网络恢复后自动重试待验单
GoogleIAP.retry_pending_verifications()
```

#### 4. 服务端验单接口规范
```
请求格式（POST）：
{
  "sku": "com.yourgame.coins.100",
  "token": "purchase_token_here",
  "order_id": "GPA.1234-5678-9012-34567",
  "timestamp": 1234567890123
}

响应格式：
{
  "verified": true,
  "message": "验单成功",
  "data": { /* 可选的额外数据 */ }
}
```

#### 5. 服务端实现示例（Node.js）
```javascript
const express = require('express');
const { google } = require('googleapis');
const app = express();

app.use(express.json());

const androidpublisher = google.androidpublisher('v3');
const auth = new google.auth.GoogleAuth({
  keyFile: 'service-account.json',
  scopes: ['https://www.googleapis.com/auth/androidpublisher']
});

app.post('/api/verify-purchase', async (req, res) => {
  try {
    const { sku, token, order_id } = req.body;
    const authClient = await auth.getClient();
    
    const result = await androidpublisher.purchases.products.get({
      auth: authClient,
      packageName: 'com.your.game',
      productId: sku,
      token: token
    });
    
    if (result.data.purchaseState === 0) {
      res.json({ verified: true, message: '验单成功' });
    } else {
      res.json({ verified: false, message: '订单无效' });
    }
  } catch (error) {
    console.error('验单失败:', error);
    res.status(500).json({ verified: false, message: '验单服务异常' });
  }
});

app.listen(3000);
```

---

## Godot打包配置

### Android导出完整配置

#### 1. 基本设置
```
项目 → 导出 → Android
- 名称：你的应用名称
- 唯一名称：com.yourcompany.yourgame
- 版本：1.0.0
- 版本代码：1
```

#### 2. 架构配置
```
架构（Architectures）：
- 勾选：arm64-v8a（推荐）
- 可选：armeabi-v7a（兼容旧设备）
- 可选：x86_64（模拟器）
```

#### 3. 签署配置
```
勾选：使用自定义发布构建
- Release：
  - Keystore：选择你的.keystore文件
  - Keystore用户：输入密钥别名
  - Keystore密码：输入密钥库密码
  - 密钥密码：输入密钥密码
```

#### 4. 权限配置
```
在android/build/AndroidManifest.xml中添加：

<!-- 网络权限（必需） -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 计费权限（必需） -->
<uses-permission android:name="com.android.vending.BILLING" />
```

#### 5. Gradle配置
```
在android/build/build.gradle中添加：

dependencies {
    // Google Play Billing Library
    implementation 'com.android.billingclient:billing:6.2.1'
    implementation 'com.android.billingclient:billing-ktx:6.2.1'
}
```

#### 6. 启动场景配置
```
确保主场景已设置：
项目 → 项目设置 → 应用 → 运行
- 主场景：选择你的Main.tscn
```

#### 7. 自动加载配置
```
项目 → 项目设置 → 自动加载
- 添加PlayerData（单例）
- 添加GoogleIAP（如果需要全局访问）
```

---

## 华为/小米渠道适配

### 华为应用市场（AppGallery）

#### 1. 创建华为开发者账号
```
https://developer.huawei.com/consumer/cn/
注册并完成实名认证
```

#### 2. 创建应用和配置商品
```
1. 登录AppGallery Connect
2. 创建应用，填写应用信息
3. 配置应用签名（SHA256指纹）
4. 在"运营" → "产品" → "应用内商品"中创建商品
```

#### 3. 集成华为IAP SDK
```
推荐使用现成的Godot华为IAP插件：
- Godot Asset Library搜索"Huawei IAP"
- 或GitHub搜索"godot huawei iap"
```

#### 4. 代码适配示例
```gdscript
# 检测设备厂商
func get_device_manufacturer() -> String:
    return OS.get_system_property("ro.product.manufacturer").to_lower()

# 选择IAP服务
func get_iap_service() -> String:
    var manufacturer = get_device_manufacturer()
    if manufacturer == "huawei" or manufacturer == "honor":
        return "huawei"
    return "google"

# 购买商品
func purchase_product(product_id: String) -> void:
    var service = get_iap_service()
    match service:
        "huawei":
            HuaweiIAP.purchase_product(product_id)
        "google":
            GoogleIAP.purchase_product(product_id)
```

### 小米应用商店

#### 1. 创建小米开发者账号
```
https://dev.mi.com/distribute
注册并完成实名认证
```

#### 2. 创建应用和配置商品
```
1. 登录小米开放平台
2. 创建应用，填写应用信息
3. 配置应用签名
4. 在"应用内购买"中创建商品
```

#### 3. 集成小米IAP SDK
```
推荐使用现成的Godot小米IAP插件：
- Godot Asset Library搜索"Xiaomi IAP"
- 或GitHub搜索"godot xiaomi iap"
```

---

## 其他常见问题

### Q: 如何测试支付功能？
```
A: 使用Google Play的许可测试功能
1. 在Google Play Console添加测试账号
2. 使用测试账号登录设备
3. 测试支付不会真实扣款
```

### Q: 商品查询失败怎么办？
```
A: 
1. 检查网络连接
2. 确认商品ID正确
3. 确认商品已在Google Play Console激活
4. 插件会自动重试3次，查看日志确认
```

### Q: 如何保存购买记录？
```
A: 
1. 使用PlayerData类保存本地记录
2. 服务端验单成功后保存到服务器
3. 使用restore_purchases()恢复购买
```

### Q: 支持订阅商品吗？
```
A: 支持！
1. ProductType.SUBS 用于订阅商品
2. 订阅商品需要特殊的处理逻辑
3. 建议查看Google Play Billing订阅文档
```

### Q: 如何处理退款？
```
A: 
1. Google Play Console手动处理退款
2. 监听voided purchases API
3. 服务端定期检查并扣除道具
```

### Q: 插件支持哪些Godot版本？
```
A: 支持Godot 4.0~4.7所有版本
- 4.0-4.5：使用File API
- 4.6+：使用FileAccess API
- 插件自动检测并适配
```

---

## 技术支持

如遇到其他问题，请：
1. 查看本文档的其他章节
2. 启用DEBUG日志查看详细信息
3. 检查Google Play官方文档
4. 联系插件作者获取支持

---

## 更新日志

- v6.0.0：商用终极版，添加降级验单、重试逻辑、分级日志
- v5.0.0：添加服务端验单功能
- v4.0.0：添加CSV导出功能
- v3.0.0：添加可视化配置面板
- v2.0.0：全版本兼容适配
- v1.0.0：初始版本
