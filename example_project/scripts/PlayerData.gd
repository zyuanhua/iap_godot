extends Node
class_name PlayerData

# ==================== 单例模式 ====================
static var _instance: PlayerData = null

static func get_instance() -> PlayerData:
	return _instance

func _ready() -> void:
	if _instance:
		queue_free()
		return
	_instance = self
	_load_data()

# ==================== 玩家数据 ====================
var coins: int = 0
var vip_days: int = 0
var no_ads: bool = false
var owned_items: Array[String] = []

# ==================== 信号 ====================
signal coins_changed(new_amount: int)
signal vip_days_changed(new_days: int)
signal no_ads_changed(enabled: bool)
signal item_added(item_id: String)

# ==================== 金币管理 ====================
func add_coins(amount: int) -> void:
	coins += amount
	_save_data()
	coins_changed.emit(coins)
	print("[PlayerData] 金币 +", amount, "，当前: ", coins)

func get_coins() -> int:
	return coins

# ==================== VIP管理 ====================
func add_vip_days(days: int) -> void:
	vip_days += days
	_save_data()
	vip_days_changed.emit(vip_days)
	print("[PlayerData] VIP +", days, "天，当前: ", vip_days, "天")

func get_vip_days() -> int:
	return vip_days

func is_vip() -> bool:
	return vip_days > 0

# ==================== 广告管理 ====================
func set_no_ads(enabled: bool) -> void:
	no_ads = enabled
	_save_data()
	no_ads_changed.emit(no_ads)
	print("[PlayerData] 无广告状态: ", enabled)

func has_no_ads() -> bool:
	return no_ads

# ==================== 道具管理 ====================
func add_item(item_id: String) -> void:
	if not owned_items.has(item_id):
		owned_items.append(item_id)
		_save_data()
		item_added.emit(item_id)
		print("[PlayerData] 获得道具: ", item_id)

func has_item(item_id: String) -> bool:
	return owned_items.has(item_id)

func get_owned_items() -> Array[String]:
	return owned_items.duplicate()

# ==================== 数据持久化 ====================
func _get_save_path() -> String:
	return "user://player_data.json"

func _save_data() -> void:
	var save_data = {
		"coins": coins,
		"vip_days": vip_days,
		"no_ads": no_ads,
		"owned_items": owned_items
	}
	
	var json = JSON.stringify(save_data)
	var file = FileAccess.open(_get_save_path(), FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()

func _load_data() -> void:
	if not FileAccess.file_exists(_get_save_path()):
		return
	
	var file = FileAccess.open(_get_save_path(), FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var save_data = json.data
			coins = save_data.get("coins", 0)
			vip_days = save_data.get("vip_days", 0)
			no_ads = save_data.get("no_ads", false)
			owned_items = save_data.get("owned_items", [])

func reset_data() -> void:
	coins = 0
	vip_days = 0
	no_ads = false
	owned_items.clear()
	_save_data()
	coins_changed.emit(coins)
	vip_days_changed.emit(vip_days)
	no_ads_changed.emit(no_ads)
	print("[PlayerData] 数据已重置")
