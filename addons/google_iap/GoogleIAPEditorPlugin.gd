@tool
extends EditorPlugin

var google_iap_dock: Control
var panel_instance: Control

func _enter_tree() -> void:
	_create_dock()

func _exit_tree() -> void:
	if google_iap_dock:
		remove_control_from_docks(google_iap_dock)
		google_iap_dock.queue_free()
		google_iap_dock = null

func _create_dock() -> void:
	if google_iap_dock:
		remove_control_from_docks(google_iap_dock)
		google_iap_dock.queue_free()
	
	google_iap_dock = Control.new()
	google_iap_dock.name = "Google IAP"
	google_iap_dock.custom_minimum_size = Vector2(550, 400)
	
	var panel_scene: Resource = load("res://addons/google_iap/GoogleIAPConfigPanel.tscn")
	if panel_scene:
		panel_instance = panel_scene.instantiate()
		if panel_instance:
			google_iap_dock.add_child(panel_instance)
			panel_instance.anchors_preset = Control.PRESET_FULL_RECT
		else:
			_show_error("无法实例化面板")
	else:
		_show_error("无法加载面板场景")
	
	add_control_to_dock(DOCK_SLOT_LEFT_BR, google_iap_dock)

func _show_error(message: String) -> void:
	var error_label = Label.new()
	error_label.text = "Google IAP 插件加载失败\n\n" + message
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	google_iap_dock.add_child(error_label)
	add_control_to_dock(DOCK_SLOT_LEFT_BR, google_iap_dock)

func _get_plugin_name() -> String:
	return "Google IAP"

func _has_main_screen() -> bool:
	return false

func _get_plugin_icon() -> Texture2D:
	return load("res://addons/google_iap/icon.svg")
