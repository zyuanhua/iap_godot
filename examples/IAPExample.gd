extends Control

# ==================== 商品 ID 配置 ====================
# 请在这里配置您在 Google Play Console 中定义的商品 ID
const CONSUMABLE_PRODUCT_ID: String = "com.yourgame.coins.100"  # 可消耗商品
const NON_CONSUMABLE_PRODUCT_ID: String = "com.yourgame.no_ads" # 非消耗商品
const SUBSCRIPTION_PRODUCT_ID: String = "com.yourgame.premium"   # 订阅商品

# 商品列表
var product_ids: Array = [CONSUMABLE_PRODUCT_ID, NON_CONSUMABLE_PRODUCT_ID, SUBSCRIPTION_PRODUCT_ID]

# 当前加载的商品信息
var loaded_products: Array = []

# 当前已购买的商品
var owned_purchases: Array = []

# GoogleIAP 实例
var google_iap: GoogleIAP

# ==================== UI 元素引用（在编辑器中绑定） ====================
@onready var status_label: Label = $StatusLabel
@onready var product_list: VBoxContainer = $ScrollContainer/ProductList
@onready var owned_list: VBoxContainer = $ScrollContainer/OwnedList
@onready var load_products_button: Button = $LoadProductsButton
@onready var restore_purchases_button: Button = $RestorePurchasesButton

func _ready() -> void:
	print("[IAPExample] 初始化 IAP 示例")
	
	# 创建 GoogleIAP 实例
	google_iap = GoogleIAP.new()
	add_child(google_iap)
	
	# 连接 GoogleIAP 的所有信号
	_connect_iap_signals()
	
	# 初始化 Billing 服务
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

# ==================== UI 事件处理 ====================
func _on_load_products_button_pressed() -> void:
	_update_status("正在加载商品...")
	load_products_button.disabled = true
	
	# 查询所有商品（分别查询一次性购买和订阅商品）
	var in_app_products: Array = [CONSUMABLE_PRODUCT_ID, NON_CONSUMABLE_PRODUCT_ID]
	google_iap.query_products(in_app_products, google_iap.ProductType.IN_APP)
	
	# 查询订阅商品
	var subs_products: Array = [SUBSCRIPTION_PRODUCT_ID]
	google_iap.query_products(subs_products, google_iap.ProductType.SUBS)

func _on_restore_purchases_button_pressed() -> void:
	_update_status("正在恢复购买...")
	restore_purchases_button.disabled = true
	google_iap.restore_purchases()

func _on_purchase_button_pressed(product_id: String) -> void:
	_update_status("正在购买：" + product_id)
	
	# 判断商品类型
	var product_type: GoogleIAP.ProductType = GoogleIAP.ProductType.IN_APP
	if product_id == SUBSCRIPTION_PRODUCT_ID:
		product_type = GoogleIAP.ProductType.SUBS
	
	google_iap.purchase_product(product_id, product_type)

func _on_consume_button_pressed(product_id: String, purchase_token: String) -> void:
	_update_status("正在消耗：" + product_id)
	google_iap.consume_product(product_id, purchase_token)

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
	print("[IAPExample] 商品加载成功: ", products)
	
	# 将新加载的商品添加到列表中
	for product in products:
		loaded_products.append(product)
	
	# 更新UI显示
	_update_product_list()
	load_products_button.disabled = false
	_update_status("商品加载完成")

func _on_products_load_failed(error_code: int, error_message: String) -> void:
	print("[IAPExample] 商品加载失败: ", error_code, " - ", error_message)
	_update_status("商品加载失败: " + error_message)
	load_products_button.disabled = false

func _on_purchase_success(product_id: String, purchase_token: String, order_id: String) -> void:
	print("[IAPExample] 购买成功: ", product_id, " 订单: ", order_id)
	
	# 保存购买信息
	var purchase = {
		"product_id": product_id,
		"purchase_token": purchase_token,
		"order_id": order_id
	}
	owned_purchases.append(purchase)
	
	# 更新UI
	_update_owned_list()
	_update_status("购买成功: " + product_id)
	
	# 如果是可消耗商品，可以自动消耗
	if product_id == CONSUMABLE_PRODUCT_ID:
		# 这里可以选择是否自动消耗，或者让用户手动消耗
		print("[IAPExample] 可消耗商品，建议调用consume_product进行消耗")

