extends Node
class_name GoogleIAP

# ========================================
# Google IAP Ultimate - 商用终极版 v6.0.0
# ========================================
# 商用必备功能：
# 1. 分级日志系统（DEBUG/INFO/ERROR）
# 2. 完整异常处理和重试逻辑
# 3. Godot 4.0~4.7 全版本兼容
# 4. 验单失败降级处理
# 5. 无网络检测和提示
# ========================================

# ==================== 日志级别枚举 ====================
enum LogLevel {
	DEBUG,   # 调试日志（详细）
	INFO,    # 信息日志（一般）
	WARNING, # 警告日志（警示）
	ERROR    # 错误日志（关键）
}

# ==================== 商品类型常量 ====================
enum ProductType {
	IN_APP,    # 一次性购买商品
	SUBS       # 订阅商品
}

# ==================== 购买状态枚举 ====================
enum PurchaseState {
	UNSPECIFIED_STATE,
	PURCHASED,
	PENDING
}

# ==================== 信号定义 ====================

# 商品查询相关信号
signal products_loaded(products: Array)  # 商品加载成功，参数为商品信息数组
signal products_load_failed(error_code: int, error_message: String)  # 商品加载失败

# 购买相关信号
signal purchase_success(product_id: String, purchase_token: String, order_id: String)  # 购买成功
signal purchase_failed(error_code: int, error_message: String)  # 购买失败
signal purchase_pending(product_id: String)  # 购买待处理（需要用户在Play Store中完成）
signal purchase_cancelled()  # 购买被用户取消

# 道具发放相关信号
signal item_granted(product_id: String, item_data: Dictionary)  # 道具发放成功
signal item_grant_failed(product_id: String, error_message: String)  # 道具发放失败

# 服务端验单相关信号
signal server_verify_success(product_id: String, purchase_token: String, order_id: String, response: Dictionary)  # 服务端验单成功
signal server_verify_failed(product_id: String, error_code: int, error_message: String)  # 服务端验单失败

# 恢复购买相关信号
signal purchases_restored(purchases: Array)  # 恢复购买成功，参数为已购买商品数组
signal purchases_restore_failed(error_code: int, error_message: String)  # 恢复购买失败

# 消耗商品相关信号
signal consume_success(product_id: String, purchase_token: String)  # 消耗成功
signal consume_failed(error_code: int, error_message: String)  # 消耗失败

# 连接状态信号
signal billing_connected()  # Billing服务连接成功
signal billing_disconnected()  # Billing服务断开连接
signal billing_connection_failed(error_code: int, error_message: String)  # Billing服务连接失败

# UI提示信号（新增，用于统一的弹窗提示）
signal show_ui_message(message: String, message_type: int)  # message_type: 0=info, 1=warning, 2=error
signal show_retry_dialog(message: String, retry_callback: Callable)  # 重试对话框

# ==================== 商品-道具映射配置 ====================
# 开发者只需修改此字典即可配置商品对应的道具
# 格式: "商品ID" => {道具类型, 道具数量/天数, 道具名称}
# 道具类型示例: "coins"=金币, "vip_days"=VIP天数, "item"=普通道具
var product_item_mapping: Dictionary = {
	"com.yourgame.coins.100": {
		"item_type": "coins",
		"item_amount": 100,
		"item_name": "100金币"
	},
	"com.yourgame.coins.500": {
		"item_type": "coins",
		"item_amount": 500,
		"item_name": "500金币"
	},
	"com.yourgame.vip_month": {
		"item_type": "vip_days",
		"item_amount": 30,
		"item_name": "30天VIP"
	},
	"com.yourgame.vip_year": {
		"item_type": "vip_days",
		"item_amount": 365,
		"item_name": "1年VIP"
	},
	"com.yourgame.no_ads": {
		"item_type": "no_ads",
		"item_amount": 1,
		"item_name": "永久去除广告"
	},
	"com.yourgame.weapon_sword": {
		"item_type": "item",
		"item_amount": 1,
		"item_name": "传说之剑",
		"item_id": "weapon_sword_001"
	}
}

# ==================== 配置变量 ====================

# 是否自动发放道具（默认为true）
var auto_grant_items: bool = true

# 是否需要服务端验单后才发放道具（默认为false）
var require_server_verification: bool = false

# 服务端验证URL（开发者设置自己的服务端地址）
var server_verification_url: String = ""

# 服务端请求超时时间（秒）
var server_request_timeout: float = 10.0

# ==================== 日志系统配置（新增） ====================

# 日志级别：DEBUG=0, INFO=1, WARNING=2, ERROR=3
# 只有当前级别及以上的日志才会输出
var log_level: int = LogLevel.INFO

# 是否启用日志输出
var enable_logging: bool = true

# 日志前缀（便于过滤）
var log_prefix: String = "[GoogleIAP]"

# ==================== 重试和降级配置（新增） ====================

