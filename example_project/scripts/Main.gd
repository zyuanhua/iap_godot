extends Control

# ==================== UI元素引用 ====================
@onready var coins_label: Label = $VBoxContainer/StatsPanel/CoinsLabel
@onready var vip_label: Label = $VBoxContainer/StatsPanel/VipLabel
@onready var no_ads_label: Label = $VBoxContainer/StatsPanel/NoAdsLabel

@onready var buy_100_coins_btn: Button = $VBoxContainer/ShopPanel/Buy100CoinsBtn
@onready var buy_500_coins_btn: Button = $VBoxContainer/ShopPanel/Buy500CoinsBtn
@onready var buy_vip_month_btn: Button = $VBoxContainer/ShopPanel/BuyVipMonthBtn
@onready var buy_vip_year_btn: Button = $VBoxContainer/ShopPanel/BuyVipYearBtn
@onready var buy_no_ads_btn: Button = $VBoxContainer/ShopPanel/BuyNoAdsBtn
@onready var buy_sword_btn: Button = $VBoxContainer/ShopPanel/BuySwordBtn

@onready var reset_btn: Button = $VBoxContainer/ResetBtn

@onready var message_dialog: AcceptDialog = $MessageDialog
@onready var success_dialog: AcceptDialog = $SuccessDialog

# GoogleIAP 实例
var google_iap: GoogleIAP

# 多语言支持
var lang_data: Dictionary = {}
var current_language: String = "zh"

# ==================== 商品常量 ====================
const PRODUCT_100_COINS: String = "com.yourgame.coins.100"
const PRODUCT_500_COINS: String = "com.yourgame.coins.500"
const PRODUCT_VIP_MONTH: String = "com.yourgame.vip_month"
const PRODUCT_VIP_YEAR: String = "com.yourgame.vip_year"
const PRODUCT_NO_ADS: String = "com.yourgame.no_ads"
const PRODUCT_SWORD: String = "com.yourgame.weapon_sword"

func _ready() -> void:
	# 创建 GoogleIAP 实例
	google_iap = GoogleIAP.new()
	add_child(google_iap)
	
	# 加载语言配置
	_load_language()
	
	# 连接按钮信号
	buy_100_coins_btn.pressed.connect(func(): _on_buy_button_pressed(PRODUCT_100_COINS))
	buy_500_coins_btn.pressed.connect(func(): _on_buy_button_pressed(PRODUCT_500_COINS))
	buy_vip_month_btn.pressed.connect(func(): _on_buy_button_pressed(PRODUCT_VIP_MONTH))
	buy_vip_year_btn.pressed.connect(func(): _on_buy_button_pressed(PRODUCT_VIP_YEAR))
	buy_no_ads_btn.pressed.connect(func(): _on_buy_button_pressed(PRODUCT_NO_ADS))
	buy_sword_btn.pressed.connect(func(): _on_buy_button_pressed(PRODUCT_SWORD))
	
	reset_btn.pressed.connect(_on_reset_button_pressed)
	
	# 连接 Google IAP 信号
	_connect_iap_signals()
	
	# 连接 PlayerData 信号
	_connect_player_data_signals()
	
	# 应用本地化文本
	_apply_localization()
	
	# 更新 UI
	_update_ui()
	
	# 初始化 Google IAP
	google_iap.initialize()
	
	# 配置商品 - 道具映射
	_setup_product_mapping()

