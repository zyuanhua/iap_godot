extends Node

# ========================================
# Google IAP 最小化示例
# ========================================
# 这是最简单的使用方式，仅 3 步！
# ========================================

# GoogleIAP 实例
var google_iap: GoogleIAP

func _ready() -> void:
	# ========================================
	# 第 1 步：连接道具发放信号
	# ========================================
	# 创建 GoogleIAP 实例
	google_iap = GoogleIAP.new()
	add_child(google_iap)
	
	google_iap.item_granted.connect(_on_item_granted)
	google_iap.item_grant_failed.connect(_on_item_grant_failed)
	
	# ========================================
	# 第 2 步：初始化
	# ========================================
	google_iap.initialize()
	
	print("[最小化示例] 初始化完成！")

# ========================================
# 第 3 步：购买商品时，道具自动发放！
# ========================================
func buy_100_coins() -> void:
	google_iap.purchase_product("com.yourgame.coins.100")

func buy_vip_month() -> void:
	google_iap.purchase_product("com.yourgame.vip_month", google_iap.ProductType.SUBS)

# ========================================
# 道具发放成功回调（唯一需要处理的）
# ========================================
func _on_item_granted(product_id: String, item_data: Dictionary) -> void:
	var item_name = item_data.get("item_name", "道具")
	print("[最小化示例] 恭喜获得: ", item_name)
	
	# 显示提示
	# show_reward_popup(item_name)

# ========================================
# 道具发放失败回调
# ========================================
func _on_item_grant_failed(product_id: String, error_message: String) -> void:
	print("[最小化示例] 道具发放失败: ", error_message)