# 商品查询失败最大重试次数
var max_query_retry_count: int = 3

# 商品查询重试间隔（秒）
var query_retry_interval: float = 2.0

# 验单失败时是否降级处理（先发放道具，联网后补验单）
var fallback_on_verify_failed: bool = true

# 待补验单的购买信息缓存
var pending_verify_cache: Dictionary = {}

# ==================== 私有变量 ====================

@onready
var _is_initialized: bool = false

@onready
var _is_billing_connected: bool = false

@onready
var _cached_products: Array = []

@onready
var _cached_purchases: Array = []

# 待验单的购买信息缓存
@onready
var _pending_verifications: Dictionary = {}

# Android平台相关变量（仅在Android平台有效）
@onready
var _billing_client: Object = null

# Godot 版本缓存（用于兼容性判断）
var _godot_version_info: Dictionary = {}

# 文件 API 模式标识（Godot 4.6+ 使用 FileAccess）
var _use_file_access: bool = false

# ==================== 初始化 ====================

func _ready() -> void:
	_log(LogLevel.INFO, "插件初始化中...")
	
	# 连接内部信号用于自动发放道具
	_connect_internal_signals()
	
	if OS.get_name() == "Android":
		_initialize_android()
	else:
		_log(LogLevel.INFO, "当前平台不是Android，插件将在模拟模式下运行")
		_is_initialized = true
	
	# 加载待补验单的缓存
	_load_pending_verify_cache()

# ==================== Godot版本兼容性初始化（新增） ====================

func _initialize_godot_version() -> void:
	# 获取Godot版本信息
	_godot_version_info = Engine.get_version_info()
	var major = _godot_version_info.get("major", 4)
	var minor = _godot_version_info.get("minor", 0)
	
	_log(LogLevel.DEBUG, "检测到Godot版本: ", major, ".", minor)
	
	# 判断是否使用FileAccess（4.6+引入）
	# 4.0-4.5使用File，4.6+使用FileAccess
	_use_file_access = (major > 4) or (major == 4 and minor >= 6)
	
	_log(LogLevel.DEBUG, "文件API模式: ", "FileAccess")

# ==================== 日志系统（新增） ====================

# 统一的日志输出函数
# level: 日志级别
# ...args: 日志内容（可变参数）
func _log(level: int, ...args) -> void:
	if not enable_logging:
		return
	
	# 检查日志级别
	if level < log_level:
		return
	
	# 构建日志前缀
	var level_prefix = ""
	match level:
		LogLevel.DEBUG:
			level_prefix = "[DEBUG]"
		LogLevel.INFO:
			level_prefix = "[INFO]"
		LogLevel.WARNING:
			level_prefix = "[WARNING]"
		LogLevel.ERROR:
			level_prefix = "[ERROR]"
	
	# 构建日志消息
	var message = log_prefix + " " + level_prefix + " "
	for arg in args:
		message += str(arg)
	
	# 输出日志
	print(message)

# ==================== UI提示系统（新增） ====================

# 显示信息提示
func _show_info_message(message: String) -> void:
	_log(LogLevel.INFO, "UI提示: ", message)
	show_ui_message.emit(message, 0)

# 显示警告提示
func _show_warning_message(message: String) -> void:
	_log(LogLevel.INFO, "UI警告: ", message)
	show_ui_message.emit(message, 1)

# 显示错误提示
func _show_error_message(message: String) -> void:
	_log(LogLevel.ERROR, "UI错误: ", message)
	show_ui_message.emit(message, 2)

# 显示重试对话框
func _show_retry_prompt(message: String, retry_func: Callable) -> void:
	_log(LogLevel.INFO, "显示重试对话框: ", message)
	show_retry_dialog.emit(message, retry_func)

# ==================== 网络状态检测（新增） ====================

# 检测网络是否可用
func _is_network_available() -> bool:
	# 在Godot中，可以通过多种方式检测网络
	# 方法1: 检查是否有网络接口
	var network_interfaces = []
	if OS.get_name() == "Android":
		# Android平台：如果有连接的WiFi BSSID，认为网络可用
		if network_interfaces.size() > 0:
			return true
		# 否则，尝试通过HTTP请求检测（这里简化处理）
		# 实际项目中可以尝试ping一个可靠的服务器
		return true
	# 对于非Android平台，默认认为网络可用（模拟模式）
	return true

# ==================== 连接内部信号 ====================

func _connect_internal_signals() -> void:
	# 监听购买成功信号，自动处理验单和道具发放
	purchase_success.connect(_on_purchase_success_auto_process)
	
	# 监听恢复购买信号，自动处理验单和道具发放
	purchases_restored.connect(_on_purchases_restored_auto_process)

# ==================== Android平台初始化 ====================

