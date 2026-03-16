extends Control

# ==================== UI元素引用 ====================
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var coins_label: Label = $VBoxContainer/CoinsLabel
@onready var product_list: VBoxContainer = $VBoxContainer/ProductScrollContainer/ProductList
@onready var load_products_button: Button = $VBoxContainer/ButtonContainer/LoadProductsButton
@onready var restore_purchases_button: Button = $VBoxContainer/ButtonContainer/RestorePurchasesButton

# ==================== 游戏变量 ====================
var coins: int = 0
var loaded_products: Array = []
var owned_purchases: Array = []

# GoogleIAP 实例
var google_iap: GoogleIAP

# ==================== 初始化 ====================
func _ready() -> void:
	print("[IAPGameExample] 游戏示例初始化")
	
	# 创建 GoogleIAP 实例
	google_iap = GoogleIAP.new()
	add_child(google_iap)
	
	# 更新金币显示
	_update_coins_display()
	
	# 连接 IAP 信号
	_connect_iap_signals()
	
	# 初始化 IAP
	google_iap.initialize()
	
	# 更新状态
	_update_status("等待初始化...")

# ==================== 信号连接 ====================
func _connect_iap_signals() -> void:
	# 商品查询信号
	google_iap.products_loaded.connect(_on_products_loaded)
	google_iap.products_load_failed.connect(_on_products_load_failed)
	
	# 购买信号
	google_iap.purchase_success.connect(_on_purchase_success)
	google_iap.purchase_failed.connect(_on_purchase_failed)
	google_iap.purchase_pending.connect(_on_purchase_pending)
	google_iap.purchase_cancelled.connect(_on_purchase_cancelled)
	
	# 恢复购买信号
	google_iap.purchases_restored.connect(_on_purchases_restored)
	google_iap.purchases_restore_failed.connect(_on_purchases_restore_failed)
	
	# 消耗商品信号
	google_iap.consume_success.connect(_on_consume_success)
	google_iap.consume_failed.connect(_on_consume_failed)
	
	# 连接状态信号
	google_iap.billing_connected.connect(_on_billing_connected)
	google_iap.billing_disconnected.connect(_on_billing_disconnected)
	google_iap.billing_connection_failed.connect(_on_billing_connection_failed)
	
	# 按钮信号
	load_products_button.pressed.connect(_on_load_products_button_pressed)
	restore_purchases_button.pressed.connect(_on_restore_purchases_button_pressed)

# ==================== UI 事件处理 ====================
func _on_load_products_button_pressed() -> void:
	_update_status("正在加载商品...")
	load_products_button.disabled = true
	
	# 注意：这里需要使用您在配置面板中配置的商品 ID
	# 这里使用示例商品 ID，实际使用时请替换
	var example_products = [
		"com.yourgame.coins.100",
		"com.yourgame.coins.500",
		"com.yourgame.no_ads",
		"com.yourgame.premium"
	]
	
	# 查询一次性购买商品
	var in_app_products = ["com.yourgame.coins.100", "com.yourgame.coins.500", "com.yourgame.no_ads"]
	google_iap.query_products(in_app_products, google_iap.ProductType.IN_APP)
	
	# 查询订阅商品
	var subs_products = ["com.yourgame.premium"]
	google_iap.query_products(subs_products, google_iap.ProductType.SUBS)

func _on_restore_purchases_button_pressed() -> void:
	_update_status("正在恢复购买...")
	restore_purchases_button.disabled = true
	google_iap.restore_purchases()

func _on_purchase_button_pressed(product_id: String, product_type: int) -> void:
	_update_status("正在购买：" + product_id)
	google_iap.purchase_product(product_id, product_type)

# ==================== GoogleIAP信号回调 ====================
func _on_billing_connected() -> void:
	_update_status("Billing服务已连接")
	load_products_button.disabled = false
	restore_purchases_button.disabled = false

func _on_billing_disconnected() -> void:
	_update_status("Billing服务已断开")
	load_products_button.disabled = true
	restore_purchases_button.disabled = true

func _on_billing_connection_failed(error_code: int, error_message: String) -> void:
	_update_status("Billing连接失败: " + error_message)
	load_products_button.disabled = true
	restore_purchases_button.disabled = true

func _on_products_loaded(products: Array) -> void:
	print("[IAPGameExample] 商品加载成功: ", products)
	
	# 将新加载的商品添加到列表中
	for product in products:
		loaded_products.append(product)
	
	# 更新UI显示
	_update_product_list()
	load_products_button.disabled = false
	_update_status("商品加载完成: " + str(loaded_products.size()) + " 个")

func _on_products_load_failed(error_code: int, error_message: String) -> void:
	print("[IAPGameExample] 商品加载失败: ", error_code, " - ", error_message)
	_update_status("商品加载失败: " + error_message)
	load_products_button.disabled = false

