extends Node

# ========================================
# Google IAP 商用功能示例
# 展示如何使用所有新增的商用功能
# ========================================

# GoogleIAP 实例
var google_iap: GoogleIAP

# 连接 GoogleIAP 插件的 UI 提示信号
func _ready() -> void:
	# 创建 GoogleIAP 实例
	google_iap = GoogleIAP.new()
	add_child(google_iap)
	
	# 连接 UI 提示信号
	google_iap.show_ui_message.connect(_on_show_ui_message)
	google_iap.show_retry_dialog.connect(_on_show_retry_dialog)
	
	# 设置日志级别为 DEBUG（开发阶段）
	google_iap.log_level = google_iap.LogLevel.DEBUG
	google_iap.enable_logging = true
	
	# 配置重试参数
	google_iap.max_query_retry_count = 3
	google_iap.query_retry_interval = 2.0
	google_iap.fallback_on_verify_failed = true
	
	# 初始化插件
	google_iap.initialize()
	
	# 检查是否有待补验单的订单
	google_iap.retry_pending_verifications()

# 处理UI提示信号
func _on_show_ui_message(message: String, message_type: int) -> void:
	match message_type:
		0: # info
			print("[INFO] ", message)
			# 这里可以显示你的游戏的信息弹窗
		1: # warning
			print("[WARNING] ", message)
			# 这里可以显示你的游戏的警告弹窗
		2: # error
			print("[ERROR] ", message)
			# 这里可以显示你的游戏的错误弹窗

# 处理重试对话框
func _on_show_retry_dialog(message: String, retry_callback: Callable) -> void:
	print("[RETRY] ", message)
	# 这里可以显示你的游戏的重试对话框
	# 用户点击重试后调用 retry_callback.call()

# 示例：查询商品（带重试功能）
func query_products_with_retry() -> void:
	var product_ids = [
		"com.yourgame.coins.100",
		"com.yourgame.vip_month"
	]
	google_iap.query_products(product_ids, google_iap.ProductType.IN_APP)

# 示例：购买商品
func purchase_product_example(product_id: String) -> void:
	google_iap.purchase_product(product_id, google_iap.ProductType.IN_APP)

# 示例：手动重试验单
func retry_verifications_manually() -> void:
	google_iap.retry_pending_verifications()