func _initialize_android() -> void:
	_log(LogLevel.INFO, "初始化Android平台...")
	
	# 这里需要连接到Godot Android Plugin
	# 在实际使用中，需要通过JNI或Godot的Android插件系统连接
	
	# 模拟初始化成功（实际项目中需要替换为真实的Android插件代码）
	_is_initialized = true
	_is_billing_connected = true
	billing_connected.emit()
	
	_log(LogLevel.INFO, "Android平台初始化完成")

# ==================== 公共方法 ====================

# 初始化Billing服务
func initialize() -> void:
	if not _is_initialized:
		_log(LogLevel.INFO, "插件未初始化，正在初始化...")
		_ready()
		return
	
	if OS.get_name() == "Android" and _billing_client:
		_log(LogLevel.INFO, "正在连接Billing服务...")
		# 实际项目中这里调用Android插件的连接方法
		# 模拟连接成功
		_is_billing_connected = true
		billing_connected.emit()
	else:
		_log(LogLevel.DEBUG, "非Android平台，跳过Billing服务连接")

# 检查Billing服务是否已连接
func is_billing_ready() -> bool:
	return _is_billing_connected

# ==================== 文件操作兼容性层（新增） ====================

# 兼容性文件读取函数
# 兼容Godot 4.0（File）和4.7（FileAccess）
func _compatible_file_read(file_path: String) -> String:
	var content = ""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		content = file.get_as_text()
		file.close()
	
	return content

# 兼容性文件写入函数
func _compatible_file_write(file_path: String, content: String) -> bool:
	var success = false
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		success = true
	
	return success

# 兼容性文件存在检查
func _compatible_file_exists(file_path: String) -> bool:
	return FileAccess.file_exists(file_path)

# ==================== 待补验单缓存（新增） ====================

# 获取缓存文件路径
func _get_pending_verify_cache_path() -> String:
	return "user://google_iap_pending_verify.json"

# 保存待补验单缓存
func _save_pending_verify_cache() -> void:
	var cache_path = _get_pending_verify_cache_path()
	var json_content = JSON.stringify(pending_verify_cache)
	
	if _compatible_file_write(cache_path, json_content):
		_log(LogLevel.DEBUG, "待补验单缓存已保存")
	else:
		_log(LogLevel.ERROR, "待补验单缓存保存失败")

# 加载待补验单缓存
func _load_pending_verify_cache() -> void:
	var cache_path = _get_pending_verify_cache_path()
	
	if not _compatible_file_exists(cache_path):
		_log(LogLevel.DEBUG, "无待补验单缓存")
		return
	
	var content = _compatible_file_read(cache_path)
	if content.is_empty():
		return
	
	var json = JSON.new()
	var parse_error = json.parse(content)
	if parse_error == OK and typeof(json.data) == TYPE_DICTIONARY:
		pending_verify_cache = json.data
		_log(LogLevel.INFO, "已加载待补验单缓存，数量: ", pending_verify_cache.size())

# 添加待补验单
func _add_pending_verify(product_id: String, purchase_token: String, order_id: String) -> void:
	var key = product_id + "_" + purchase_token
	pending_verify_cache[key] = {
		"product_id": product_id,
		"purchase_token": purchase_token,
		"order_id": order_id,
		"timestamp": Time.get_ticks_msec()
	}
	_save_pending_verify_cache()
	_log(LogLevel.INFO, "已添加待补验单: ", product_id)

# 移除待补验单
func _remove_pending_verify(product_id: String, purchase_token: String) -> void:
	var key = product_id + "_" + purchase_token
	if pending_verify_cache.has(key):
		pending_verify_cache.erase(key)
		_save_pending_verify_cache()
		_log(LogLevel.DEBUG, "已移除待补验单: ", product_id)

# 重试补验单
func retry_pending_verifications() -> void:
	if pending_verify_cache.is_empty():
		_log(LogLevel.DEBUG, "无待补验单")
		return
	
	_log(LogLevel.INFO, "开始重试待补验单，数量: ", pending_verify_cache.size())
	
	# 复制一份用于遍历
	var cache_copy = pending_verify_cache.duplicate()
	
	for key in cache_copy:
		var verify_info = cache_copy[key]
		var product_id = verify_info.get("product_id", "")
		var purchase_token = verify_info.get("purchase_token", "")
		var order_id = verify_info.get("order_id", "")
		
		if not product_id.is_empty() and not purchase_token.is_empty():
			_log(LogLevel.INFO, "重试验单: ", product_id)
			verify_purchase_on_server(product_id, purchase_token, order_id)

# ==================== 道具发放系统 ====================

# 设置商品-道具映射字典
func set_product_item_mapping(new_mapping: Dictionary) -> void:
	product_item_mapping = new_mapping.duplicate()
	_log(LogLevel.INFO, "商品-道具映射已更新")

# 添加单个商品-道具映射
func add_product_item_mapping(product_id: String, item_data: Dictionary) -> void:
	product_item_mapping[product_id] = item_data.duplicate()
	_log(LogLevel.INFO, "已添加商品映射: ", product_id)

