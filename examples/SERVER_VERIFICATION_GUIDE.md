# Google IAP 服务端验单指南

## 概述

本指南说明如何配置和使用 Google IAP 插件的服务端验单功能，以防止玩家作弊。

## 核心功能

- ✅ 支付成功后自动调用服务端验证
- ✅ JSON 格式参数传递（sku + token）
- ✅ 可选开关控制是否需要验单
- ✅ 完整的成功/失败回调
- ✅ 详细的日志记录

## 工作流程

```
1. 玩家购买商品
2. Google Play 支付成功
3. 插件收到 purchase_success 信号
4. 检查是否需要服务端验单（require_server_verification）
5. 如需要，发送 HTTP POST 请求到服务端
6. 服务端验证购买凭证
7. 服务端返回验证结果
8. 验单成功后发放道具
```

## 快速开始

### 1. 配置插件

在游戏初始化时配置服务端验单：

```gdscript
extends Node

func _ready():
    # 启用服务端验单
    GoogleIAP.require_server_verification = true
    
    # 设置服务端验证 URL
    GoogleIAP.server_verification_url = "https://your-server.com/api/verify-purchase"
    
    # 设置请求超时时间（秒）
    GoogleIAP.server_request_timeout = 10.0
    
    # 连接验单信号
    GoogleIAP.server_verify_success.connect(_on_server_verify_success)
    GoogleIAP.server_verify_failed.connect(_on_server_verify_failed)
    
    # 初始化插件
    GoogleIAP.initialize()

func _on_server_verify_success(product_id: String, purchase_token: String, order_id: String, response: Dictionary):
    print("验单成功:", product_id)
    print("服务端响应:", response)

func _on_server_verify_failed(product_id: String, error_code: int, error_message: String):
    print("验单失败:", product_id, error_code, error_message)
    # 可以在这里显示错误提示给玩家
```

### 2. 服务端接口规范

#### 请求格式

**方法**: POST  
**Content-Type**: application/json

**请求体**:
```json
{
  "sku": "com.yourgame.coins.100",
  "token": "purchase_token_from_google_play",
  "order_id": "GPA.1234-5678-9012-34567",
  "timestamp": 1699999999999
}
```

**字段说明**:
- `sku`: 商品 ID（Product ID）
- `token`: Google Play 购买凭证（Purchase Token）
- `order_id`: 订单 ID
- `timestamp`: 请求时间戳（毫秒）

#### 响应格式

**成功响应** (HTTP 200):
```json
{
  "verified": true,
  "message": "验证成功",
  "product_id": "com.yourgame.coins.100",
  "purchase_time": 1699999999999,
  "purchase_state": 0
}
```

**失败响应** (HTTP 200):
```json
{
  "verified": false,
  "message": "购买凭证无效"
}
```

**字段说明**:
- `verified`: 必填，布尔值，是否验证成功
- `message`: 可选，提示信息
- 其他字段可根据需要添加

## 服务端实现示例

### Node.js (Express)

```javascript
const express = require('express');
const { google } = require('googleapis');
const app = express();

app.use(express.json());

// 配置 Google Play Developer API
const auth = new google.auth.GoogleAuth({
  keyFile: 'your-service-account-key.json',
  scopes: ['https://www.googleapis.com/auth/androidpublisher']
});

const androidPublisher = google.androidpublisher('v3');

app.post('/api/verify-purchase', async (req, res) => {
  try {
    const { sku, token, order_id } = req.body;
    const packageName = 'com.your.game.package';
    
    console.log('验证购买:', sku, order_id);
    
    const authClient = await auth.getClient();
    
    // 验证一次性购买商品
    const result = await androidPublisher.purchases.products.get({
      auth: authClient,
      packageName: packageName,
      productId: sku,
      token: token
    });
    
    const purchase = result.data;
    
    // 检查购买状态
    if (purchase.purchaseState === 0) {
      // 购买成功
      res.json({
        verified: true,
        message: '验证成功',
        product_id: sku,
        purchase_time: purchase.purchaseTimeMillis,
        purchase_state: purchase.purchaseState
      });
    } else {
      // 购买无效
      res.json({
        verified: false,
        message: '购买状态无效'
      });
    }
  } catch (error) {
    console.error('验单失败:', error);
    res.status(500).json({
      verified: false,
      message: '服务器错误: ' + error.message
    });
  }
});

app.listen(3000, () => {
  console.log('服务端运行在端口 3000');
});
```