func _on_purchase_failed(error_code: int, error_message: String) -> void:
	print("[IAPExample] 购买失败: ", error_code, " - ", error_message)
	_update_status("购买失败: " + error_message)

func _on_purchase_pending(product_id: String) -> void:
	print("[IAPExample] 购买待处理: ", product_id)
	_update_status("购买待处理，请在Google Play中完成交易")

func _on_purchase_cancelled() -> void:
	print("[IAPExample] 购买已取消")
	_update_status("购买已取消")

func _on_purchases_restored(purchases: Array) -> void:
	print("[IAPExample] 恢复购买成功: ", purchases)
	owned_purchases = purchases.duplicate()
	_update_owned_list()
	restore_purchases_button.disabled = false
	_update_status("恢复购买完成: " + str(purchases.size()) + " 个商品")

func _on_purchases_restore_failed(error_code: int, error_message: String) -> void:
	print("[IAPExample] 恢复购买失败: ", error_code, " - ", error_message)
	_update_status("恢复购买失败: " + error_message)
	restore_purchases_button.disabled = false

func _on_consume_success(product_id: String, purchase_token: String) -> void:
	print("[IAPExample] 消耗成功: ", product_id)
	
	# 从已购买列表中移除
	var index = -1
	for i in range(owned_purchases.size()):
		if owned_purchases[i]["product_id"] == product_id and owned_purchases[i]["purchase_token"] == purchase_token:
			index = i
			break
	
	if index != -1:
		owned_purchases.remove_at(index)
	
	_update_owned_list()
	_update_status("消耗成功: " + product_id)
	
	# 这里可以给玩家发放奖励，比如增加金币
	_give_reward(product_id)

func _on_consume_failed(error_code: int, error_message: String) -> void:
	print("[IAPExample] 消耗失败: ", error_code, " - ", error_message)
	_update_status("消耗失败: " + error_message)

# ==================== 辅助方法 ====================
func _update_status(message: String) -> void:
	print("[IAPExample] ", message)
	if status_label:
		status_label.text = message

func _update_product_list() -> void:
	# 清空现有列表
	for child in product_list.get_children():
		child.queue_free()
	
	# 为每个商品创建一个按钮
	for product in loaded_products:
		var product_panel = HBoxContainer.new()
		
		var info_label = Label.new()
		info_label.text = product["title"] + " - " + product["price"]
		info_label.custom_minimum_size.x = 300
		
		var purchase_button = Button.new()
		purchase_button.text = "购买"
		purchase_button.pressed.connect(_on_purchase_button_pressed.bind(product["product_id"]))
		
		product_panel.add_child(info_label)
		product_panel.add_child(purchase_button)
		product_list.add_child(product_panel)

func _update_owned_list() -> void:
	# 清空现有列表
	for child in owned_list.get_children():
		child.queue_free()
	
	if owned_purchases.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无已购买商品"
		owned_list.add_child(empty_label)
		return
	
	# 为每个已购买商品创建显示项
	for purchase in owned_purchases:
		var purchase_panel = HBoxContainer.new()
		
		var info_label = Label.new()
		info_label.text = purchase["product_id"]
		info_label.custom_minimum_size.x = 300
		
		# 只有可消耗商品才显示消耗按钮
		if purchase["product_id"] == CONSUMABLE_PRODUCT_ID:
			var consume_button = Button.new()
			consume_button.text = "消耗"
			consume_button.pressed.connect(_on_consume_button_pressed.bind(purchase["product_id"], purchase["purchase_token"]))
			purchase_panel.add_child(consume_button)
		
		purchase_panel.add_child(info_label)
		owned_list.add_child(purchase_panel)

func _give_reward(product_id: String) -> void:
	# 根据商品ID给玩家发放奖励
	match product_id:
		CONSUMABLE_PRODUCT_ID:
			print("[IAPExample] 发放100金币奖励！")
			# 这里添加您的游戏逻辑来增加金币
		_:
			print("[IAPExample] 未知商品，无法发放奖励")