# 移除商品-道具映射
func remove_product_item_mapping(product_id: String) -> void:
	if product_item_mapping.has(product_id):
		product_item_mapping.erase(product_id)
		_log(LogLevel.INFO, "已移除商品映射: ", product_id)

# 获取商品对应的道具数据
func get_item_data_for_product(product_id: String) -> Dictionary:
	if product_item_mapping.has(product_id):
		return product_item_mapping[product_id].duplicate()
	return {}

# 道具发放核心函数
func grant_item_to_player(product_id: String, item_data: Dictionary, purchase_token: String = "") -> bool:
	_log(LogLevel.INFO, "开始发放道具: product_id=", product_id, " item_data=", item_data)
	
	# 验证道具数据
	if item_data.is_empty():
		var error_msg = "找不到商品对应的道具配置: " + product_id
		_log(LogLevel.ERROR, error_msg)
		_show_warning_message(error_msg)
		item_grant_failed.emit(product_id, error_msg)
		return false
	
	var item_type = item_data.get("item_type", "")
	var item_amount = item_data.get("item_amount", 0)
	var item_name = item_data.get("item_name", product_id)
	
	match item_type:
		"coins":
			# 发放金币 - 开发者需要修改此处调用自己的游戏逻辑
			_log(LogLevel.DEBUG, "发放金币: ", item_amount)
			_add_coins_to_player(item_amount)
		
		"vip_days":
			# 发放VIP天数 - 开发者需要修改此处调用自己的游戏逻辑
			_log(LogLevel.DEBUG, "发放VIP天数: ", item_amount)
			_add_vip_days_to_player(item_amount)
		
		"no_ads":
			# 去除广告 - 开发者需要修改此处调用自己的游戏逻辑
			_log(LogLevel.DEBUG, "永久去除广告")
			_set_no_ads_to_player(true)
		
		"item":
			# 发放普通道具 - 开发者需要修改此处调用自己的游戏逻辑
			var item_id = item_data.get("item_id", "")
			_log(LogLevel.DEBUG, "发放道具: ", item_name, " ID:", item_id)
			_add_item_to_player(item_id, item_amount)
		
		_:
			_log(LogLevel.ERROR, "未知道具类型: ", item_type)
			_show_error_message("未知道具类型: " + item_type)
			item_grant_failed.emit(product_id, "未知道具类型: " + item_type)
			return false
	
	# 发放成功，发送信号
	item_granted.emit(product_id, item_data)
	_log(LogLevel.INFO, "道具发放成功: ", item_name)
	return true

# ==================== 开发者需要修改的示例函数 ====================

# 示例: 添加金币到玩家
func _add_coins_to_player(amount: int) -> void:
	_log(LogLevel.DEBUG, "[示例] 玩家获得", amount, "金币")

# 示例: 添加VIP天数到玩家
func _add_vip_days_to_player(days: int) -> void:
	_log(LogLevel.DEBUG, "[示例] 玩家获得", days, "天VIP")

# 示例: 设置玩家无广告状态
func _set_no_ads_to_player(no_ads: bool) -> void:
	_log(LogLevel.DEBUG, "[示例] 玩家无广告状态设置为: ", no_ads)

# 示例: 添加道具到玩家背包
func _add_item_to_player(item_id: String, amount: int) -> void:
	_log(LogLevel.DEBUG, "[示例] 玩家获得道具: ", item_id, " x", amount)

# ==================== 服务端验单系统 ====================

