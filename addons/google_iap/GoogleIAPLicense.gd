extends Node
class_name GoogleIAPLicense

# ========================================
# Google IAP 授权管理模块
# 基于设备唯一ID的授权绑定
# ========================================

# ==================== 配置 ====================

# 是否启用授权验证
var enable_license_check: bool = false

# 授权的设备ID列表
var authorized_device_ids: Array[String] = []

# ==================== 信号 ====================

signal license_verified()  # 授权验证成功
signal license_failed(reason: String)  # 授权验证失败

# ==================== 私有变量 ====================

var _is_verified: bool = false
var _current_device_id: String = ""

# ==================== 初始化 ====================

func _ready() -> void:
	_get_current_device_id()

# ==================== 设备ID获取 ====================

func _get_current_device_id() -> String:
	if _current_device_id.is_empty():
		# 使用Godot的设备唯一ID
		_current_device_id = OS.get_unique_id()
		# 如果获取失败，使用其他方式生成
		if _current_device_id.is_empty():
			_current_device_id = _generate_fallback_device_id()
	return _current_device_id

func _generate_fallback_device_id() -> String:
	# 后备方案：组合多种系统信息生成ID
	var info = ""
	info += OS.get_name()
	info += OS.get_distribution_name()
	info += OS.get_version()
	info += str(OS.get_processor_count())
	info += str(OS.get_static_memory_usage())
	
	# 简单哈希
	var hash = 0
	for char in info:
		hash = (hash * 31 + char.unicode_at(0)) & 0x7FFFFFFF
	
	return "FALLBACK_" + str(hash)

# ==================== 授权管理 ====================

func get_current_device_id() -> String:
	return _get_current_device_id()

func add_authorized_device(device_id: String) -> void:
	if not authorized_device_ids.has(device_id):
		authorized_device_ids.append(device_id)
		print("[GoogleIAPLicense] 已添加授权设备: ", device_id)

func remove_authorized_device(device_id: String) -> void:
	if authorized_device_ids.has(device_id):
		authorized_device_ids.erase(device_id)
		print("[GoogleIAPLicense] 已移除授权设备: ", device_id)

func clear_authorized_devices() -> void:
	authorized_device_ids.clear()
	print("[GoogleIAPLicense] 已清空所有授权设备")

# ==================== 授权验证 ====================

func verify_license() -> bool:
	if not enable_license_check:
		# 未启用授权检查，直接通过
		_is_verified = true
		license_verified.emit()
		return true
	
	var device_id = _get_current_device_id()
	
	if authorized_device_ids.is_empty():
		# 没有授权设备列表，验证失败
		_is_verified = false
		var reason = "未配置授权设备列表"
		license_failed.emit(reason)
		print("[GoogleIAPLicense] 授权失败: ", reason)
		return false
	
	if authorized_device_ids.has(device_id):
		# 设备已授权
		_is_verified = true
		license_verified.emit()
		print("[GoogleIAPLicense] 授权成功: ", device_id)
		return true
	else:
		# 设备未授权
		_is_verified = false
		var reason = "设备未授权: " + device_id
		license_failed.emit(reason)
		print("[GoogleIAPLicense] 授权失败: ", reason)
		return false

func is_verified() -> bool:
	return _is_verified

# ==================== 授权持久化 ====================

func _get_license_file_path() -> String:
	return "user://google_iap_license.dat"

func save_authorized_devices() -> void:
	var save_data = {
		"authorized_device_ids": authorized_device_ids,
		"enable_license_check": enable_license_check
	}
	
	var json = JSON.stringify(save_data)
	var file = FileAccess.open(_get_license_file_path(), FileAccess.WRITE)
	if file:
		# 简单混淆保存内容
		var obfuscated = _obfuscate_string(json)
		file.store_string(obfuscated)
		file.close()
		print("[GoogleIAPLicense] 授权配置已保存")

func load_authorized_devices() -> void:
	var file_path = _get_license_file_path()
	if not FileAccess.file_exists(file_path):
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var obfuscated = file.get_as_text()
		file.close()
		
		var json = _deobfuscate_string(obfuscated)
		var parser = JSON.new()
		if parser.parse(json) == OK:
			var data = parser.data
			authorized_device_ids = data.get("authorized_device_ids", [])
			enable_license_check = data.get("enable_license_check", false)
			print("[GoogleIAPLicense] 授权配置已加载")

# ==================== 简单字符串混淆（防君子不防小人） ====================

func _obfuscate_string(input: String) -> String:
	var result = ""
	var key = 0x5A
	for i in range(input.length()):
		var char = input[i]
		var code = char.unicode_at(0) ^ key
		result += char.chr(code)
	return result

func _deobfuscate_string(input: String) -> String:
	return _obfuscate_string(input)  # 异或运算的逆运算是自身

# ==================== 便捷方法 ====================

func show_device_id_dialog() -> void:
	# 显示当前设备ID（用于授权配置）
	var device_id = get_current_device_id()
	
	var dialog = AcceptDialog.new()
	dialog.title = "设备ID"
	dialog.dialog_text = "当前设备ID:\n" + device_id + "\n\n请将此ID添加到授权列表中"
	dialog.unresizable = false
	
	var copy_button = Button.new()
	copy_button.text = "复制"
	copy_button.pressed.connect(func(): 
		DisplayServer.clipboard_set(device_id)
		dialog.hide()
	)
	
	dialog.add_button("确定", true)
	dialog.add_child(copy_button)
	dialog.set_ok_button_text("确定")
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func quick_authorize_current_device() -> void:
	# 快速授权当前设备
	var device_id = get_current_device_id()
	add_authorized_device(device_id)
	save_authorized_devices()
	print("[GoogleIAPLicense] 当前设备已授权: ", device_id)