func _on_purchase_success(product_id: String, purchase_token: String, order_id: String) -> void:
	print("[IAPGameExample] 购买成功: ", product_id, " 订单: ", order_id)
	
	# 保存购买信息
	var purchase = {
		"product_id": product_id,
		"purchase_token": purchase_token,
		"order_id": order_id
	}
	owned_purchases.append(purchase)
	
	# 处理购买奖励
	_handle_purchase_reward(product_id, purchase_token)
	
	_update_status("购买成功: " + product_id)

func _on_purchase_failed(error_code: int, error_message: String) -> void:
	print("[IAPGameExample] 购买失败: ", error_code, " - ", error_message)
	_update_status("购买失败: " + error_message)

func _on_purchase_pending(product_id: String) -> void:
	print("[IAPGameExample] 购买待处理: ", product_id)
	_update_status("购买待处理，请在Google Play中完成交易")

func _on_purchase_cancelled() -> void:
	print("[IAPGameExample] 购买已取消")
	_update_status("购买已取消")

func _on_purchases_restored(purchases: Array) -> void:
	print("[IAPGameExample] 恢复购买成功: ", purchases)
	owned_purchases = purchases.duplicate()
	restore_purchases_button.disabled = false
	_update_status("恢复购买完成: " + str(purchases.size()) + " 个商品")
	
	# 处理已恢复的购买
	for purchase in purchases:
		_handle_purchase_reward(purchase["product_id"], purchase["purchase_token"], true)

func _on_purchases_restore_failed(error_code: int, error_message: String) -> void:
	print("[IAPGameExample] 恢复购买失败: ", error_code, " - ", error_message)
	_update_status("恢复购买失败: " + error_message)
	restore_purchases_button.disabled = false

func _on_consume_success(product_id: String, purchase_token: String) -> void:
	print("[IAPGameExample] 消耗成功: ", product_id)
	
	# 从已购买列表中移除
	var index = -1
	for i in range(owned_purchases.size()):
		if owned_purchases[i]["product_id"] == product_id and owned_purchases[i]["purchase_token"] == purchase_token:
			index = i
			break
	
	if index != -1:
		owned_purchases.remove_at(index)
	
	_update_status("消耗成功: " + product_id)

func _on_consume_failed(error_code: int, error_message: String) -> void:
	print("[IAPGameExample] 消耗失败: ", error_code, " - ", error_message)
	_update_status("消耗失败: " + error_message)

# ==================== 游戏逻辑 ====================
func _handle_purchase_reward(product_id: String, purchase_token: String, is_restoring: bool = false) -> void:
	match product_id:
		"com.yourgame.coins.100":
			_add_coins(100)
			if not is_restoring:
				google_iap.consume_product(product_id, purchase_token)
		"com.yourgame.coins.500":
			_add_coins(500)
			if not is_restoring:
				google_iap.consume_product(product_id, purchase_token)
		"com.yourgame.no_ads":
			_remove_ads()
		"com.yourgame.premium":
			_activate_premium()
		_:
			print("[IAPGameExample] 未知商品：", product_id)

func _add_coins(amount: int) -> void:
	coins += amount
	_update_coins_display()
	print("[IAPGameExample] 获得 ", amount, " 金币，总计: ", coins)

func _remove_ads() -> void:
	print("[IAPGameExample] 已移除广告")
	# 这里添加移除广告的逻辑

func _activate_premium() -> void:
	print("[IAPGameExample] 已激活高级版")
	# 这里添加激活高级版的逻辑

# ==================== UI更新 ====================
func _update_status(message: String) -> void:
	print("[IAPGameExample] ", message)
	if status_label:
		status_label.text = "状态: " + message

func _update_coins_display() -> void:
	if coins_label:
		coins_label.text = "金币: " + str(coins)

func _update_product_list() -> void:
	# 清空现有列表
	for child in product_list.get_children():
		child.queue_free()
	
	if loaded_products.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无商品，请点击'加载商品'"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size.y = 60
		product_list.add_child(empty_label)
		return
	
	# 为每个商品创建一个按钮
	for product in loaded_products:
		var product_panel = HBoxContainer.new()
		product_panel.custom_minimum_size.y = 45
		
		var info_label = Label.new()
		var type_str = "一次性购买" if product.get("product_type", "inapp") == "inapp" else "订阅"
		info_label.text = "%s - %s\n%s" % [product.get("title", ""), product.get("price", ""), type_str]
		info_label.size_flags_horizontal = SIZE_EXPAND_FILL
		info_label.custom_minimum_size.x = 300
		
		var purchase_button = Button.new()
		purchase_button.text = "购买"
		purchase_button.custom_minimum_size.x = 80
		
		# 确定商品类型
		var product_type = GoogleIAP.ProductType.IN_APP
		if product.get("product_type", "inapp") == "subs":
			product_type = GoogleIAP.ProductType.SUBS
		
		purchase_button.pressed.connect(_on_purchase_button_pressed.bind(product.get("product_id", ""), product_type))
		
		product_panel.add_child(info_label)
		product_panel.add_child(purchase_button)
		product_list.add_child(product_panel)