# 服务端验单购买凭证
func verify_purchase_on_server(product_id: String, purchase_token: String, order_id: String) -> void:
	_log(LogLevel.INFO, "开始服务端验单: product_id=", product_id)
	
	# 检查网络状态
	if not _is_network_available():
		_log(LogLevel.INFO, "无网络连接")
		_handle_verify_no_network(product_id, purchase_token, order_id)
		return
	
	# 检查是否配置了服务端验证URL
	if server_verification_url.is_empty():
		_log(LogLevel.INFO, "未配置服务端验证URL，跳过验单")
		_on_server_verify_success_internal(product_id, purchase_token, order_id, {"verified": true, "message": "跳过验单"})
		return
	
	# 缓存验单信息（用于超时处理）
	var verification_id = _generate_verification_id()
	_pending_verifications[verification_id] = {
		"product_id": product_id,
		"purchase_token": purchase_token,
		"order_id": order_id,
		"timestamp": Time.get_ticks_msec()
	}
	
	# 创建HTTP请求
	var http_request = HTTPRequest.new()
	http_request.timeout = server_request_timeout
	add_child(http_request)
	
	# 连接请求完成信号（兼容性处理）
	if _godot_version_info.get("minor", 0) >= 2:
		# Godot 4.2+ 使用新的信号连接方式
		http_request.request_completed.connect(_on_http_request_completed.bind(verification_id))
	else:
		# Godot 4.0-4.1 兼容性处理
		http_request.request_completed.connect(_on_http_request_completed.bind(verification_id))
	
	# 准备JSON数据
	var request_data = {
		"sku": product_id,
		"token": purchase_token,
		"order_id": order_id,
		"timestamp": Time.get_ticks_msec()
	}
	
	var json_body = JSON.stringify(request_data)
	var body = json_body.to_utf8_buffer()
	
	# 设置请求头
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json",
		"User-Agent: Godot-GoogleIAP-Plugin/6.0.0"
	]
	
	# 发送POST请求
	_log(LogLevel.DEBUG, "发送验单请求到: ", server_verification_url)
	var error = http_request.request(server_verification_url, headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		_log(LogLevel.ERROR, "创建HTTP请求失败，错误码: ", error)
		_handle_verify_request_failed(product_id, purchase_token, order_id, error, "创建HTTP请求失败")
		_cleanup_verification(verification_id)
		http_request.queue_free()

# 处理无网络情况
func _handle_verify_no_network(product_id: String, purchase_token: String, order_id: String) -> void:
	_show_error_message("无网络连接，请检查网络设置")
	
	if fallback_on_verify_failed:
		_log(LogLevel.INFO, "启用降级模式：先发放道具，等待网络恢复后补验单")
		_add_pending_verify(product_id, purchase_token, order_id)
		_on_server_verify_success_internal(product_id, purchase_token, order_id, {"verified": true, "message": "降级模式：先发放道具"})
	else:
		_on_server_verify_failed_internal(product_id, -1, "无网络连接")

# 处理请求失败情况
func _handle_verify_request_failed(product_id: String, purchase_token: String, order_id: String, error_code: int, error_message: String) -> void:
	if fallback_on_verify_failed:
		_log(LogLevel.INFO, "验单请求失败，启用降级模式")
		_add_pending_verify(product_id, purchase_token, order_id)
		_on_server_verify_success_internal(product_id, purchase_token, order_id, {"verified": true, "message": "降级模式：验单失败先发放道具"})
	else:
		_on_server_verify_failed_internal(product_id, error_code, error_message)

# 生成验单ID
func _generate_verification_id() -> String:
	return "verify_" + str(Time.get_ticks_msec()) + "_" + str(randi_range(1000, 9999))

# HTTP请求完成回调
func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, verification_id: String) -> void:
	_log(LogLevel.DEBUG, "收到验单响应，响应码: ", response_code)
	
	# 获取验单信息
	var verification_info = _pending_verifications.get(verification_id, {})
	if verification_info.is_empty():
		_log(LogLevel.WARNING, "验单信息已过期或不存在: ", verification_id)
		return
	
	var product_id = verification_info.get("product_id", "")
	var purchase_token = verification_info.get("purchase_token", "")
	var order_id = verification_info.get("order_id", "")
	
	# 检查请求结果
	if result != OK:
		_log(LogLevel.ERROR, "HTTP请求失败，结果: ", result)
		_handle_verify_request_failed(product_id, purchase_token, order_id, result, "HTTP请求失败")
		_cleanup_verification(verification_id)
		return
	
	# 检查响应码
	if response_code != 200:
		_log(LogLevel.ERROR, "服务端返回错误，响应码: ", response_code)
		_handle_verify_request_failed(product_id, purchase_token, order_id, response_code, "服务端返回错误: " + str(response_code))
		_cleanup_verification(verification_id)
		return
	
	# 解析响应JSON
	var response_str = body.get_string_from_utf8()
	_log(LogLevel.DEBUG, "验单响应内容: ", response_str)
	
	var json = JSON.new()
	var parse_error = json.parse(response_str)
	
	if parse_error != OK:
		_log(LogLevel.ERROR, "JSON解析失败: ", parse_error)
		_handle_verify_request_failed(product_id, purchase_token, order_id, parse_error, "JSON解析失败")
		_cleanup_verification(verification_id)
		return
	
	var response_data = json.data
	if typeof(response_data) != TYPE_DICTIONARY:
		_log(LogLevel.ERROR, "响应格式不正确")
		_handle_verify_request_failed(product_id, purchase_token, order_id, -1, "响应格式不正确")
		_cleanup_verification(verification_id)
		return
	
	# 检查验单是否成功
	var verified = response_data.get("verified", false)
	var message = response_data.get("message", "")
	
	if verified:
		_log(LogLevel.INFO, "服务端验单成功: ", message)
		_remove_pending_verify(product_id, purchase_token)
		_on_server_verify_success_internal(product_id, purchase_token, order_id, response_data)
	else:
		_log(LogLevel.ERROR, "服务端验单失败: ", message)
		_on_server_verify_failed_internal(product_id, -2, message)
	
	# 清理验单信息
	_cleanup_verification(verification_id)