func _load_language() -> void:
	# 从配置文件加载语言设置（如果有）
	var config_path = "user://example_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var config = json.data
			current_language = config.get("language", "zh")
	
	# 加载语言文件
	var lang_path = "res://example_project/locales/%s.json" % current_language
	if FileAccess.file_exists(lang_path):
		var file = FileAccess.open(lang_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			lang_data = json.data
			print("[Main] 语言已加载：", current_language)

func _t(key: String) -> String:
	if lang_data.has(key):
		return lang_data[key]
	return key

func _apply_localization() -> void:
	# 更新所有 UI 文本
	$VBoxContainer/TitleLabel.text = _t("title")
	$VBoxContainer/ShopPanel/VBoxContainer3/ShopTitle.text = _t("shop_title")
	$VBoxContainer/ShopPanel/VBoxContainer3/Buy100CoinsBtn.text = _t("buy_100_coins")
	$VBoxContainer/ShopPanel/VBoxContainer3/Buy500CoinsBtn.text = _t("buy_500_coins")
	$VBoxContainer/ShopPanel/VBoxContainer3/BuyVipMonthBtn.text = _t("buy_vip_month")
	$VBoxContainer/ShopPanel/VBoxContainer3/BuyVipYearBtn.text = _t("buy_vip_year")
	$VBoxContainer/ShopPanel/VBoxContainer3/BuyNoAdsBtn.text = _t("buy_no_ads")
	$VBoxContainer/ShopPanel/VBoxContainer3/BuySwordBtn.text = _t("buy_sword")
	$VBoxContainer/ResetBtn.text = _t("reset_data")

func _connect_iap_signals() -> void:
	google_iap.purchase_success.connect(_on_purchase_success)
	google_iap.purchase_failed.connect(_on_purchase_failed)
	google_iap.purchase_cancelled.connect(_on_purchase_cancelled)
	google_iap.purchase_pending.connect(_on_purchase_pending)
	google_iap.item_granted.connect(_on_item_granted)
	google_iap.show_ui_message.connect(_on_show_ui_message)

func _connect_player_data_signals() -> void:
	PlayerData.get_instance().coins_changed.connect(_update_ui)
	PlayerData.get_instance().vip_days_changed.connect(_update_ui)
	PlayerData.get_instance().no_ads_changed.connect(_update_ui)

func _setup_product_mapping() -> void:
	google_iap.product_item_mapping = {
		PRODUCT_100_COINS: {
			"item_type": "coins",
			"item_amount": 100,
			"item_name": "100 金币"
		},
		PRODUCT_500_COINS: {
			"item_type": "coins",
			"item_amount": 500,
			"item_name": "500 金币"
		},
		PRODUCT_VIP_MONTH: {
			"item_type": "vip_days",
			"item_amount": 30,
			"item_name": "30 天 VIP"
		},
		PRODUCT_VIP_YEAR: {
			"item_type": "vip_days",
			"item_amount": 365,
			"item_name": "1 年 VIP"
		},
		PRODUCT_NO_ADS: {
			"item_type": "no_ads",
			"item_amount": 1,
			"item_name": "永久去除广告"
		},
		PRODUCT_SWORD: {
			"item_type": "item",
			"item_amount": 1,
			"item_name": "传说之剑",
			"item_id": "weapon_sword_001"
		}
	}
	
	# 配置服务端验单（示例中关闭，实际使用时设置）
	google_iap.require_server_verification = false
	google_iap.auto_grant_items = true

func _update_ui() -> void:
	var player_data = PlayerData.get_instance()
	coins_label.text = _t("coins") + ": " + str(player_data.get_coins())
	
	var vip_days = player_data.get_vip_days()
	if vip_days > 0:
		vip_label.text = _t("vip") + ": " + str(vip_days) + "天"
	else:
		vip_label.text = _t("vip") + ": " + _t("vip_not_active")
	
	no_ads_label.text = _t("no_ads") + ": " + (_t("yes") if player_data.has_no_ads() else _t("no"))

func _on_buy_button_pressed(product_id: String) -> void:
	print("[Main] 购买商品：" + product_id)
	google_iap.purchase_product(product_id, google_iap.ProductType.IN_APP)

func _on_reset_button_pressed() -> void:
	PlayerData.get_instance().reset_data()
	_show_message(_t("data_reset"))

func _on_purchase_success(product_id: String, purchase_token: String, order_id: String) -> void:
	print("[Main] " + _t("log_purchase_success") + ": " + product_id)

func _on_purchase_failed(error_code: int, error_message: String) -> void:
	print("[Main] " + _t("log_purchase_failed") + ": " + error_message)
	_show_message(_t("purchase_failed") + ": " + error_message)

func _on_purchase_cancelled() -> void:
	print("[Main] " + _t("log_purchase_cancelled"))
	_show_message(_t("purchase_cancelled"))

func _on_purchase_pending(product_id: String) -> void:
	print("[Main] " + _t("log_purchase_pending") + ": " + product_id)
	_show_message(_t("purchase_pending"))

func _on_item_granted(product_id: String, item_data: Dictionary) -> void:
	var item_name = item_data.get("item_name", product_id)
	print("[Main] " + _t("log_item_granted") + ": " + item_name)
	_show_success_dialog(_t("item_granted") + ": " + item_name)
	
	# 手动处理道具发放（展示如何自定义处理）
	_manual_grant_item(item_data)

func _manual_grant_item(item_data: Dictionary) -> void:
	var item_type = item_data.get("item_type", "")
	var item_amount = item_data.get("item_amount", 0)
	var player_data = PlayerData.get_instance()
	
	match item_type:
		"coins":
			player_data.add_coins(item_amount)
		"vip_days":
			player_data.add_vip_days(item_amount)
		"no_ads":
			player_data.set_no_ads(true)
		"item":
			var item_id = item_data.get("item_id", "")
			if not item_id.is_empty():
				player_data.add_item(item_id)

func _on_show_ui_message(message: String, message_type: int) -> void:
	_show_message(message)

func _show_message(message: String) -> void:
	message_dialog.title = _t("purchase_failed") if "失败" in message or "failed" in message.to_lower() else "Message"
	message_dialog.dialog_text = message
	message_dialog.popup_centered()

func _show_success_dialog(message: String) -> void:
	success_dialog.title = _t("item_granted")
	success_dialog.dialog_text = message
	success_dialog.popup_centered()