### Python (Flask)

```python
from flask import Flask, request, jsonify
from google.oauth2 import service_account
from googleapiclient.discovery import build
import json

app = Flask(__name__)

# 配置 Google Play Developer API
SERVICE_ACCOUNT_FILE = 'your-service-account-key.json'
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']
PACKAGE_NAME = 'com.your.game.package'

credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES)
android_publisher = build('androidpublisher', 'v3', credentials=credentials)

@app.route('/api/verify-purchase', methods=['POST'])
def verify_purchase():
    try:
        data = request.get_json()
        sku = data.get('sku')
        token = data.get('token')
        
        print(f'验证购买: {sku}')
        
        # 验证一次性购买商品
        result = android_publisher.purchases().products().get(
            packageName=PACKAGE_NAME,
            productId=sku,
            token=token
        ).execute()
        
        # 检查购买状态
        if result.get('purchaseState') == 0:
            return jsonify({
                'verified': True,
                'message': '验证成功',
                'product_id': sku,
                'purchase_time': result.get('purchaseTimeMillis'),
                'purchase_state': result.get('purchaseState')
            })
        else:
            return jsonify({
                'verified': False,
                'message': '购买状态无效'
            })
            
    except Exception as e:
        print(f'验单失败: {e}')
        return jsonify({
            'verified': False,
            'message': f'服务器错误: {str(e)}'
        }), 500

if __name__ == '__main__':
    app.run(port=3000)
```

### PHP (Laravel)

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Google\Client;
use Google\Service\AndroidPublisher;

Route::post('/api/verify-purchase', function (Request $request) {
    try {
        $sku = $request->input('sku');
        $token = $request->input('token');
        $packageName = 'com.your.game.package';
        
        \Log::info('验证购买:', ['sku' => $sku]);
        
        // 配置 Google API 客户端
        $client = new Client();
        $client->setAuthConfig(storage_path('app/service-account-key.json'));
        $client->addScope(AndroidPublisher::ANDROIDPUBLISHER);
        
        $service = new AndroidPublisher($client);
        
        // 验证一次性购买商品
        $purchase = $service->purchases_products->get(
            $packageName,
            $sku,
            $token
        );
        
        // 检查购买状态
        if ($purchase->getPurchaseState() == 0) {
            return response()->json([
                'verified' => true,
                'message' => '验证成功',
                'product_id' => $sku,
                'purchase_time' => $purchase->getPurchaseTimeMillis(),
                'purchase_state' => $purchase->getPurchaseState()
            ]);
        } else {
            return response()->json([
                'verified' => false,
                'message' => '购买状态无效'
            ]);
        }
    } catch (\Exception $e) {
        \Log::error('验单失败:', ['error' => $e->getMessage()]);
        return response()->json([
            'verified' => false,
            'message' => '服务器错误: ' . $e->getMessage()
        ], 500);
    }
});
```

## 订阅商品验证

对于订阅商品，验证方式略有不同：

### Node.js 订阅验证

```javascript
// 验证订阅商品
const result = await androidPublisher.purchases.subscriptions.get({
  auth: authClient,
  packageName: packageName,
  subscriptionId: sku,
  token: token
});

const subscription = result.data;