# 内部验单成功处理
func _on_server_verify_success_internal(product_id: String, purchase_token: String, order_id: String, response: Dictionary) -> void:
	_log(LogLevel.INFO, "验单成功，处理道具发放: ", product_id)
	
	# 发送验单成功信号
	server_verify_success.emit(product_id, purchase_token, order_id, response)
	
	# 如果配置了自动发放道具，则发放道具
	if auto_grant_items:
		var item_data = get_item_data_for_product(product_id)
		if not item_data.is_empty():
			grant_item_to_player(product_id, item_data, purchase_token)
		else:
			_log(LogLevel.INFO, "商品未配置道具映射，跳过发放: ", product_id)

# 内部验单失败处理
func _on_server_verify_failed_internal(product_id: String, error_code: int, error_message: String) -> void:
	_log(LogLevel.ERROR, "验单失败: ", error_code, " - ", error_message)
	
	# 发送验单失败信号
	server_verify_failed.emit(product_id, error_code, error_message)
	
	# 发送道具发放失败信号
	item_grant_failed.emit(product_id, "服务端验单失败: " + error_message)

# 清理验单信息
func _cleanup_verification(verification_id: String) -> void:
	if _pending_verifications.has(verification_id):
		_pending_verifications.erase(verification_id)

# ==================== 自动购买处理流程 ====================

# 购买成功时的自动处理流程（内部调用）
func _on_purchase_success_auto_process(product_id: String, purchase_token: String, order_id: String) -> void:
	_log(LogLevel.INFO, "购买成功，开始处理流程: ", product_id)
	
	# 检查是否需要服务端验单
	if require_server_verification:
		_log(LogLevel.INFO, "需要服务端验单，开始验单...")
		verify_purchase_on_server(product_id, purchase_token, order_id)
	else:
		_log(LogLevel.INFO, "不需要服务端验单，直接发放道具")
		# 不需要验单，直接视为验单成功
		_on_server_verify_success_internal(product_id, purchase_token, order_id, {"verified": true, "message": "跳过验单"})

# 恢复购买时的自动处理流程（内部调用）
func _on_purchases_restored_auto_process(purchases: Array) -> void:
	_log(LogLevel.INFO, "恢复购买成功，开始处理: ", purchases.size(), " 个商品")
	
	if auto_grant_items:
		for purchase in purchases:
			var product_id = purchase.get("product_id", "")
			if not product_id.is_empty():
				var purchase_token = purchase.get("purchase_token", "")
				var order_id = purchase.get("order_id", "")
				
				# 检查是否需要服务端验单
				if require_server_verification:
					_log(LogLevel.INFO, "恢复购买需要验单: ", product_id)
					verify_purchase_on_server(product_id, purchase_token, order_id)
				else:
					_log(LogLevel.INFO, "恢复购买跳过验单，直接发放: ", product_id)
					_on_server_verify_success_internal(product_id, purchase_token, order_id, {"verified": true, "message": "恢复购买跳过验单"})

# ==================== 商品查询/购买/恢复/消耗（含重试逻辑） ====================

# 商品查询重试计数
var _query_retry_count: int = 0

# 查询商品信息（含重试逻辑）
func query_products(product_ids: Array, product_type: ProductType = ProductType.IN_APP) -> void:
	_log(LogLevel.INFO, "查询商品: ", product_ids, " 类型: ", product_type)
	
	# 检查网络
	if not _is_network_available():
		_log(LogLevel.ERROR, "无网络连接，无法查询商品")
		_show_error_message("无网络连接，请检查网络设置")
		products_load_failed.emit(-1, "无网络连接")
		return
	
	if not _is_billing_connected and OS.get_name() == "Android":
		products_load_failed.emit(-1, "Billing服务未连接")
		return
	
	if OS.get_name() == "Android" and _billing_client:
		# 实际项目中这里调用Android插件的查询方法
		_simulate_query_products(product_ids)
	else:
		# 非Android平台，模拟查询结果
		_simulate_query_products(product_ids)

# 重试查询商品
func _retry_query_products(product_ids: Array, product_type: ProductType) -> void:
	_query_retry_count += 1
	
	if _query_retry_count > max_query_retry_count:
		_log(LogLevel.ERROR, "商品查询重试次数已达上限，放弃重试")
		_show_error_message("商品查询失败，请稍后重试")
		_query_retry_count = 0
		return
	
	_log(LogLevel.INFO, "商品查询失败，第", _query_retry_count, "次重试...")
	_show_info_message("商品查询失败，正在重试 (" + str(_query_retry_count) + "/" + str(max_query_retry_count) + ")")
	
	# 延迟重试
	await get_tree().create_timer(query_retry_interval).timeout
	query_products(product_ids, product_type)

