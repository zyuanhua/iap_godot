extends Node
class_name IAPItemGrantExample

# ========================================
# Google IAP 极简道具发放示例
# ========================================
# 这个示例展示了如何使用道具自动发放系统
# ========================================

# 玩家数据（示例）
var player_data = {
	"coins": 0,
	"vip_days": 0,
	"vip_expire_time": 0,
	"no_ads": false,
	"inventory": {}
}

# GoogleIAP 实例
var google_iap: GoogleIAP

func _ready() -> void:
	print("[示例] IAP 道具发放示例初始化")
	
	# 创建 GoogleIAP 实例
	google_iap = GoogleIAP.new()
	add_child(google_iap)
	
	# 1. 连接信号监听
	_connect_iap_signals()
	
	# 2. 初始化 Google IAP
	google_iap.initialize()
	
	# 3. 可选：设置自定义道具映射（如果需要）
	# setup_custom_item_mapping()
	
	# 4. 可选：设置服务端验证 URL
	# google_iap.server_verification_url = "https://your-server.com/verify-purchase"

# ========================================
# 1. 连接信号监听（最简单的方式）
# ========================================
func _connect_iap_signals() -> void:
	# 监听道具发放成功信号
	google_iap.item_granted.connect(_on_item_granted)
	
	# 监听道具发放失败信号
	google_iap.item_grant_failed.connect(_on_item_grant_failed)
	
	# 监听购买成功信号（如需额外处理）
	google_iap.purchase_success.connect(_on_purchase_success)
	
	# 监听购买失败信号
	google_iap.purchase_failed.connect(_on_purchase_failed)

# ========================================
# 2. 道具发放成功回调（核心）
# ========================================
func _on_item_granted(product_id: String, item_data: Dictionary) -> void:
	print("[示例] 道具发放成功!")
	print("  商品ID: ", product_id)
	print("  道具数据: ", item_data)
	
	# 显示UI提示
	_show_reward_popup(item_data.get("item_name", "道具"))

# ========================================
# 3. 道具发放失败回调
# ========================================
func _on_item_grant_failed(product_id: String, error_message: String) -> void:
	print("[示例] 道具发放失败!")
	print("  商品ID: ", product_id)
	print("  错误信息: ", error_message)
	
	# 显示错误提示
	_show_error_popup(error_message)

# ========================================
# 4. 购买成功回调（可选）
# ========================================
func _on_purchase_success(product_id: String, purchase_token: String, order_id: String) -> void:
	print("[示例] 购买成功，道具会自动发放!")
	# 注意：道具会自动通过item_granted信号发放，这里无需额外处理

# ========================================
# 5. 购买失败回调
# ========================================
func _on_purchase_failed(error_code: int, error_message: String) -> void:
	print("[示例] 购买失败: ", error_message)
	_show_error_popup("购买失败: " + error_message)

# ========================================
# 6. 购买商品的调用示例
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
# 7. 自定义道具映射（可选）
# ========================================
func setup_custom_item_mapping() -> void:
	var custom_mapping = {
		"com.mygame.gems.50": {
			"item_type": "gems",
			"item_amount": 50,
			"item_name": "50 钻石"
		},
		"com.mygame.weapon.fire": {
			"item_type": "weapon",
			"item_amount": 1,
			"item_name": "烈焰之剑",
			"item_id": "weapon_fire_001"
		}
	}
	
	# 设置自定义映射
	google_iap.set_product_item_mapping(custom_mapping)
	
	# 或者添加单个映射
	google_iap.add_product_item_mapping("com.mygame.boost.speed", {
		"item_type": "boost",
		"item_amount": 10,
		"item_name": "10 次加速"
	})
	
	print("[示例] 自定义道具映射已设置")

# ========================================
# 8. 自定义道具发放逻辑（如果需要）
# ========================================
# 如果你想完全自定义道具发放逻辑，可以重写GoogleIAP的grant_item_to_player函数
# 方法：创建一个继承自GoogleIAP的脚本，重写该函数

# ========================================
# 辅助函数 - UI相关（示例）
# ========================================
func _show_reward_popup(item_name: String) -> void:
	print("[示例] 显示奖励弹窗: 获得 ", item_name)
	# 实际项目中:
	# var popup = RewardPopup.new()
	# popup.item_name = item_name
	# get_tree().root.add_child(popup)

func _show_error_popup(message: String) -> void:
	print("[示例] 显示错误弹窗: ", message)
	# 实际项目中:
	# var popup = ErrorPopup.new()
	# popup.message = message
	# get_tree().root.add_child(popup)

# ========================================
# 玩家数据操作函数（实际项目中替换为自己的逻辑）
# ========================================
func add_coins(amount: int) -> void:
	player_data["coins"] += amount
	print("[示例] 玩家金币: ", player_data["coins"])

func add_vip_days(days: int) -> void:
	var current_time = Time.get_ticks_msec() / 1000
	if player_data["vip_expire_time"] < current_time:
		player_data["vip_expire_time"] = current_time + days * 86400
	else:
		player_data["vip_expire_time"] += days * 86400
	print("[示例] VIP到期时间: ", player_data["vip_expire_time"])

func set_no_ads(no_ads: bool) -> void:
	player_data["no_ads"] = no_ads
	print("[示例] 无广告状态: ", player_data["no_ads"])

func add_item_to_inventory(item_id: String, amount: int) -> void:
	if not player_data["inventory"].has(item_id):
		player_data["inventory"][item_id] = 0
	player_data["inventory"][item_id] += amount
	print("[示例] 背包: ", player_data["inventory"])