if (subscription.paymentState === 1) {
  // 订阅有效
}
```

### Python 订阅验证

```python
# 验证订阅商品
result = android_publisher.purchases().subscriptions().get(
    packageName=PACKAGE_NAME,
    subscriptionId=sku,
    token=token
).execute()
```

## 配置 Google Play Console

### 1. 创建服务账号

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建或选择项目
3. 启用 "Google Play Android Developer API"
4. 创建服务账号密钥（JSON格式）
5. 下载密钥文件

### 2. 授权服务账号

1. 访问 [Google Play Console](https://play.google.com/console/)
2. 进入 "用户和权限" → "邀请新用户"
3. 输入服务账号邮箱
4. 授予 "查看财务数据" 和 "管理订单和订阅" 权限

## 安全建议

1. **HTTPS**: 确保服务端使用 HTTPS
2. **API 密钥**: 考虑添加 API 密钥验证
3. **IP 白名单**: 限制可访问服务端的 IP
4. **请求频率**: 防止恶意请求
5. **日志记录**: 记录所有验证请求
6. **重复验证**: 防止同一 token 多次验证

## 完整的游戏调用示例

```gdscript
extends Node

func _ready():
    # 配置服务端验单
    GoogleIAP.require_server_verification = true
    GoogleIAP.server_verification_url = "https://your-server.com/api/verify-purchase"
    GoogleIAP.server_request_timeout = 15.0
    
    # 连接所有信号
    GoogleIAP.purchase_success.connect(_on_purchase_success)
    GoogleIAP.purchase_failed.connect(_on_purchase_failed)
    GoogleIAP.item_granted.connect(_on_item_granted)
    GoogleIAP.item_grant_failed.connect(_on_item_grant_failed)
    GoogleIAP.server_verify_success.connect(_on_server_verify_success)
    GoogleIAP.server_verify_failed.connect(_on_server_verify_failed)
    
    # 初始化
    GoogleIAP.initialize()

func buy_coins():
    GoogleIAP.purchase_product("com.yourgame.coins.100")

func _on_purchase_success(product_id: String, token: String, order_id: String):
    print("支付成功，等待验单...")
    # 显示"处理中..."提示
    show_processing_dialog()

func _on_purchase_failed(error_code: int, error_message: String):
    hide_processing_dialog()
    show_error_dialog("支付失败: " + error_message)

func _on_server_verify_success(product_id: String, token: String, order_id: String, response: Dictionary):
    print("验单成功，道具将自动发放")

func _on_server_verify_failed(product_id: String, error_code: int, error_message: String):
    hide_processing_dialog()
    show_error_dialog("验单失败: " + error_message)

func _on_item_granted(product_id: String, item_data: Dictionary):
    hide_processing_dialog()
    var item_name = item_data.get("item_name", "道具")
    show_reward_dialog("恭喜获得: " + item_name)

func _on_item_grant_failed(product_id: String, error_message: String):
    hide_processing_dialog()
    show_error_dialog("道具发放失败: " + error_message)
```

## 测试

### 1. 不使用服务端验单（开发测试）

```gdscript
GoogleIAP.require_server_verification = false
```

### 2. 模拟服务端响应

使用工具如 Postman 或 curl 测试服务端接口：

```bash
curl -X POST https://your-server.com/api/verify-purchase \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "com.yourgame.coins.100",
    "token": "test_token",
    "order_id": "GPA.1234-5678-9012-34567",
    "timestamp": 1699999999999
  }'
```

## 常见问题

### Q: 如何禁用服务端验单？

A: 设置 `GoogleIAP.require_server_verification = false`

### Q: 验单超时怎么办？

A: 调整 `GoogleIAP.server_request_timeout` 的值（默认10秒）

### Q: 如何处理验单失败？

A: 监听 `server_verify_failed` 信号，显示错误提示给玩家

### Q: 服务端需要验证什么？

A: 至少验证：
1. purchaseState 是否为 0（已购买）
2. 订单是否已验证过（防止重复验证）
3. 商品ID是否匹配

## 参考文档

- [Google Play Billing Library 文档](https://developer.android.com/google/play/billing)
- [Google Play Android Developer API](https://developers.google.com/android-publisher)
- [服务端验证购买](https://developer.android.com/google/play/billing/security#verify)