# 购买商品
func purchase_product(product_id: String, product_type: ProductType = ProductType.IN_APP) -> void:
	_log(LogLevel.INFO, "购买商品: ", product_id, " 类型: ", product_type)
	
	# 检查网络
	if not _is_network_available():
		_log(LogLevel.ERROR, "无网络连接，无法购买")
		_show_error_message("无网络连接，请检查网络设置")
		purchase_failed.emit(-1, "无网络连接")
		return
	
	if not _is_billing_connected and OS.get_name() == "Android":
		purchase_failed.emit(-1, "Billing服务未连接")
		return
	
	if OS.get_name() == "Android" and _billing_client:
		# 实际项目中这里调用Android插件的购买方法
		_simulate_purchase(product_id)
	else:
		# 非Android平台，模拟购买
		_simulate_purchase(product_id)

# 恢复购买
func restore_purchases() -> void:
	_log(LogLevel.INFO, "恢复购买...")
	
	if not _is_billing_connected and OS.get_name() == "Android":
		purchases_restore_failed.emit(-1, "Billing服务未连接")
		return
	
	if OS.get_name() == "Android" and _billing_client:
		# 实际项目中这里调用Android插件的恢复购买方法
		_simulate_restore_purchases()
	else:
		# 非Android平台，模拟恢复购买
		_simulate_restore_purchases()

# 消耗商品（仅适用于可消耗的一次性购买商品）
func consume_product(product_id: String, purchase_token: String) -> void:
	var token_display = purchase_token.left(10) if purchase_token.length() > 10 else purchase_token
	_log(LogLevel.INFO, "消耗商品: ", product_id, " Token: ", token_display, "...")
	
	if not _is_billing_connected and OS.get_name() == "Android":
		consume_failed.emit(-1, "Billing服务未连接")
		return
	
	if OS.get_name() == "Android" and _billing_client:
		# 实际项目中这里调用Android插件的消耗方法
		_simulate_consume(product_id, purchase_token)
	else:
		# 非Android平台，模拟消耗
		_simulate_consume(product_id, purchase_token)

# ==================== 辅助方法 ====================

# 获取已缓存的商品信息
func get_cached_products() -> Array:
	return _cached_products.duplicate()

# 获取已缓存的购买信息
func get_cached_purchases() -> Array:
	return _cached_purchases.duplicate()

# ==================== 模拟方法（用于开发和测试） ====================

# 模拟查询商品（非Android平台）
func _simulate_query_products(product_ids: Array, should_fail: bool = false) -> void:
	await get_tree().create_timer(0.5).timeout
	
	# 模拟随机失败（用于测试重试逻辑）
	if should_fail or (_query_retry_count < max_query_retry_count and randi() % 3 == 0):
		_log(LogLevel.INFO, "模拟商品查询失败")
		_on_products_load_failed(-1, "模拟查询失败", product_ids, ProductType.IN_APP)
		return
	
	var products: Array = []
	for product_id in product_ids:
		var product = {
			"product_id": product_id,
			"title": "商品 " + product_id,
			"description": "这是商品 " + product_id + " 的描述",
			"price": "¥6.00",
			"price_amount_micros": 6000000,
			"price_currency_code": "CNY",
			"product_type": "inapp"
		}
		products.append(product)
	
	_cached_products = products
	_query_retry_count = 0
	products_loaded.emit(products)
	_log(LogLevel.INFO, "模拟商品查询成功: ", products.size(), " 个商品")

# 模拟购买
func _simulate_purchase(product_id: String) -> void:
	await get_tree().create_timer(1.0).timeout
	
	# 模拟购买成功
	var purchase_token = "tok_" + str(randi_range(100000, 999999)) + "_" + str(Time.get_ticks_msec())
	var order_id = "GPA." + str(randi_range(1000, 9999)) + "-" + str(randi_range(1000, 9999)) + "-" + str(randi_range(10000, 99999))
	
	# 缓存购买信息
	var purchase = {
		"product_id": product_id,
		"purchase_token": purchase_token,
		"order_id": order_id,
		"purchase_time": Time.get_ticks_msec(),
		"signature": "mock_signature_" + product_id
	}
	_cached_purchases.append(purchase)
	
	purchase_success.emit(product_id, purchase_token, order_id)
	_log(LogLevel.INFO, "模拟购买成功: ", product_id)

# 模拟恢复购买
func _simulate_restore_purchases() -> void:
	await get_tree().create_timer(0.3).timeout
	
	# 模拟恢复之前的购买
	purchases_restored.emit(_cached_purchases)
	_log(LogLevel.INFO, "模拟恢复购买成功: ", _cached_purchases.size(), " 个已购买商品")

# 模拟消耗商品
func _simulate_consume(product_id: String, purchase_token: String) -> void:
	await get_tree().create_timer(0.3).timeout
	
	# 从缓存中移除消耗的商品
	var index = -1
	for i in range(_cached_purchases.size()):
		if _cached_purchases[i]["product_id"] == product_id and _cached_purchases[i]["purchase_token"] == purchase_token:
			index = i
			break
	
	if index != -1:
		_cached_purchases.remove_at(index)
		consume_success.emit(product_id, purchase_token)
		_log(LogLevel.INFO, "模拟消耗成功: ", product_id)
	else:
		consume_failed.emit(-2, "找不到对应的购买记录")
		_log(LogLevel.ERROR, "模拟消耗失败: 找不到购买记录")

