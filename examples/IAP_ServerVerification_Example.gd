extends Node
class_name IAPServerVerificationExample

# ========================================
# Google IAP 服务端验单完整示例
# ========================================
# 展示如何配置和使用服务端验单功能
# ========================================

# 玩家数据
var player_data = {
	"coins": 0,
	"vip_days": 0,
	"vip_expire_time": 0,
	"no_ads": false,
	"inventory": {}
}

# GoogleIAP 实例
var google_iap: GoogleIAP

# ========================================
# 初始化
# ========================================
func _ready() -> void:
	print("[示例] 服务端验单示例初始化")
	
	# 创建 GoogleIAP 实例
	google_iap = GoogleIAP.new()
	add_child(google_iap)
	
	# ========================================
	# 第 1 步：配置服务端验单
	# ========================================
	_configure_server_verification()
	
	# ========================================
	# 第 2 步：连接信号
	# ========================================
	_connect_signals()
	
	# ========================================
	# 第 3 步：初始化插件
	# ========================================
	google_iap.initialize()
	
	print("[示例] 初始化完成")

# ========================================
# 配置服务端验单
# ========================================
func _configure_server_verification() -> void:
	print("[示例] 配置服务端验单")
	
	# 启用服务端验单（关键！设置为 true 才会进行验单）
	google_iap.require_server_verification = true
	
	# 设置服务端验证 URL（替换为你的实际地址）
	google_iap.server_verification_url = "https://your-server.com/api/verify-purchase"
	
	# 设置请求超时时间（秒）
	google_iap.server_request_timeout = 15.0
	
	# 启用自动发放道具（验单成功后自动发放）
	google_iap.auto_grant_items = true
	
	print("[示例] 服务端验单配置完成")
	print("  require_server_verification: ", google_iap.require_server_verification)
	print("  server_verification_url: ", google_iap.server_verification_url)
	print("  server_request_timeout: ", google_iap.server_request_timeout)

# ========================================
# 连接信号
# ========================================
func _connect_signals() -> void:
	print("[示例] 连接信号")
	
	# 购买相关信号
	google_iap.purchase_success.connect(_on_purchase_success)
	google_iap.purchase_failed.connect(_on_purchase_failed)
	google_iap.purchase_pending.connect(_on_purchase_pending)
	google_iap.purchase_cancelled.connect(_on_purchase_cancelled)
	
	# 服务端验单相关信号（新增）
	google_iap.server_verify_success.connect(_on_server_verify_success)
	google_iap.server_verify_failed.connect(_on_server_verify_failed)
	
	# 道具发放相关信号
	google_iap.item_granted.connect(_on_item_granted)
	google_iap.item_grant_failed.connect(_on_item_grant_failed)
	
	# 其他信号
	google_iap.products_loaded.connect(_on_products_loaded)
	google_iap.billing_connected.connect(_on_billing_connected)

# ========================================
# 购买商品函数
# ========================================
func buy_coins_100() -> void:
	print("[示例] 点击购买 100 金币")
	google_iap.purchase_product("com.yourgame.coins.100")

func buy_vip_month() -> void:
	print("[示例] 点击购买月度 VIP")
	google_iap.purchase_product("com.yourgame.vip_month", google_iap.ProductType.SUBS)

func buy_no_ads() -> void:
	print("[示例] 点击购买去广告")
	google_iap.purchase_product("com.yourgame.no_ads")

# ========================================
# 购买相关回调
# ========================================
func _on_purchase_success(product_id: String, purchase_token: String, order_id: String) -> void:
	print("[示例] ========================================")
	print("[示例] 支付成功！")
	print("[示例] 商品ID: ", product_id)
	print("[示例] 订单ID: ", order_id)
	print("[示例] ========================================")
	
	# 显示"处理中..."提示
	_show_processing_dialog("正在验证订单，请稍候...")
	
	# 注意：如果启用了require_server_verification，
	# 这里不会立即发放道具，会先进行服务端验单

func _on_purchase_failed(error_code: int, error_message: String) -> void:
	print("[示例] 支付失败: ", error_code, " - ", error_message)
	
	_hide_processing_dialog()
	_show_error_dialog("支付失败: " + error_message)

func _on_purchase_pending(product_id: String) -> void:
	print("[示例] 购买待处理，需要在Play Store中完成")
	_show_info_dialog("支付处理中，请在Google Play中完成支付")

func _on_purchase_cancelled() -> void:
	print("[示例] 购买已取消")
	_hide_processing_dialog()

# ========================================
# 服务端验单回调（新增）
# ========================================
func _on_server_verify_success(product_id: String, purchase_token: String, order_id: String, response: Dictionary) -> void:
	print("[示例] ========================================")
	print("[示例] 服务端验单成功！")
	print("[示例] 商品ID: ", product_id)
	print("[示例] 服务端响应: ", response)
	print("[示例] ========================================")
	
	# 验单成功后，道具会自动发放（如果auto_grant_items为true）
	# 这里可以更新UI状态
	_update_ui_status("验单成功，正在发放道具...")