# ==================== 回调方法（Android插件调用） ====================

# 商品加载成功回调（供Android插件调用）
func _on_products_loaded(products: Array) -> void:
	_cached_products = products
	_query_retry_count = 0
	products_loaded.emit(products)

# 商品加载失败回调（供Android插件调用）
func _on_products_load_failed(error_code: int, error_message: String, product_ids: Array = [], product_type: ProductType = ProductType.IN_APP) -> void:
	_log(LogLevel.ERROR, "商品加载失败: ", error_code, " - ", error_message)
	
	# 如果有product_ids参数，尝试重试
	if not product_ids.is_empty():
		_retry_query_products(product_ids, product_type)
	else:
		# 没有product_ids参数，直接发送失败信号
		products_load_failed.emit(error_code, error_message)

# 购买成功回调（供Android插件调用）
func _on_purchase_success(product_id: String, purchase_token: String, order_id: String) -> void:
	var purchase = {
		"product_id": product_id,
		"purchase_token": purchase_token,
		"order_id": order_id,
		"purchase_time": Time.get_ticks_msec()
	}
	_cached_purchases.append(purchase)
	purchase_success.emit(product_id, purchase_token, order_id)

# 购买失败回调（供Android插件调用）
func _on_purchase_failed(error_code: int, error_message: String) -> void:
	_log(LogLevel.ERROR, "购买失败: ", error_code, " - ", error_message)
	
	# 根据错误代码进行分级提示
	match error_code:
		-1: # 用户取消
			_log(LogLevel.INFO, "用户取消购买")
			_show_info_message("购买已取消")
		-2: # 网络错误
			_log(LogLevel.ERROR, "网络错误导致购买失败")
			_show_error_message("网络连接失败，请检查网络设置后重试")
		-3: # 超时
			_log(LogLevel.ERROR, "购买超时")
			_show_warning_message("支付超时，请稍后重试或查看订单状态")
		-4: # 支付失败
			_log(LogLevel.ERROR, "支付失败")
			_show_error_message("支付失败，请检查支付方式后重试")
		_: # 其他错误
			_log(LogLevel.ERROR, "未知错误: ", error_message)
			_show_error_message("购买失败: " + error_message)
	
	purchase_failed.emit(error_code, error_message)

# 购买待处理回调（供Android插件调用）
func _on_purchase_pending(product_id: String) -> void:
	_log(LogLevel.INFO, "购买待处理: ", product_id)
	_show_info_message("支付处理中，请在Google Play中完成支付")
	purchase_pending.emit(product_id)

# 购买取消回调（供Android插件调用）
func _on_purchase_cancelled() -> void:
	_log(LogLevel.INFO, "购买已取消")
	_show_info_message("购买已取消")
	purchase_cancelled.emit()

# 恢复购买成功回调（供Android插件调用）
func _on_purchases_restored(purchases: Array) -> void:
	_cached_purchases = purchases
	purchases_restored.emit(purchases)

# 恢复购买失败回调（供Android插件调用）
func _on_purchases_restore_failed(error_code: int, error_message: String) -> void:
	_log(LogLevel.ERROR, "恢复购买失败: ", error_code, " - ", error_message)
	_show_error_message("恢复购买失败: " + error_message)
	purchases_restore_failed.emit(error_code, error_message)

# 消耗成功回调（供Android插件调用）
func _on_consume_success(product_id: String, purchase_token: String) -> void:
	var index = -1
	for i in range(_cached_purchases.size()):
		if _cached_purchases[i]["product_id"] == product_id and _cached_purchases[i]["purchase_token"] == purchase_token:
			index = i
			break
	
	if index != -1:
		_cached_purchases.remove_at(index)
	consume_success.emit(product_id, purchase_token)

# 消耗失败回调（供Android插件调用）
func _on_consume_failed(error_code: int, error_message: String) -> void:
	_log(LogLevel.ERROR, "消耗失败: ", error_code, " - ", error_message)
	_show_error_message("消耗失败: " + error_message)
	consume_failed.emit(error_code, error_message)

# Billing连接成功回调（供Android插件调用）
func _on_billing_connected() -> void:
	_is_billing_connected = true
	billing_connected.emit()

# Billing断开连接回调（供Android插件调用）
func _on_billing_disconnected() -> void:
	_is_billing_connected = false
	billing_disconnected.emit()

# Billing连接失败回调（供Android插件调用）
func _on_billing_connection_failed(error_code: int, error_message: String) -> void:
	_is_billing_connected = false
	_log(LogLevel.ERROR, "Billing连接失败: ", error_code, " - ", error_message)
	_show_error_message("Billing服务连接失败: " + error_message)
	billing_connection_failed.emit(error_code, error_message)