func _on_server_verify_failed(product_id: String, error_code: int, error_message: String) -> void:
	print("[示例] ========================================")
	print("[示例] 服务端验单失败！")
	print("[示例] 商品ID: ", product_id)
	print("[示例] 错误码: ", error_code)
	print("[示例] 错误信息: ", error_message)
	print("[示例] ========================================")
	
	_hide_processing_dialog()
	
	# 根据错误类型显示不同提示
	match error_code:
		-1:
			_show_error_dialog("验单失败：响应格式不正确")
		-2:
			_show_error_dialog("验单失败：" + error_message)
		408:
			_show_error_dialog("验单超时，请检查网络连接")
		500:
			_show_error_dialog("服务器错误，请稍后重试")
		_:
			_show_error_dialog("验单失败：" + error_message)

# ========================================
# 道具发放回调
# ========================================
func _on_item_granted(product_id: String, item_data: Dictionary) -> void:
	print("[示例] ========================================")
	print("[示例] 道具发放成功！")
	print("[示例] 商品ID: ", product_id)
	print("[示例] 道具数据: ", item_data)
	print("[示例] ========================================")
	
	_hide_processing_dialog()
	
	var item_name = item_data.get("item_name", "道具")
	var item_type = item_data.get("item_type", "")
	var item_amount = item_data.get("item_amount", 0)
	
	# 更新玩家数据（实际项目中替换为你的逻辑）
	match item_type:
		"coins":
			player_data["coins"] += item_amount
			print("[示例] 玩家金币: ", player_data["coins"])
		
		"vip_days":
			var current_time = Time.get_ticks_msec() / 1000
			if player_data["vip_expire_time"] < current_time:
				player_data["vip_expire_time"] = current_time + item_amount * 86400
			else:
				player_data["vip_expire_time"] += item_amount * 86400
			print("[示例] VIP到期时间: ", player_data["vip_expire_time"])
		
		"no_ads":
			player_data["no_ads"] = true
			print("[示例] 无广告状态: ", player_data["no_ads"])
		
		"item":
			var item_id = item_data.get("item_id", "")
			if not player_data["inventory"].has(item_id):
				player_data["inventory"][item_id] = 0
			player_data["inventory"][item_id] += item_amount
			print("[示例] 背包: ", player_data["inventory"])
	
	# 显示奖励弹窗
	_show_reward_dialog(item_name)

func _on_item_grant_failed(product_id: String, error_message: String) -> void:
	print("[示例] 道具发放失败: ", product_id, " - ", error_message)
	
	_hide_processing_dialog()
	_show_error_dialog("道具发放失败: " + error_message)

# ========================================
# 其他信号回调
# ========================================
func _on_products_loaded(products: Array) -> void:
	print("[示例] 商品加载成功: ", products.size(), " 个商品")

func _on_billing_connected() -> void:
	print("[示例] Billing服务已连接")

# ========================================
# UI相关函数（示例）
# ========================================
func _show_processing_dialog(message: String) -> void:
	print("[示例] [UI] 显示处理中弹窗: ", message)
	# 实际项目中创建并显示Dialog
	# var dialog = ProcessingDialog.new()
	# dialog.message = message
	# get_tree().root.add_child(dialog)

func _hide_processing_dialog() -> void:
	print("[示例] [UI] 隐藏处理中弹窗")
	# 实际项目中查找并关闭Dialog

func _show_error_dialog(message: String) -> void:
	print("[示例] [UI] 显示错误弹窗: ", message)
	# 实际项目中创建并显示ErrorDialog

func _show_info_dialog(message: String) -> void:
	print("[示例] [UI] 显示信息弹窗: ", message)
	# 实际项目中创建并显示InfoDialog

func _show_reward_dialog(item_name: String) -> void:
	print("[示例] [UI] 显示奖励弹窗: 获得", item_name)
	# 实际项目中创建并显示RewardDialog

func _update_ui_status(message: String) -> void:
	print("[示例] [UI] 更新状态: ", message)
	# 实际项目中更新UI状态显示

# ========================================
# 开发测试：禁用服务端验单
# ========================================
func disable_server_verification_for_testing() -> void:
	print("[示例] 禁用服务端验单（用于开发测试）")
	google_iap.require_server_verification = false
	print("[示例] require_server_verification: ", google_iap.require_server_verification)

# ========================================
# 开发测试：启用服务端验单
# ========================================
func enable_server_verification() -> void:
	print("[示例] 启用服务端验单")
	google_iap.require_server_verification = true
	print("[示例] require_server_verification: ", google_iap.require_server_verification)

# ========================================
# 手动触发验单（测试用）
# ========================================
func test_verify_purchase() -> void:
	print("[示例] 手动测试验单")
	google_iap.verify_purchase_on_server(
		"com.yourgame.coins.100",
		"test_purchase_token_123",
		"GPA.1234-5678-9012-34567"
	)
