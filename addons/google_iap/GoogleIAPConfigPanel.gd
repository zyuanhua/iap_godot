@tool
extends ScrollContainer
class_name GoogleIAPConfigPanel

const PROVIDER_KEYS: Array[String] = ["google", "apple", "huawei"]
const ENVIRONMENT_KEYS: Array[String] = ["production", "sandbox", "test"]
const SKU_TYPE_KEYS: Array[String] = ["consumable", "non_consumable", "subscription"]
const SKU_STATUS_KEYS: Array[String] = ["active", "inactive", "pending"]
const APPROVAL_HOURS: int = 2

var localization_data: Dictionary = {}
var current_language: String = "zh"
var sku_database: Array[Dictionary] = []
var user_configs: Dictionary = {}
var current_user: String = ""
var billing_initialized: bool = false
var pending_dialog_action: String = ""
var pending_dialog_data: Dictionary = {}
var is_editing_sku: bool = false
var editing_sku_index: int = -1
var debug_mode: bool = false
var pending_timer: Timer = null
var file_dialog: FileDialog = null

var _nodes: Dictionary = {}

func _ready() -> void:
	_cache_nodes()
	_reorder_modules()
	_load_saved_language()
	_load_language_file(current_language)
	_load_column_widths()
	_setup_ui()
	_connect_signals()
	_init_sku_data()
	_setup_pending_timer()
	_load_all_user_configs()
	_ensure_default_user()
	_update_button_states()

func _reorder_modules() -> void:
	var main_vbox: VBoxContainer = get_node_or_null("MainVBox")
	if not main_vbox:
		return
	
	var header_row: Node = main_vbox.get_node_or_null("HeaderRow")
	var sep0: Node = main_vbox.get_node_or_null("Sep0")
	var module6: Node = main_vbox.get_node_or_null("Module6_ServerConfig")
	var sep5: Node = main_vbox.get_node_or_null("Sep5")
	var module3: Node = main_vbox.get_node_or_null("Module3_SKU")
	var sep2: Node = main_vbox.get_node_or_null("Sep2")
	var module2: Node = main_vbox.get_node_or_null("Module2_Billing")
	var sep3: Node = main_vbox.get_node_or_null("Sep3")
	var module4: Node = main_vbox.get_node_or_null("Module4_Simulation")
	var sep4: Node = main_vbox.get_node_or_null("Sep4")
	var module7: Node = main_vbox.get_node_or_null("Module7_Verification")
	var sep6: Node = main_vbox.get_node_or_null("Sep6")
	var module5: Node = main_vbox.get_node_or_null("Module5_Log")
	var sep7: Node = main_vbox.get_node_or_null("Sep7")
	var module8: Node = main_vbox.get_node_or_null("Module8_Analytics")
	
	if not header_row or not module6 or not module3:
		return
	
	var desired_order: Array = [
		header_row, sep0,
		module6, sep5,
		module3, sep2,
		module2, sep3,
		module4, sep4,
		module7, sep6,
		module5, sep7,
		module8
	]
	
	for i: int in desired_order.size():
		var node: Node = desired_order[i]
		if node:
			var current_idx: int = node.get_index()
			if current_idx != i:
				main_vbox.move_child(node, i)

func _init_sku_data() -> void:
	var config_path: String = "res://addons/google_iap/sku_database.json"
	if FileAccess.file_exists(config_path):
		var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			var json: JSON = JSON.new()
			if json.parse(json_string) == OK:
				var data: Variant = json.data
				if data is Array:
					sku_database.clear()
					for item: Variant in data:
						if item is Dictionary:
							sku_database.append(item)
	_refresh_sku_tree()

func _save_sku_database() -> void:
	var config_path: String = "res://addons/google_iap/sku_database.json"
	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(sku_database, "  ")
		file.store_string(json_string)
		file.close()

func _save_column_widths() -> void:
	var config_path: String = "res://addons/google_iap/column_widths.json"
	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(sku_column_widths, "  ")
		file.store_string(json_string)
		file.close()

func _load_column_widths() -> void:
	var config_path: String = "res://addons/google_iap/column_widths.json"
	if FileAccess.file_exists(config_path):
		var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			var json: JSON = JSON.new()
			var parse_result: int = json.parse(json_string)
			if parse_result == OK:
				var loaded_widths: Array = json.data
				for i: int in min(loaded_widths.size(), sku_column_widths.size()):
					sku_column_widths[i] = int(loaded_widths[i])

func _setup_pending_timer() -> void:
	if pending_timer == null:
		pending_timer = Timer.new()
		pending_timer.wait_time = 60.0
		pending_timer.one_shot = false
		pending_timer.autostart = true
		pending_timer.timeout.connect(_apply_pending_status)
		add_child(pending_timer)

func _get_provider_rules(provider: String) -> Dictionary:
	var rules: Dictionary = {
		"name_modify_needs_approval": false,
		"price_modify_needs_approval": false,
		"approval_hours": APPROVAL_HOURS,
		"allow_physical_delete": false,
		"reactivate_needs_approval": false
	}
	match provider:
		"google":
			rules.name_modify_needs_approval = false
			rules.price_modify_needs_approval = false
			rules.reactivate_needs_approval = false
		"apple":
			rules.name_modify_needs_approval = true
			rules.price_modify_needs_approval = false
			rules.reactivate_needs_approval = true
		"huawei":
			rules.name_modify_needs_approval = true
			rules.price_modify_needs_approval = false
			rules.reactivate_needs_approval = true
	return rules

func _load_saved_language() -> void:
	var config_path: String = "res://addons/google_iap/settings.cfg"
	if FileAccess.file_exists(config_path):
		var config: ConfigFile = ConfigFile.new()
		if config.load(config_path) == OK:
			var saved_lang: String = config.get_value("settings", "language", "zh")
			if saved_lang in ["zh", "en"]:
				current_language = saved_lang

func _save_language_setting() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "language", current_language)
	var config_path: String = "res://addons/google_iap/settings.cfg"
	config.save(config_path)

func _cache_nodes() -> void:
	_nodes["language_selector"] = get_node_or_null("MainVBox/HeaderRow/LanguageSelector")
	_nodes["title_label"] = get_node_or_null("MainVBox/HeaderRow/TitleLabel")
	
	_nodes["title2"] = get_node_or_null("MainVBox/Module2_Billing/TitleRow/Title2")
	_nodes["module2_info"] = get_node_or_null("MainVBox/Module2_Billing/TitleRow/Module2Info")
	_nodes["label2_1"] = get_node_or_null("MainVBox/Module2_Billing/Row1/Label1")
	_nodes["env_option"] = get_node_or_null("MainVBox/Module2_Billing/Row1/EnvOption")
	_nodes["btn_init_billing"] = get_node_or_null("MainVBox/Module2_Billing/Row2/BtnInitBilling")
	_nodes["btn_refresh_billing"] = get_node_or_null("MainVBox/Module2_Billing/Row2/BtnRefreshBilling")
	_nodes["btn_close_billing"] = get_node_or_null("MainVBox/Module2_Billing/Row2/BtnCloseBilling")
	_nodes["service_status_label"] = get_node_or_null("MainVBox/Module2_Billing/Row2/ServiceStatusLabel")
	
	_nodes["title3"] = get_node_or_null("MainVBox/Module3_SKU/TitleRow/Title3")
	_nodes["module3_info"] = get_node_or_null("MainVBox/Module3_SKU/TitleRow/Module3Info")
	_nodes["filter_label"] = get_node_or_null("MainVBox/Module3_SKU/FilterRow/FilterLabel")
	_nodes["sku_provider_filter"] = get_node_or_null("MainVBox/Module3_SKU/FilterRow/SkuProviderFilter")
	_nodes["show_inactive_checkbox"] = get_node_or_null("MainVBox/Module3_SKU/FilterRow/ShowInactiveCheckbox")
	_nodes["debug_mode_checkbox"] = get_node_or_null("MainVBox/Module3_SKU/FilterRow/DebugModeCheckbox")
	_nodes["btn_manual_sync"] = get_node_or_null("MainVBox/Module3_SKU/FilterRow/BtnManualSync")
	_nodes["label3_1"] = get_node_or_null("MainVBox/Module3_SKU/InputRow1/Label1")
	_nodes["sku_id_edit"] = get_node_or_null("MainVBox/Module3_SKU/InputRow1/SkuIdEdit")
	_nodes["label3_2"] = get_node_or_null("MainVBox/Module3_SKU/InputRow2/Label2")
	_nodes["sku_name_edit"] = get_node_or_null("MainVBox/Module3_SKU/InputRow2/SkuNameEdit")
	_nodes["label3_3"] = get_node_or_null("MainVBox/Module3_SKU/InputRow3/Label3")
	_nodes["sku_price_edit"] = get_node_or_null("MainVBox/Module3_SKU/InputRow3/SkuPriceEdit")
	_nodes["label3_4"] = get_node_or_null("MainVBox/Module3_SKU/InputRow4/Label4")
	_nodes["sku_provider_option"] = get_node_or_null("MainVBox/Module3_SKU/InputRow4/SkuProviderOption")
	_nodes["btn_add_sku"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow1/BtnAddSku")
	_nodes["btn_edit_sku"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow1/BtnEditSku")
	_nodes["btn_update_sku"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow1/BtnUpdateSku")
	_nodes["btn_deactivate_sku"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow2/BtnDeactivateSku")
	_nodes["btn_activate_sku"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow2/BtnActivateSku")
	_nodes["btn_import_json"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow3/BtnImportJson")
	_nodes["btn_export_json"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow3/BtnExportJson")
	_nodes["btn_import_csv"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow3/BtnImportCsv")
	_nodes["btn_export_csv"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow3/BtnExportCsv")
	_nodes["btn_add_new_sku"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow4/BtnAddNewSku")
	_nodes["btn_delete_sku"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow4/BtnDeleteSku")
	_nodes["btn_clear_list"] = get_node_or_null("MainVBox/Module3_SKU/BtnRow4/BtnClearList")
	_nodes["sku_tree"] = get_node_or_null("MainVBox/Module3_SKU/SkuTree")
	_nodes["status_timer"] = get_node_or_null("MainVBox/Module3_SKU/StatusTimer")
	
	_nodes["title4"] = get_node_or_null("MainVBox/Module4_Simulation/TitleRow/Title4")
	_nodes["module4_info"] = get_node_or_null("MainVBox/Module4_Simulation/TitleRow/Module4Info")
	_nodes["btn_simulate_success"] = get_node_or_null("MainVBox/Module4_Simulation/BtnRow1/BtnSimulateSuccess")
	_nodes["btn_simulate_no_stock"] = get_node_or_null("MainVBox/Module4_Simulation/BtnRow1/BtnSimulateNoStock")
	_nodes["btn_simulate_cancel"] = get_node_or_null("MainVBox/Module4_Simulation/BtnRow1/BtnSimulateCancel")
	_nodes["btn_reset_test"] = get_node_or_null("MainVBox/Module4_Simulation/BtnRow2/BtnResetTest")
	_nodes["debug_checkbox"] = get_node_or_null("MainVBox/Module4_Simulation/BtnRow2/DebugCheckbox")
	
	_nodes["title5"] = get_node_or_null("MainVBox/Module5_Log/TitleRow/Title5")
	_nodes["module5_info"] = get_node_or_null("MainVBox/Module5_Log/TitleRow/Module5Info")
	_nodes["log_text"] = get_node_or_null("MainVBox/Module5_Log/LogText")
	_nodes["btn_clear_log"] = get_node_or_null("MainVBox/Module5_Log/BtnRow/BtnClearLog")
	_nodes["btn_export_log"] = get_node_or_null("MainVBox/Module5_Log/BtnRow/BtnExportLog")
	
	_nodes["title6"] = get_node_or_null("MainVBox/Module6_ServerConfig/TitleRow/Title6")
	_nodes["module6_info"] = get_node_or_null("MainVBox/Module6_ServerConfig/TitleRow/Module6Info")
	_nodes["account_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/AccountRow/AccountLabel")
	_nodes["account_selector"] = get_node_or_null("MainVBox/Module6_ServerConfig/AccountRow/AccountSelector")
	_nodes["btn_new_account"] = get_node_or_null("MainVBox/Module6_ServerConfig/AccountRow/BtnNewAccount")
	_nodes["btn_save_account"] = get_node_or_null("MainVBox/Module6_ServerConfig/AccountRow/BtnSaveAccount")
	_nodes["btn_delete_account"] = get_node_or_null("MainVBox/Module6_ServerConfig/AccountRow/BtnDeleteAccount")
	_nodes["btn_rename_account"] = get_node_or_null("MainVBox/Module6_ServerConfig/AccountRow/BtnRenameAccount")
	_nodes["label6_1"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigRow1/Label1")
	_nodes["server_provider"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigRow1/ServerProvider")
	_nodes["label6_2"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigRow2/Label2")
	_nodes["server_env"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigRow2/ServerEnv")
	_nodes["google_config_container"] = get_node_or_null("MainVBox/Module6_ServerConfig/GoogleConfigContainer")
	_nodes["google_key_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/GoogleConfigContainer/Row1/Label1")
	_nodes["google_key_path"] = get_node_or_null("MainVBox/Module6_ServerConfig/GoogleConfigContainer/Row1/GoogleKeyPath")
	_nodes["btn_select_google_key"] = get_node_or_null("MainVBox/Module6_ServerConfig/GoogleConfigContainer/Row1/BtnSelectGoogleKey")
	_nodes["google_package_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/GoogleConfigContainer/Row2/Label2")
	_nodes["google_package_name"] = get_node_or_null("MainVBox/Module6_ServerConfig/GoogleConfigContainer/Row2/GooglePackageName")
	_nodes["apple_config_container"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer")
	_nodes["apple_issuer_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row1/Label1")
	_nodes["apple_issuer_id"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row1/AppleIssuerId")
	_nodes["apple_key_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row2/Label2")
	_nodes["apple_key_id"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row2/AppleKeyId")
	_nodes["apple_bundle_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row3/Label3")
	_nodes["apple_bundle_id"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row3/AppleBundleId")
	_nodes["apple_keyfile_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row4/Label4")
	_nodes["apple_key_path"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row4/AppleKeyPath")
	_nodes["btn_select_apple_key"] = get_node_or_null("MainVBox/Module6_ServerConfig/AppleConfigContainer/Row4/BtnSelectAppleKey")
	_nodes["huawei_config_container"] = get_node_or_null("MainVBox/Module6_ServerConfig/HuaweiConfigContainer")
	_nodes["huawei_api_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/HuaweiConfigContainer/Row1/Label1")
	_nodes["huawei_api_key"] = get_node_or_null("MainVBox/Module6_ServerConfig/HuaweiConfigContainer/Row1/HuaweiApiKey")
	_nodes["huawei_app_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/HuaweiConfigContainer/Row2/Label2")
	_nodes["huawei_app_id"] = get_node_or_null("MainVBox/Module6_ServerConfig/HuaweiConfigContainer/Row2/HuaweiAppId")
	_nodes["btn_save_config"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigBtnRow/BtnSaveConfig")
	_nodes["btn_load_config"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigBtnRow/BtnLoadConfig")
	_nodes["btn_test_connection"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigBtnRow/BtnTestConnection")
	_nodes["config_status_label"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfigStatusRow/ConfigStatusLabel")
	_nodes["input_dialog"] = get_node_or_null("MainVBox/Module6_ServerConfig/InputDialog")
	_nodes["input_field"] = get_node_or_null("MainVBox/Module6_ServerConfig/InputDialog/InputField")
	_nodes["confirm_dialog"] = get_node_or_null("MainVBox/Module6_ServerConfig/ConfirmDialog")
	_nodes["message_dialog"] = get_node_or_null("MainVBox/Module6_ServerConfig/MessageDialog")
	
	_nodes["title7"] = get_node_or_null("MainVBox/Module7_Verification/TitleRow/Title7")
	_nodes["module7_info"] = get_node_or_null("MainVBox/Module7_Verification/TitleRow/Module7Info")
	_nodes["verify_provider_label"] = get_node_or_null("MainVBox/Module7_Verification/ProviderRow/ProviderLabel")
	_nodes["verify_provider_option"] = get_node_or_null("MainVBox/Module7_Verification/ProviderRow/VerifyProviderOption")
	_nodes["test_google_container"] = get_node_or_null("MainVBox/Module7_Verification/TestGoogleContainer")
	_nodes["google_product_label"] = get_node_or_null("MainVBox/Module7_Verification/TestGoogleContainer/Row1/Label1")
	_nodes["google_product_id_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestGoogleContainer/Row1/GoogleProductIdEdit")
	_nodes["google_token_label"] = get_node_or_null("MainVBox/Module7_Verification/TestGoogleContainer/Row2/Label2")
	_nodes["google_token_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestGoogleContainer/Row2/GoogleTokenEdit")
	_nodes["google_order_label"] = get_node_or_null("MainVBox/Module7_Verification/TestGoogleContainer/Row3/Label3")
	_nodes["google_order_id_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestGoogleContainer/Row3/GoogleOrderIdEdit")
	_nodes["test_apple_container"] = get_node_or_null("MainVBox/Module7_Verification/TestAppleContainer")
	_nodes["apple_product_label"] = get_node_or_null("MainVBox/Module7_Verification/TestAppleContainer/Row1/Label1")
	_nodes["apple_product_id_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestAppleContainer/Row1/AppleProductIdEdit")
	_nodes["apple_transaction_label"] = get_node_or_null("MainVBox/Module7_Verification/TestAppleContainer/Row2/Label2")
	_nodes["apple_transaction_id_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestAppleContainer/Row2/AppleTransactionIdEdit")
	_nodes["apple_original_label"] = get_node_or_null("MainVBox/Module7_Verification/TestAppleContainer/Row3/Label3")
	_nodes["apple_original_tx_id_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestAppleContainer/Row3/AppleOriginalTxIdEdit")
	_nodes["test_huawei_container"] = get_node_or_null("MainVBox/Module7_Verification/TestHuaweiContainer")
	_nodes["huawei_product_label"] = get_node_or_null("MainVBox/Module7_Verification/TestHuaweiContainer/Row1/Label1")
	_nodes["huawei_product_id_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestHuaweiContainer/Row1/HuaweiProductIdEdit")
	_nodes["huawei_token_label"] = get_node_or_null("MainVBox/Module7_Verification/TestHuaweiContainer/Row2/Label2")
	_nodes["huawei_token_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestHuaweiContainer/Row2/HuaweiTokenEdit")
	_nodes["huawei_purchase_label"] = get_node_or_null("MainVBox/Module7_Verification/TestHuaweiContainer/Row3/Label3")
	_nodes["huawei_purchase_data_edit"] = get_node_or_null("MainVBox/Module7_Verification/TestHuaweiContainer/Row3/HuaweiPurchaseDataEdit")
	_nodes["btn_simulate_verify"] = get_node_or_null("MainVBox/Module7_Verification/BtnRow/BtnSimulateVerify")
	_nodes["btn_clear_response"] = get_node_or_null("MainVBox/Module7_Verification/BtnRow/BtnClearResponse")
	_nodes["response_label"] = get_node_or_null("MainVBox/Module7_Verification/ResponseLabel")
	_nodes["response_text"] = get_node_or_null("MainVBox/Module7_Verification/ResponseText")
	_nodes["key_file_dialog"] = get_node_or_null("KeyFileDialog")
	
	_nodes["title8"] = get_node_or_null("MainVBox/Module8_Analytics/TitleRow/Title8")
	_nodes["module8_info"] = get_node_or_null("MainVBox/Module8_Analytics/TitleRow/Module8Info")
	_nodes["platform_label"] = get_node_or_null("MainVBox/Module8_Analytics/PlatformRow/PlatformLabel")
	_nodes["report_platform_selector"] = get_node_or_null("MainVBox/Module8_Analytics/PlatformRow/ReportPlatformSelector")
	_nodes["btn_test_report_connection"] = get_node_or_null("MainVBox/Module8_Analytics/PlatformRow/BtnTestReportConnection")
	_nodes["apple_report_container"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer")
	_nodes["apple_report_issuer_label"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row1/Label1")
	_nodes["apple_report_issuer_id"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row1/AppleReportIssuerId")
	_nodes["apple_report_key_label"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row2/Label2")
	_nodes["apple_report_key_id"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row2/AppleReportKeyId")
	_nodes["apple_report_keyfile_label"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row3/Label3")
	_nodes["apple_report_key_path"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row3/AppleReportKeyPath")
	_nodes["btn_select_apple_report_key"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row3/BtnSelectAppleReportKey")
	_nodes["apple_vendor_label"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row4/Label4")
	_nodes["apple_vendor_number"] = get_node_or_null("MainVBox/Module8_Analytics/AppleReportContainer/Row4/AppleVendorNumber")
	_nodes["google_report_container"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer")
	_nodes["google_report_key_label"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer/Row1/Label1")
	_nodes["google_report_key_path"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer/Row1/GoogleReportKeyPath")
	_nodes["btn_select_google_report_key"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer/Row1/BtnSelectGoogleReportKey")
	_nodes["google_bucket_label"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer/Row2/Label2")
	_nodes["google_bucket_id"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer/Row2/GoogleBucketId")
	_nodes["google_package_label"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer/Row3/Label3")
	_nodes["google_package_name_edit"] = get_node_or_null("MainVBox/Module8_Analytics/GoogleReportContainer/Row3/GooglePackageNameEdit")
	_nodes["huawei_report_container"] = get_node_or_null("MainVBox/Module8_Analytics/HuaweiReportContainer")
	_nodes["huawei_report_client_label"] = get_node_or_null("MainVBox/Module8_Analytics/HuaweiReportContainer/Row1/Label1")
	_nodes["huawei_report_client_id"] = get_node_or_null("MainVBox/Module8_Analytics/HuaweiReportContainer/Row1/HuaweiReportClientId")
	_nodes["huawei_report_app_label"] = get_node_or_null("MainVBox/Module8_Analytics/HuaweiReportContainer/Row2/Label2")
	_nodes["huawei_report_app_id"] = get_node_or_null("MainVBox/Module8_Analytics/HuaweiReportContainer/Row2/HuaweiReportAppId")
	_nodes["huawei_report_team_label"] = get_node_or_null("MainVBox/Module8_Analytics/HuaweiReportContainer/Row3/Label3")
	_nodes["huawei_report_team_id"] = get_node_or_null("MainVBox/Module8_Analytics/HuaweiReportContainer/Row3/HuaweiReportTeamId")
	_nodes["report_type_label"] = get_node_or_null("MainVBox/Module8_Analytics/QueryRow/ReportTypeLabel")
	_nodes["report_type_selector"] = get_node_or_null("MainVBox/Module8_Analytics/QueryRow/ReportTypeSelector")
	_nodes["date_range_label"] = get_node_or_null("MainVBox/Module8_Analytics/DateRangeRow/DateRangeLabel")
	_nodes["date_range_selector"] = get_node_or_null("MainVBox/Module8_Analytics/DateRangeRow/DateRangeSelector")
	_nodes["start_date_label"] = get_node_or_null("MainVBox/Module8_Analytics/DateRangeRow/StartDateLabel")
	_nodes["start_date_picker"] = get_node_or_null("MainVBox/Module8_Analytics/DateRangeRow/StartDatePicker")
	_nodes["end_date_label"] = get_node_or_null("MainVBox/Module8_Analytics/DateRangeRow/EndDateLabel")
	_nodes["end_date_picker"] = get_node_or_null("MainVBox/Module8_Analytics/DateRangeRow/EndDatePicker")
	_nodes["btn_query_reports"] = get_node_or_null("MainVBox/Module8_Analytics/DateRangeRow/BtnQueryReports")
	_nodes["report_tree"] = get_node_or_null("MainVBox/Module8_Analytics/ReportListRow/ReportTree")
	_nodes["preview_label"] = get_node_or_null("MainVBox/Module8_Analytics/ReportPreviewRow/PreviewLabel")
	_nodes["report_preview_table"] = get_node_or_null("MainVBox/Module8_Analytics/ReportPreviewRow/ReportPreviewTable")
	_nodes["btn_download_report"] = get_node_or_null("MainVBox/Module8_Analytics/ReportBtnRow/BtnDownloadReport")
	_nodes["btn_open_report_folder"] = get_node_or_null("MainVBox/Module8_Analytics/ReportBtnRow/BtnOpenReportFolder")
	_nodes["report_progress_bar"] = get_node_or_null("MainVBox/Module8_Analytics/ReportProgressBar")
	_nodes["report_status_label"] = get_node_or_null("MainVBox/Module8_Analytics/ReportStatusLabel")
	_nodes["report_file_dialog"] = get_node_or_null("ReportFileDialog")

func _load_language_file(lang: String) -> void:
	var locale_path: String = "res://addons/google_iap/locales/%s.json" % lang
	if FileAccess.file_exists(locale_path):
		var file: FileAccess = FileAccess.open(locale_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			var json: JSON = JSON.new()
			var error: int = json.parse(json_string)
			if error == OK:
				localization_data = json.data
			else:
				push_error("Failed to parse language file: %s, error: %s" % [locale_path, json.get_error_message()])
		else:
			push_error("Failed to open language file: %s" % locale_path)
	else:
		push_error("Language file not found: %s" % locale_path)

func _t(key: String) -> String:
	var keys: PackedStringArray = key.split(".")
	var current_data: Variant = localization_data
	for k: String in keys:
		if current_data is Dictionary and current_data.has(k):
			current_data = current_data[k]
		else:
			return key
	if current_data is String:
		return current_data
	return key

func _setup_ui() -> void:
	_setup_language_selector()
	_setup_provider_options()
	_setup_environment_options()
	_setup_sku_tree()
	_setup_verify_provider_option()
	_apply_localization()

func _setup_language_selector() -> void:
	if _nodes["language_selector"]:
		_nodes["language_selector"].clear()
		_nodes["language_selector"].add_item("中文")
		_nodes["language_selector"].add_item("English")
		_nodes["language_selector"].select(0 if current_language == "zh" else 1)

func _setup_provider_options() -> void:
	var provider_nodes: Array = ["sku_provider_filter", "sku_provider_option", "server_provider"]
	var provider_keys: Array = ["google", "apple", "huawei"]
	for node_name: String in provider_nodes:
		if _nodes[node_name]:
			_nodes[node_name].clear()
			for key: String in provider_keys:
				_nodes[node_name].add_item(_t("common.provider." + key))

func _setup_environment_options() -> void:
	var env_nodes: Array = ["env_option", "server_env"]
	var env_keys: Array = ["production", "sandbox", "test"]
	for node_name: String in env_nodes:
		if _nodes[node_name]:
			_nodes[node_name].clear()
			for key: String in env_keys:
				_nodes[node_name].add_item(_t("common.environment." + key))

func _apply_pending_status() -> void:
	var current_time: int = Time.get_unix_time_from_system()
	var changed: bool = false
	for i: int in sku_database.size():
		var sku: Dictionary = sku_database[i]
		if sku.get("status", "active") == "pending":
			var pending_until: int = sku.get("pending_until", 0)
			if current_time >= pending_until:
				var pending_fields: Dictionary = sku.get("pending_fields", {})
				for field: String in pending_fields.keys():
					sku[field] = pending_fields[field]
				sku["status"] = "active"
				sku.erase("pending_until")
				sku.erase("pending_fields")
				changed = true
				_log_message(_t("module3.log.sku_activated").replace("{sku_id}", sku.get("sku_id", "")))
	if changed:
		_save_sku_database()
		_refresh_sku_tree()

func _get_pending_time_text(pending_until: int) -> String:
	var current_time: int = Time.get_unix_time_from_system()
	var remaining: int = pending_until - current_time
	if remaining <= 0:
		return _t("module3.status.effecting")
	var hours: int = remaining / 3600
	var minutes: int = (remaining % 3600) / 60
	if hours > 0:
		return _t("module3.status.pending_time").replace("{hours}", str(hours)).replace("{minutes}", str(minutes))
	else:
		return _t("module3.status.pending_minutes").replace("{minutes}", str(minutes))

var sku_column_widths: Array[int] = [120, 200, 150, 80, 100, 120, 120]

func _setup_sku_tree() -> void:
	if _nodes["sku_tree"]:
		_nodes["sku_tree"].columns = 7
		_nodes["sku_tree"].set_column_title(0, _t("module3.tree.provider"))
		_nodes["sku_tree"].set_column_title(1, _t("module3.tree.sku_id"))
		_nodes["sku_tree"].set_column_title(2, _t("module3.tree.sku_name"))
		_nodes["sku_tree"].set_column_title(3, _t("module3.tree.sku_price"))
		_nodes["sku_tree"].set_column_title(4, _t("module3.tree.sku_type"))
		_nodes["sku_tree"].set_column_title(5, _t("module3.tree.status"))
		_nodes["sku_tree"].set_column_title(6, _t("module3.tree.effect_time"))
		_apply_column_widths()
		_nodes["sku_tree"].set_column_clip_content(0, false)
		_nodes["sku_tree"].set_column_clip_content(1, false)
		_nodes["sku_tree"].set_column_clip_content(2, false)
		_nodes["sku_tree"].set_column_clip_content(3, false)
		_nodes["sku_tree"].set_column_clip_content(4, false)
		_nodes["sku_tree"].set_column_clip_content(5, false)
		_nodes["sku_tree"].set_column_clip_content(6, false)
		_nodes["sku_tree"].hide_root = true
		if _nodes["sku_tree"].has_signal("column_width_changed"):
			if not _nodes["sku_tree"].column_width_changed.is_connected(_on_column_width_changed):
				_nodes["sku_tree"].column_width_changed.connect(_on_column_width_changed)

func _apply_column_widths() -> void:
	if not _nodes["sku_tree"]:
		return
	for i: int in sku_column_widths.size():
		_nodes["sku_tree"].set_column_custom_minimum_width(i, sku_column_widths[i])

func _on_column_width_changed(column: int, new_width: int) -> void:
	if column >= 0 and column < sku_column_widths.size():
		sku_column_widths[column] = new_width
		_save_column_widths()

func _setup_verify_provider_option() -> void:
	if _nodes["verify_provider_option"]:
		_nodes["verify_provider_option"].clear()
		var provider_keys: Array = ["google", "apple", "huawei"]
		for key: String in provider_keys:
			_nodes["verify_provider_option"].add_item(_t("common.provider." + key))

func _connect_signals() -> void:
	if _nodes["language_selector"]:
		_nodes["language_selector"].item_selected.connect(_on_language_selected)
	
	if _nodes["btn_init_billing"]:
		_nodes["btn_init_billing"].pressed.connect(_on_init_billing_pressed)
	if _nodes["btn_refresh_billing"]:
		_nodes["btn_refresh_billing"].pressed.connect(_on_refresh_billing_pressed)
	if _nodes["btn_close_billing"]:
		_nodes["btn_close_billing"].pressed.connect(_on_close_billing_pressed)
	
	if _nodes["sku_provider_filter"]:
		_nodes["sku_provider_filter"].item_selected.connect(_on_sku_provider_filter_changed)
	if _nodes["show_inactive_checkbox"]:
		_nodes["show_inactive_checkbox"].toggled.connect(_on_show_inactive_toggled)
	if _nodes["debug_mode_checkbox"]:
		_nodes["debug_mode_checkbox"].toggled.connect(_on_debug_mode_toggled)
	if _nodes["btn_manual_sync"]:
		_nodes["btn_manual_sync"].pressed.connect(_on_manual_sync_pressed)
	
	if _nodes["btn_add_sku"]:
		_nodes["btn_add_sku"].pressed.connect(_on_add_sku_pressed)
	if _nodes["btn_edit_sku"]:
		_nodes["btn_edit_sku"].pressed.connect(_on_edit_sku_pressed)
	if _nodes["btn_update_sku"]:
		_nodes["btn_update_sku"].pressed.connect(_on_update_sku_pressed)
	if _nodes["btn_deactivate_sku"]:
		_nodes["btn_deactivate_sku"].pressed.connect(_on_deactivate_sku_pressed)
	if _nodes["btn_activate_sku"]:
		_nodes["btn_activate_sku"].pressed.connect(_on_activate_sku_pressed)
	if _nodes["btn_import_json"]:
		_nodes["btn_import_json"].pressed.connect(_on_import_json_pressed)
	if _nodes["btn_export_json"]:
		_nodes["btn_export_json"].pressed.connect(_on_export_json_pressed)
	if _nodes["btn_import_csv"]:
		_nodes["btn_import_csv"].pressed.connect(_on_import_csv_pressed)
	if _nodes["btn_export_csv"]:
		_nodes["btn_export_csv"].pressed.connect(_on_export_csv_pressed)
	if _nodes["btn_add_new_sku"]:
		_nodes["btn_add_new_sku"].pressed.connect(_on_add_new_sku_pressed)
	if _nodes["btn_delete_sku"]:
		_nodes["btn_delete_sku"].pressed.connect(_on_delete_sku_pressed)
	if _nodes["btn_clear_list"]:
		_nodes["btn_clear_list"].pressed.connect(_on_clear_list_pressed)
	if _nodes["sku_tree"]:
		_nodes["sku_tree"].item_selected.connect(_on_sku_tree_item_selected)
	
	if _nodes["btn_simulate_success"]:
		_nodes["btn_simulate_success"].pressed.connect(_on_simulate_success_pressed)
	if _nodes["btn_simulate_no_stock"]:
		_nodes["btn_simulate_no_stock"].pressed.connect(_on_simulate_no_stock_pressed)
	if _nodes["btn_simulate_cancel"]:
		_nodes["btn_simulate_cancel"].pressed.connect(_on_simulate_cancel_pressed)
	if _nodes["btn_reset_test"]:
		_nodes["btn_reset_test"].pressed.connect(_on_reset_test_pressed)
	
	if _nodes["btn_clear_log"]:
		_nodes["btn_clear_log"].pressed.connect(_on_clear_log_pressed)
	if _nodes["btn_export_log"]:
		_nodes["btn_export_log"].pressed.connect(_on_export_log_pressed)
	
	if _nodes["account_selector"]:
		_nodes["account_selector"].item_selected.connect(_on_account_selected)
	if _nodes["btn_new_account"]:
		_nodes["btn_new_account"].pressed.connect(_on_new_account_pressed)
	if _nodes["btn_save_account"]:
		_nodes["btn_save_account"].pressed.connect(_on_save_account_pressed)
	if _nodes["btn_delete_account"]:
		_nodes["btn_delete_account"].pressed.connect(_on_delete_account_pressed)
	if _nodes["btn_rename_account"]:
		_nodes["btn_rename_account"].pressed.connect(_on_rename_account_pressed)
	if _nodes["server_provider"]:
		_nodes["server_provider"].item_selected.connect(_on_server_provider_changed)
	if _nodes["btn_select_google_key"]:
		_nodes["btn_select_google_key"].pressed.connect(_on_select_google_key_pressed)
	if _nodes["btn_select_apple_key"]:
		_nodes["btn_select_apple_key"].pressed.connect(_on_select_apple_key_pressed)
	if _nodes["btn_save_config"]:
		_nodes["btn_save_config"].pressed.connect(_on_save_config_pressed)
	if _nodes["btn_load_config"]:
		_nodes["btn_load_config"].pressed.connect(_on_load_config_pressed)
	if _nodes["btn_test_connection"]:
		_nodes["btn_test_connection"].pressed.connect(_on_test_connection_pressed)
	
	if _nodes["verify_provider_option"]:
		_nodes["verify_provider_option"].item_selected.connect(_on_verify_provider_changed)
	if _nodes["btn_simulate_verify"]:
		_nodes["btn_simulate_verify"].pressed.connect(_on_simulate_verify_pressed)
	if _nodes["btn_clear_response"]:
		_nodes["btn_clear_response"].pressed.connect(_on_clear_response_pressed)
	
	if _nodes["input_dialog"]:
		_nodes["input_dialog"].confirmed.connect(_on_input_dialog_confirmed)
	if _nodes["confirm_dialog"]:
		_nodes["confirm_dialog"].confirmed.connect(_on_confirm_dialog_confirmed)
		_nodes["confirm_dialog"].canceled.connect(_on_confirm_dialog_canceled)
	
	if _nodes["status_timer"]:
		_nodes["status_timer"].timeout.connect(_on_status_timer_timeout)
	
	if _nodes["key_file_dialog"]:
		_nodes["key_file_dialog"].file_selected.connect(_on_key_file_selected)
	
	if _nodes["report_platform_selector"]:
		_nodes["report_platform_selector"].item_selected.connect(_on_report_platform_changed)
	if _nodes["btn_test_report_connection"]:
		_nodes["btn_test_report_connection"].pressed.connect(_on_test_report_connection)
	if _nodes["btn_select_apple_report_key"]:
		_nodes["btn_select_apple_report_key"].pressed.connect(_on_select_apple_report_key)
	if _nodes["btn_select_google_report_key"]:
		_nodes["btn_select_google_report_key"].pressed.connect(_on_select_google_report_key)
	if _nodes["report_type_selector"]:
		_nodes["report_type_selector"].item_selected.connect(_on_report_type_changed)
	if _nodes["date_range_selector"]:
		_nodes["date_range_selector"].item_selected.connect(_on_date_range_changed)
	if _nodes["btn_query_reports"]:
		_nodes["btn_query_reports"].pressed.connect(_on_query_reports)
	if _nodes["report_tree"]:
		_nodes["report_tree"].item_selected.connect(_on_report_tree_item_selected)
	if _nodes["btn_download_report"]:
		_nodes["btn_download_report"].pressed.connect(_on_download_report)
	if _nodes["btn_open_report_folder"]:
		_nodes["btn_open_report_folder"].pressed.connect(_on_open_report_folder)
	if _nodes["report_file_dialog"]:
		_nodes["report_file_dialog"].file_selected.connect(_on_report_file_selected)

func _apply_localization() -> void:
	_setup_provider_options()
	_setup_environment_options()
	_setup_verify_provider_option()
	
	if _nodes["title_label"]:
		_nodes["title_label"].text = _t("common.title")
	
	if _nodes["title2"]:
		_nodes["title2"].text = _t("module2.title")
	if _nodes["module2_info"]:
		_nodes["module2_info"].text = _t("module2.description")
	if _nodes["label2_1"]:
		_nodes["label2_1"].text = _t("module2.label.environment")
	if _nodes["btn_init_billing"]:
		_nodes["btn_init_billing"].text = _t("module2.btn.init")
	if _nodes["btn_refresh_billing"]:
		_nodes["btn_refresh_billing"].text = _t("module2.btn.refresh")
	if _nodes["btn_close_billing"]:
		_nodes["btn_close_billing"].text = _t("module2.btn.close")
	if _nodes["service_status_label"]:
		_nodes["service_status_label"].text = _t("module2.status.not_initialized")
	
	if _nodes["title3"]:
		_nodes["title3"].text = _t("module3.title")
	if _nodes["module3_info"]:
		_nodes["module3_info"].text = _t("module3.description")
	if _nodes["filter_label"]:
		_nodes["filter_label"].text = _t("module3.label.provider_filter")
	if _nodes["show_inactive_checkbox"]:
		_nodes["show_inactive_checkbox"].text = _t("module3.checkbox.show_inactive")
	if _nodes["debug_mode_checkbox"]:
		_nodes["debug_mode_checkbox"].text = _t("module3.checkbox.debug_mode")
	if _nodes["btn_manual_sync"]:
		_nodes["btn_manual_sync"].text = _t("module3.btn.sync")
	if _nodes["label3_1"]:
		_nodes["label3_1"].text = _t("module3.label.sku_id")
	if _nodes["sku_id_edit"]:
		_nodes["sku_id_edit"].placeholder_text = _t("module3.placeholder.sku_id")
	if _nodes["label3_2"]:
		_nodes["label3_2"].text = _t("module3.label.sku_name")
	if _nodes["sku_name_edit"]:
		_nodes["sku_name_edit"].placeholder_text = _t("module3.placeholder.sku_name")
	if _nodes["label3_3"]:
		_nodes["label3_3"].text = _t("module3.label.sku_price")
	if _nodes["sku_price_edit"]:
		_nodes["sku_price_edit"].placeholder_text = _t("module3.placeholder.sku_price")
	if _nodes["label3_4"]:
		_nodes["label3_4"].text = _t("module3.label.provider")
	if _nodes["btn_add_sku"]:
		_nodes["btn_add_sku"].text = _t("module3.btn.add_sku")
	if _nodes["btn_edit_sku"]:
		_nodes["btn_edit_sku"].text = _t("module3.btn.edit_sku")
	if _nodes["btn_update_sku"]:
		_nodes["btn_update_sku"].text = _t("module3.btn.update_sku")
	if _nodes["btn_deactivate_sku"]:
		_nodes["btn_deactivate_sku"].text = _t("module3.btn.deactivate")
	if _nodes["btn_activate_sku"]:
		_nodes["btn_activate_sku"].text = _t("module3.btn.activate")
	if _nodes["btn_import_json"]:
		_nodes["btn_import_json"].text = _t("module3.btn.import_json")
	if _nodes["btn_export_json"]:
		_nodes["btn_export_json"].text = _t("module3.btn.export_json")
	if _nodes["btn_import_csv"]:
		_nodes["btn_import_csv"].text = _t("module3.btn.import_csv")
	if _nodes["btn_export_csv"]:
		_nodes["btn_export_csv"].text = _t("module3.btn.export_csv")
	if _nodes["btn_add_new_sku"]:
		_nodes["btn_add_new_sku"].text = _t("module3.btn.add_new")
	if _nodes["btn_delete_sku"]:
		_nodes["btn_delete_sku"].text = _t("module3.btn.delete")
	if _nodes["btn_clear_list"]:
		_nodes["btn_clear_list"].text = _t("module3.btn.clear_list")
	
	_setup_sku_tree()
	
	if _nodes["title4"]:
		_nodes["title4"].text = _t("module4.title")
	if _nodes["module4_info"]:
		_nodes["module4_info"].text = _t("module4.description")
	if _nodes["btn_simulate_success"]:
		_nodes["btn_simulate_success"].text = _t("module4.btn.success")
	if _nodes["btn_simulate_no_stock"]:
		_nodes["btn_simulate_no_stock"].text = _t("module4.btn.no_stock")
	if _nodes["btn_simulate_cancel"]:
		_nodes["btn_simulate_cancel"].text = _t("module4.btn.cancel")
	if _nodes["btn_reset_test"]:
		_nodes["btn_reset_test"].text = _t("module4.btn.reset")
	if _nodes["debug_checkbox"]:
		_nodes["debug_checkbox"].text = _t("module4.checkbox.debug_mode")
	
	if _nodes["title5"]:
		_nodes["title5"].text = _t("module5.title")
	if _nodes["module5_info"]:
		_nodes["module5_info"].text = _t("module5.description")
	if _nodes["btn_clear_log"]:
		_nodes["btn_clear_log"].text = _t("module5.btn.clear_log")
	if _nodes["btn_export_log"]:
		_nodes["btn_export_log"].text = _t("module5.btn.export_log")
	
	if _nodes["title6"]:
		_nodes["title6"].text = _t("module6.title")
	if _nodes["module6_info"]:
		_nodes["module6_info"].text = _t("module6.description")
	if _nodes["account_label"]:
		_nodes["account_label"].text = _t("module6.label.account")
	if _nodes["btn_new_account"]:
		_nodes["btn_new_account"].text = _t("module6.btn.new_account")
	if _nodes["btn_save_account"]:
		_nodes["btn_save_account"].text = _t("module6.btn.save_account")
	if _nodes["btn_delete_account"]:
		_nodes["btn_delete_account"].text = _t("module6.btn.delete_account")
	if _nodes["btn_rename_account"]:
		_nodes["btn_rename_account"].text = _t("module6.btn.rename_account")
	if _nodes["label6_1"]:
		_nodes["label6_1"].text = _t("module6.label.provider")
	if _nodes["label6_2"]:
		_nodes["label6_2"].text = _t("module6.label.environment")
	
	if _nodes["google_key_label"]:
		_nodes["google_key_label"].text = _t("module6.google.label.key_file")
	if _nodes["btn_select_google_key"]:
		_nodes["btn_select_google_key"].text = _t("module6.btn.select")
	if _nodes["google_package_label"]:
		_nodes["google_package_label"].text = _t("module6.google.label.package")
	if _nodes["google_package_name"]:
		_nodes["google_package_name"].placeholder_text = _t("module6.google.placeholder.package")
	
	if _nodes["apple_issuer_label"]:
		_nodes["apple_issuer_label"].text = _t("module6.apple.label.issuer_id")
	if _nodes["apple_key_label"]:
		_nodes["apple_key_label"].text = _t("module6.apple.label.key_id")
	if _nodes["apple_bundle_label"]:
		_nodes["apple_bundle_label"].text = _t("module6.apple.label.bundle_id")
	if _nodes["apple_keyfile_label"]:
		_nodes["apple_keyfile_label"].text = _t("module6.apple.label.key_file")
	if _nodes["btn_select_apple_key"]:
		_nodes["btn_select_apple_key"].text = _t("module6.btn.select")
	
	if _nodes["huawei_api_label"]:
		_nodes["huawei_api_label"].text = _t("module6.huawei.label.api_key")
	if _nodes["huawei_app_label"]:
		_nodes["huawei_app_label"].text = _t("module6.huawei.label.app_id")
	
	if _nodes["btn_save_config"]:
		_nodes["btn_save_config"].text = _t("module6.btn.save_config")
	if _nodes["btn_load_config"]:
		_nodes["btn_load_config"].text = _t("module6.btn.load_config")
	if _nodes["btn_test_connection"]:
		_nodes["btn_test_connection"].text = _t("module6.btn.test_connection")
	if _nodes["config_status_label"]:
		_nodes["config_status_label"].text = _t("module6.status.ready")
	
	if _nodes["title7"]:
		_nodes["title7"].text = _t("module7.title")
	if _nodes["module7_info"]:
		_nodes["module7_info"].text = _t("module7.description")
	if _nodes["verify_provider_label"]:
		_nodes["verify_provider_label"].text = _t("module7.label.provider")
	
	if _nodes["google_product_label"]:
		_nodes["google_product_label"].text = _t("module7.google.label.product_id")
	if _nodes["google_token_label"]:
		_nodes["google_token_label"].text = _t("module7.google.label.token")
	if _nodes["google_order_label"]:
		_nodes["google_order_label"].text = _t("module7.google.label.order_id")
	
	if _nodes["apple_product_label"]:
		_nodes["apple_product_label"].text = _t("module7.apple.label.product_id")
	if _nodes["apple_transaction_label"]:
		_nodes["apple_transaction_label"].text = _t("module7.apple.label.transaction_id")
	if _nodes["apple_original_label"]:
		_nodes["apple_original_label"].text = _t("module7.apple.label.original_tx_id")
	
	if _nodes["huawei_product_label"]:
		_nodes["huawei_product_label"].text = _t("module7.huawei.label.product_id")
	if _nodes["huawei_token_label"]:
		_nodes["huawei_token_label"].text = _t("module7.huawei.label.token")
	if _nodes["huawei_purchase_label"]:
		_nodes["huawei_purchase_label"].text = _t("module7.huawei.label.purchase_data")
	
	if _nodes["btn_simulate_verify"]:
		_nodes["btn_simulate_verify"].text = _t("module7.btn.verify")
	if _nodes["btn_clear_response"]:
		_nodes["btn_clear_response"].text = _t("module7.btn.clear")
	if _nodes["response_label"]:
		_nodes["response_label"].text = _t("module7.label.response")
	
	_setup_report_platform_selector()
	_setup_report_type_selector()
	_setup_date_range_selector()
	_setup_report_tree()
	
	if _nodes["title8"]:
		_nodes["title8"].text = _t("module8.title")
	if _nodes["module8_info"]:
		_nodes["module8_info"].text = _t("module8.description")
	if _nodes["platform_label"]:
		_nodes["platform_label"].text = _t("module8.label.platform")
	if _nodes["btn_test_report_connection"]:
		_nodes["btn_test_report_connection"].text = _t("module8.btn.test_connection")
	
	if _nodes["apple_report_issuer_label"]:
		_nodes["apple_report_issuer_label"].text = _t("module8.apple.label.issuer_id")
	if _nodes["apple_report_key_label"]:
		_nodes["apple_report_key_label"].text = _t("module8.apple.label.key_id")
	if _nodes["apple_report_keyfile_label"]:
		_nodes["apple_report_keyfile_label"].text = _t("module8.apple.label.key_file")
	if _nodes["btn_select_apple_report_key"]:
		_nodes["btn_select_apple_report_key"].text = _t("module8.btn.browse")
	if _nodes["apple_vendor_label"]:
		_nodes["apple_vendor_label"].text = _t("module8.apple.label.vendor_number")
	
	if _nodes["google_report_key_label"]:
		_nodes["google_report_key_label"].text = _t("module8.google.label.key_file")
	if _nodes["btn_select_google_report_key"]:
		_nodes["btn_select_google_report_key"].text = _t("module8.btn.browse")
	if _nodes["google_bucket_label"]:
		_nodes["google_bucket_label"].text = _t("module8.google.label.bucket_id")
	if _nodes["google_package_label"]:
		_nodes["google_package_label"].text = _t("module8.google.label.package_name")
	
	if _nodes["huawei_report_client_label"]:
		_nodes["huawei_report_client_label"].text = _t("module8.huawei.label.client_id")
	if _nodes["huawei_report_app_label"]:
		_nodes["huawei_report_app_label"].text = _t("module8.huawei.label.app_id")
	if _nodes["huawei_report_team_label"]:
		_nodes["huawei_report_team_label"].text = _t("module8.huawei.label.team_id")
	
	if _nodes["report_type_label"]:
		_nodes["report_type_label"].text = _t("module8.label.report_type")
	if _nodes["date_range_label"]:
		_nodes["date_range_label"].text = _t("module8.label.date_range")
	if _nodes["start_date_label"]:
		_nodes["start_date_label"].text = _t("module8.label.start_date")
	if _nodes["end_date_label"]:
		_nodes["end_date_label"].text = _t("module8.label.end_date")
	if _nodes["btn_query_reports"]:
		_nodes["btn_query_reports"].text = _t("module8.btn.query")
	if _nodes["preview_label"]:
		_nodes["preview_label"].text = _t("module8.label.preview")
	if _nodes["btn_download_report"]:
		_nodes["btn_download_report"].text = _t("module8.btn.download")
	if _nodes["btn_open_report_folder"]:
		_nodes["btn_open_report_folder"].text = _t("module8.btn.open_folder")
	if _nodes["report_status_label"]:
		_nodes["report_status_label"].text = _t("module8.status.ready")
	
	_refresh_sku_tree()

func _on_language_selected(index: int) -> void:
	current_language = "zh" if index == 0 else "en"
	_save_language_setting()
	_load_language_file(current_language)
	call_deferred("_apply_localization")
	_log_message(_t("common.language_changed"))

func _on_init_billing_pressed() -> void:
	_log_message(_t("module2.log.initializing"))
	_set_service_status(_t("module2.status.initializing"))
	billing_initialized = true
	_set_service_status(_t("module2.status.connected"))

func _on_refresh_billing_pressed() -> void:
	if not billing_initialized:
		_show_message_dialog(_t("module2.message.not_initialized"))
		return
	_log_message(_t("module2.log.refreshing"))

func _on_close_billing_pressed() -> void:
	billing_initialized = false
	_set_service_status(_t("module2.status.not_initialized"))
	_log_message(_t("module2.log.closed"))

func _on_sku_provider_filter_changed(_index: int) -> void:
	_refresh_sku_tree()

func _on_show_inactive_toggled(_pressed: bool) -> void:
	_refresh_sku_tree()

func _on_debug_mode_toggled(pressed: bool) -> void:
	debug_mode = pressed
	_update_button_states()
	if pressed:
		_log_message(_t("module3.log.debug_enabled"))
	else:
		_log_message(_t("module3.log.debug_disabled"))

func _on_manual_sync_pressed() -> void:
	if debug_mode:
		_show_message_dialog(_t("module3.message.sync_disabled_in_debug"))
		return
	var filter_provider: int = 0
	if _nodes["sku_provider_filter"]:
		filter_provider = _nodes["sku_provider_filter"].selected
	var sync_count: int = 0
	var configured_providers: Array = []
	for provider_key: String in PROVIDER_KEYS:
		if _check_provider_configured(provider_key):
			configured_providers.append(provider_key)
	if configured_providers.is_empty():
		_show_message_dialog(_t("module3.message.no_provider_configured"))
		return
	for i: int in sku_database.size():
		var sku: Dictionary = sku_database[i]
		var sku_provider: String = sku.get("provider", PROVIDER_KEYS[0])
		if filter_provider > 0 and sku_provider != PROVIDER_KEYS[filter_provider]:
			continue
		if sku_provider in configured_providers:
			var sync_status: String = sku.get("sync_status", "")
			if sync_status == "pending_sync" or sync_status.is_empty():
				_sync_sku_to_provider(sku, "modify")
				sync_count += 1
	if sync_count > 0:
		_save_sku_database()
		_refresh_sku_tree()
		_log_message(_t("module3.log.sync_submitted").replace("{count}", str(sync_count)))
	else:
		_log_message(_t("module3.log.no_pending"))

func _on_add_sku_pressed() -> void:
	if is_editing_sku:
		_on_cancel_edit_sku()
		return
	var sku_data: Dictionary = _collect_sku_input()
	var validation: Dictionary = _validate_sku_input(sku_data)
	if not validation.valid:
		_show_message_dialog(validation.message)
		return
	var provider: String = sku_data.get("provider", PROVIDER_KEYS[0])
	if not _check_provider_configured(provider):
		if not debug_mode:
			_show_message_dialog(_t("module3.message.provider_not_configured").replace("{provider}", _t("common.provider." + provider)))
			debug_mode = true
			if _nodes["debug_mode_checkbox"]:
				_nodes["debug_mode_checkbox"].button_pressed = true
			_update_button_states()
			_log_message(_t("module3.log.auto_debug_mode"))
			return
	sku_data["status"] = "active"
	sku_data["created_time"] = Time.get_unix_time_from_system()
	sku_data["effect_time"] = _get_effect_time_for_provider(provider, "add")
	sku_database.append(sku_data)
	_sync_sku_to_provider(sku_data, "add")
	_save_sku_database()
	_refresh_sku_tree()
	_clear_sku_inputs()
	_log_message(_t("module3.log.sku_added"))

func _on_edit_sku_pressed() -> void:
	var index: int = _get_selected_sku_index()
	if index < 0:
		_show_message_dialog(_t("module3.message.select_sku"))
		return
	if index >= sku_database.size():
		return
	var sku: Dictionary = sku_database[index]
	if _nodes["sku_id_edit"]:
		_nodes["sku_id_edit"].text = sku.get("sku_id", "")
		_nodes["sku_id_edit"].editable = false
	if _nodes["sku_name_edit"]:
		_nodes["sku_name_edit"].text = sku.get("sku_name", "")
	if _nodes["sku_price_edit"]:
		_nodes["sku_price_edit"].text = str(sku.get("sku_price", ""))
	if _nodes["sku_provider_option"] and _nodes["sku_provider_option"].item_count > 0:
		var provider_key: String = sku.get("provider", PROVIDER_KEYS[0])
		for i: int in PROVIDER_KEYS.size():
			if PROVIDER_KEYS[i] == provider_key:
				if i < _nodes["sku_provider_option"].item_count:
					_nodes["sku_provider_option"].select(i)
				break
	is_editing_sku = true
	editing_sku_index = index
	_update_button_states()
	_log_message(_t("module3.log.editing_sku"))

func _on_update_sku_pressed() -> void:
	if not is_editing_sku or editing_sku_index < 0:
		return
	if editing_sku_index >= sku_database.size():
		return
	var old_sku: Dictionary = sku_database[editing_sku_index]
	var new_data: Dictionary = _collect_sku_input()
	var validation: Dictionary = _validate_sku_input(new_data)
	if not validation.valid:
		_show_message_dialog(validation.message)
		return
	var provider: String = old_sku.get("provider", PROVIDER_KEYS[0])
	var rules: Dictionary = _get_provider_rules(provider)
	var pending_fields: Dictionary = {}
	if not debug_mode:
		if rules.name_modify_needs_approval and old_sku.get("sku_name", "") != new_data.get("sku_name", ""):
			pending_fields["sku_name"] = new_data.get("sku_name", "")
		if rules.price_modify_needs_approval and old_sku.get("sku_price", 0.0) != new_data.get("sku_price", 0.0):
			pending_fields["sku_price"] = new_data.get("sku_price", 0.0)
	if pending_fields.is_empty() or debug_mode:
		old_sku["sku_name"] = new_data.get("sku_name", "")
		old_sku["sku_price"] = new_data.get("sku_price", 0.0)
		old_sku["status"] = "active"
		old_sku["modified_time"] = Time.get_unix_time_from_system()
		old_sku["effect_time"] = _get_effect_time_for_provider(provider, "modify")
		_sync_sku_to_provider(old_sku, "modify")
		_log_message(_t("module3.log.sku_updated"))
	else:
		old_sku["pending_fields"] = pending_fields
		old_sku["pending_until"] = Time.get_unix_time_from_system() + (rules.approval_hours * 3600)
		old_sku["status"] = "pending"
		old_sku["effect_time"] = _get_effect_time_for_provider(provider, "modify")
		_log_message(_t("module3.log.sku_pending"))
	_save_sku_database()
	_refresh_sku_tree()
	_on_cancel_edit_sku()

func _on_cancel_edit_sku() -> void:
	is_editing_sku = false
	editing_sku_index = -1
	_clear_sku_inputs()
	_update_button_states()
	_log_message(_t("module3.log.edit_cancelled"))

func _on_deactivate_sku_pressed() -> void:
	var index: int = _get_selected_sku_index()
	if index < 0:
		_show_message_dialog(_t("module3.message.select_sku"))
		return
	if index >= sku_database.size():
		return
	var sku: Dictionary = sku_database[index]
	sku["status"] = "inactive"
	sku["effect_time"] = _get_effect_time_for_provider(sku.get("provider", PROVIDER_KEYS[0]), "deactivate")
	_sync_sku_to_provider(sku, "deactivate")
	_save_sku_database()
	_refresh_sku_tree()
	_log_message(_t("module3.log.sku_deactivated"))

func _on_activate_sku_pressed() -> void:
	var index: int = _get_selected_sku_index()
	if index < 0:
		_show_message_dialog(_t("module3.message.select_sku"))
		return
	if index >= sku_database.size():
		return
	var sku: Dictionary = sku_database[index]
	var provider: String = sku.get("provider", PROVIDER_KEYS[0])
	var rules: Dictionary = _get_provider_rules(provider)
	if rules.reactivate_needs_approval and not debug_mode:
		sku["status"] = "pending"
		sku["pending_until"] = Time.get_unix_time_from_system() + (rules.approval_hours * 3600)
		sku["effect_time"] = _get_effect_time_for_provider(provider, "activate")
		_log_message(_t("module3.log.sku_reactivate_pending"))
	else:
		sku["status"] = "active"
		sku["effect_time"] = _get_effect_time_for_provider(provider, "activate")
		_sync_sku_to_provider(sku, "activate")
		_log_message(_t("module3.log.sku_activated"))
	_save_sku_database()
	_refresh_sku_tree()

func _on_import_json_pressed() -> void:
	_show_file_dialog("json", false)

func _on_export_json_pressed() -> void:
	_show_file_dialog("json", true)

func _on_import_csv_pressed() -> void:
	_show_file_dialog("csv", false)

func _on_export_csv_pressed() -> void:
	_show_file_dialog("csv", true)

func _show_file_dialog(file_type: String, is_save: bool) -> void:
	if file_dialog == null:
		file_dialog = FileDialog.new()
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.use_native_dialog = true
		add_child(file_dialog)
		file_dialog.file_selected.connect(_on_file_selected)
		file_dialog.files_selected.connect(_on_files_selected)
	file_dialog.clear_filters()
	if file_type == "json":
		file_dialog.add_filter("*.json", "JSON Files")
	else:
		file_dialog.add_filter("*.csv", "CSV Files")
	if is_save:
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		file_dialog.title = _t("module3.dialog.save_file")
		file_dialog.current_file = "sku_database." + file_type
	else:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.title = _t("module3.dialog.open_file")
	file_dialog.set_meta("file_type", file_type)
	file_dialog.set_meta("is_save", is_save)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String) -> void:
	var file_type: String = file_dialog.get_meta("file_type", "json")
	var is_save: bool = file_dialog.get_meta("is_save", false)
	if is_save:
		if file_type == "json":
			_export_json_file(path)
		else:
			_export_csv_file(path)
	else:
		if file_type == "json":
			_import_json_file(path)
		else:
			_import_csv_file(path)

func _on_files_selected(paths: PackedStringArray) -> void:
	if paths.size() > 0:
		_on_file_selected(paths[0])

func _import_json_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		_show_message_dialog(_t("module3.error.file_open"))
		return
	var json_string: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(json_string) != OK:
		_show_message_dialog(_t("module3.error.json_parse"))
		return
	var data: Variant = json.data
	var import_count: int = 0
	if data is Array:
		for item: Variant in data:
			if item is Dictionary:
				var sku: Dictionary = _normalize_sku_data(item)
				sku_database.append(sku)
				import_count += 1
	elif data is Dictionary:
		if data.has("products"):
			var products: Variant = data.get("products")
			if products is Array:
				for item: Variant in products:
					if item is Dictionary:
						var sku: Dictionary = _normalize_sku_data(item)
						sku_database.append(sku)
						import_count += 1
		elif data.has("inappproducts"):
			var products: Variant = data.get("inappproducts")
			if products is Array:
				for item: Variant in products:
					if item is Dictionary:
						var sku: Dictionary = _normalize_google_format(item)
						sku_database.append(sku)
						import_count += 1
	_save_sku_database()
	_refresh_sku_tree()
	_log_message(_t("module3.log.import_success").replace("{count}", str(import_count)))

func _normalize_sku_data(data: Dictionary) -> Dictionary:
	return {
		"sku_id": data.get("sku_id", data.get("id", "")),
		"sku_name": data.get("sku_name", data.get("name", "")),
		"sku_price": data.get("sku_price", data.get("price", 0.0)),
		"sku_type": data.get("sku_type", data.get("type", SKU_TYPE_KEYS[0])),
		"provider": data.get("provider", PROVIDER_KEYS[0]),
		"status": data.get("status", "active")
	}

func _normalize_google_format(data: Dictionary) -> Dictionary:
	var sku: Dictionary = {
		"sku_id": data.get("sku", ""),
		"sku_name": data.get("title", ""),
		"sku_price": 0.0,
		"sku_type": SKU_TYPE_KEYS[0],
		"provider": "google",
		"status": "active"
	}
	if data.has("defaultPrice"):
		var price_info: Dictionary = data.get("defaultPrice", {})
		sku["sku_price"] = price_info.get("priceMicros", 0) / 1000000.0
	return sku

func _export_json_file(path: String) -> void:
	var export_data: Array = []
	for sku: Dictionary in sku_database:
		export_data.append(sku.duplicate())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		_show_message_dialog(_t("module3.error.file_save"))
		return
	file.store_string(JSON.stringify(export_data, "  "))
	file.close()
	_log_message(_t("module3.log.export_success"))

func _import_csv_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		_show_message_dialog(_t("module3.error.file_open"))
		return
	var content: String = file.get_as_text()
	file.close()
	var lines: PackedStringArray = content.split("\n")
	if lines.size() < 2:
		_show_message_dialog(_t("module3.error.csv_empty"))
		return
	var headers: PackedStringArray = lines[0].split(",")
	var import_count: int = 0
	for i: int in range(1, lines.size()):
		var line: String = lines[i].strip_edges()
		if line.is_empty():
			continue
		var values: PackedStringArray = _parse_csv_line(line)
		if values.size() < 3:
			continue
		var sku: Dictionary = {}
		for j: int in headers.size():
			if j < values.size():
				var header: String = headers[j].strip_edges().to_lower()
				var value: String = values[j].strip_edges()
				match header:
					"sku_id", "id", "product_id":
						sku["sku_id"] = value
					"sku_name", "name", "title":
						sku["sku_name"] = value
					"sku_price", "price":
						sku["sku_price"] = value.to_float()
					"sku_type", "type":
						if value in SKU_TYPE_KEYS:
							sku["sku_type"] = value
						else:
							sku["sku_type"] = SKU_TYPE_KEYS[0]
					"provider":
						if value in PROVIDER_KEYS:
							sku["provider"] = value
						else:
							sku["provider"] = PROVIDER_KEYS[0]
		if sku.has("sku_id") and not sku.get("sku_id", "").is_empty():
			if not sku.has("sku_type"):
				sku["sku_type"] = SKU_TYPE_KEYS[0]
			if not sku.has("provider"):
				sku["provider"] = PROVIDER_KEYS[0]
			sku["status"] = "active"
			sku_database.append(sku)
			import_count += 1
	_save_sku_database()
	_refresh_sku_tree()
	_log_message(_t("module3.log.import_success").replace("{count}", str(import_count)))

func _parse_csv_line(line: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var current: String = ""
	var in_quotes: bool = false
	for i: int in line.length():
		var c: String = line[i]
		if c == "\"":
			in_quotes = not in_quotes
		elif c == "," and not in_quotes:
			result.append(current)
			current = ""
		else:
			current += c
	result.append(current)
	return result

func _export_csv_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		_show_message_dialog(_t("module3.error.file_save"))
		return
	file.store_line("sku_id,sku_name,sku_price,sku_type,provider,status")
	for sku: Dictionary in sku_database:
		var line: String = "%s,%s,%s,%s,%s,%s" % [
			sku.get("sku_id", ""),
			sku.get("sku_name", ""),
			str(sku.get("sku_price", 0.0)),
			sku.get("sku_type", SKU_TYPE_KEYS[0]),
			sku.get("provider", PROVIDER_KEYS[0]),
			sku.get("status", "active")
		]
		file.store_line(line)
	file.close()
	_log_message(_t("module3.log.export_success"))

func _on_add_new_sku_pressed() -> void:
	_on_cancel_edit_sku()
	_clear_sku_inputs()
	if _nodes["sku_id_edit"]:
		_nodes["sku_id_edit"].grab_focus()

func _on_delete_sku_pressed() -> void:
	var index: int = _get_selected_sku_index()
	if index < 0:
		_show_message_dialog(_t("module3.message.select_sku"))
		return
	if not debug_mode:
		_show_message_dialog(_t("module3.message.delete_disabled"))
		return
	pending_dialog_action = "delete_sku"
	_show_confirm_dialog(_t("module3.confirm.delete_sku"))

func _on_clear_list_pressed() -> void:
	pending_dialog_action = "clear_list"
	_show_confirm_dialog(_t("module3.confirm.clear_list"))

func _on_sku_tree_item_selected() -> void:
	_update_button_states()

func _can_delete_sku() -> bool:
	return debug_mode and _get_selected_sku_index() >= 0

func _update_button_states() -> void:
	var has_selection: bool = _get_selected_sku_index() >= 0
	var selected_index: int = _get_selected_sku_index()
	var is_inactive: bool = false
	var is_pending: bool = false
	if selected_index >= 0 and selected_index < sku_database.size():
		var status: String = sku_database[selected_index].get("status", "active")
		is_inactive = (status == "inactive")
		is_pending = (status == "pending")
	if _nodes["btn_add_sku"]:
		_nodes["btn_add_sku"].visible = not is_editing_sku
		_nodes["btn_add_sku"].disabled = is_editing_sku
	if _nodes["btn_edit_sku"]:
		_nodes["btn_edit_sku"].visible = not is_editing_sku
		_nodes["btn_edit_sku"].disabled = not has_selection or is_editing_sku
	if _nodes["btn_update_sku"]:
		_nodes["btn_update_sku"].visible = is_editing_sku
		_nodes["btn_update_sku"].disabled = not is_editing_sku
	if _nodes["btn_deactivate_sku"]:
		_nodes["btn_deactivate_sku"].disabled = not has_selection or is_editing_sku or is_inactive
	if _nodes["btn_activate_sku"]:
		_nodes["btn_activate_sku"].disabled = not has_selection or is_editing_sku or not is_inactive
	if _nodes["btn_delete_sku"]:
		_nodes["btn_delete_sku"].visible = debug_mode
		_nodes["btn_delete_sku"].disabled = not has_selection or not debug_mode
	if _nodes["btn_clear_list"]:
		_nodes["btn_clear_list"].disabled = sku_database.is_empty()
	if _nodes["btn_import_json"]:
		_nodes["btn_import_json"].disabled = is_editing_sku
	if _nodes["btn_import_csv"]:
		_nodes["btn_import_csv"].disabled = is_editing_sku
	if _nodes["btn_export_json"]:
		_nodes["btn_export_json"].disabled = is_editing_sku or sku_database.is_empty()
	if _nodes["btn_export_csv"]:
		_nodes["btn_export_csv"].disabled = is_editing_sku or sku_database.is_empty()
	if _nodes["btn_manual_sync"]:
		_nodes["btn_manual_sync"].disabled = debug_mode or sku_database.is_empty()

func _on_simulate_success_pressed() -> void:
	_log_message(_t("module4.log.simulate_success"))

func _on_simulate_no_stock_pressed() -> void:
	_log_message(_t("module4.log.simulate_no_stock"))

func _on_simulate_cancel_pressed() -> void:
	_log_message(_t("module4.log.simulate_cancel"))

func _on_reset_test_pressed() -> void:
	_log_message(_t("module4.log.reset"))

func _on_clear_log_pressed() -> void:
	if _nodes["log_text"]:
		_nodes["log_text"].text = ""

func _on_export_log_pressed() -> void:
	_log_message(_t("module5.log.export"))

func _on_account_selected(_index: int) -> void:
	if not _nodes["account_selector"]:
		return
	if _nodes["account_selector"].item_count == 0:
		return
	var selected_idx: int = _nodes["account_selector"].selected
	if selected_idx < 0 or selected_idx >= _nodes["account_selector"].item_count:
		return
	var account_name: String = _nodes["account_selector"].get_item_text(selected_idx)
	if account_name.is_empty():
		return
	current_user = account_name
	_load_user_config(current_user)
	_log_message(_t("module6.log.account_switched") + current_user)

func _on_new_account_pressed() -> void:
	pending_dialog_action = "new_account"
	_show_input_dialog(_t("module6.dialog.new_account"))

func _on_save_account_pressed() -> void:
	if current_user.is_empty():
		_show_message_dialog(_t("module6.message.no_account"))
		return
	var config: Dictionary = _collect_server_config()
	var validation: Dictionary = _validate_server_config(config)
	if not validation.valid:
		_show_message_dialog(validation.message)
		return
	_save_user_config(current_user, config)
	_log_message(_t("module6.log.config_saved"))

func _on_delete_account_pressed() -> void:
	if current_user.is_empty():
		_show_message_dialog(_t("module6.message.no_account"))
		return
	pending_dialog_action = "delete_account"
	pending_dialog_data["account_name"] = current_user
	_show_confirm_dialog(_t("module6.confirm.delete_account"))

func _on_rename_account_pressed() -> void:
	if current_user.is_empty():
		_show_message_dialog(_t("module6.message.no_account"))
		return
	pending_dialog_action = "rename_account"
	pending_dialog_data["old_name"] = current_user
	_show_input_dialog(_t("module6.dialog.rename_account"))

func _on_server_provider_changed(_index: int) -> void:
	_update_provider_config_visibility()

func _on_select_google_key_pressed() -> void:
	pending_dialog_action = "select_google_key"
	if _nodes["key_file_dialog"]:
		_nodes["key_file_dialog"].title = _t("module6.google.label.key_file")
		_nodes["key_file_dialog"].filters = PackedStringArray(["*.json ; JSON Files"])
		_nodes["key_file_dialog"].popup_file_dialog()

func _on_select_apple_key_pressed() -> void:
	pending_dialog_action = "select_apple_key"
	if _nodes["key_file_dialog"]:
		_nodes["key_file_dialog"].title = _t("module6.apple.label.key_file")
		_nodes["key_file_dialog"].filters = PackedStringArray(["*.p8 ; P8 Files", "*.pem ; PEM Files"])
		_nodes["key_file_dialog"].popup_file_dialog()

func _on_key_file_selected(path: String) -> void:
	if pending_dialog_action == "select_google_key":
		if _nodes["google_key_path"]:
			_nodes["google_key_path"].text = path
		_log_message(_t("module6.google.label.key_file") + ": " + path)
	elif pending_dialog_action == "select_apple_key":
		if _nodes["apple_key_path"]:
			_nodes["apple_key_path"].text = path
		_log_message(_t("module6.apple.label.key_file") + ": " + path)
	elif pending_dialog_action == "select_apple_report_key":
		if _nodes["apple_report_key_path"]:
			_nodes["apple_report_key_path"].text = path
		_log_message(_t("module8.apple.label.key_file") + ": " + path)
	elif pending_dialog_action == "select_google_report_key":
		if _nodes["google_report_key_path"]:
			_nodes["google_report_key_path"].text = path
		_log_message(_t("module8.google.label.key_file") + ": " + path)
	pending_dialog_action = ""

func _on_save_config_pressed() -> void:
	_on_save_account_pressed()

func _on_load_config_pressed() -> void:
	if current_user.is_empty():
		_show_message_dialog(_t("module6.message.no_account"))
		return
	_load_user_config(current_user)
	_log_message(_t("module6.log.config_loaded"))

func _on_test_connection_pressed() -> void:
	if current_user.is_empty():
		_show_message_dialog(_t("module6.message.no_account"))
		return
	var config: Dictionary = _collect_server_config()
	var validation: Dictionary = _validate_server_config(config)
	if not validation.valid:
		_show_message_dialog(validation.message)
		return
	_set_config_status(_t("module6.status.testing"))
	_log_message(_t("module6.log.testing_connection"))
	_set_config_status(_t("module6.status.connected"))

func _on_verify_provider_changed(_index: int) -> void:
	_update_verify_provider_visibility()

func _on_simulate_verify_pressed() -> void:
	var provider_index: int = 0
	if _nodes["verify_provider_option"]:
		provider_index = _nodes["verify_provider_option"].selected
	var provider_key: String = PROVIDER_KEYS[provider_index]
	var response: String = ""
	match provider_key:
		"google":
			response = _simulate_google_verify()
		"apple":
			response = _simulate_apple_verify()
		"huawei":
			response = _simulate_huawei_verify()
	if _nodes["response_text"]:
		_nodes["response_text"].text = response
	_log_message(_t("module7.log.verify_completed"))

func _on_clear_response_pressed() -> void:
	if _nodes["response_text"]:
		_nodes["response_text"].text = ""

func _on_input_dialog_confirmed() -> void:
	var input_value: String = ""
	if _nodes["input_field"]:
		input_value = _nodes["input_field"].text.strip_edges()
	match pending_dialog_action:
		"new_account":
			if input_value.is_empty():
				_show_message_dialog(_t("module6.message.empty_name"))
				return
			if user_configs.has(input_value):
				_show_message_dialog(_t("module6.message.account_exists"))
				return
			_create_new_user(input_value)
		"rename_account":
			if input_value.is_empty():
				_show_message_dialog(_t("module6.message.empty_name"))
				return
			var old_name: String = pending_dialog_data.get("old_name", "")
			_rename_user(old_name, input_value)
	if _nodes["input_field"]:
		_nodes["input_field"].text = ""
	pending_dialog_action = ""
	pending_dialog_data.clear()

func _on_confirm_dialog_confirmed() -> void:
	match pending_dialog_action:
		"delete_sku":
			_delete_selected_sku()
		"clear_list":
			_clear_all_sku()
		"delete_account":
			var account_name: String = pending_dialog_data.get("account_name", "")
			_delete_user(account_name)
	pending_dialog_action = ""
	pending_dialog_data.clear()

func _on_confirm_dialog_canceled() -> void:
	pending_dialog_action = ""
	pending_dialog_data.clear()

func _on_status_timer_timeout() -> void:
	pass

func _collect_sku_input() -> Dictionary:
	var data: Dictionary = {}
	if _nodes["sku_id_edit"]:
		data["sku_id"] = _nodes["sku_id_edit"].text.strip_edges()
	if _nodes["sku_name_edit"]:
		data["sku_name"] = _nodes["sku_name_edit"].text.strip_edges()
	if _nodes["sku_price_edit"]:
		data["sku_price"] = _nodes["sku_price_edit"].text.strip_edges().to_float()
	if _nodes["sku_provider_option"]:
		data["provider"] = PROVIDER_KEYS[_nodes["sku_provider_option"].selected]
	data["sku_type"] = SKU_TYPE_KEYS[0]
	return data

func _validate_sku_input(data: Dictionary) -> Dictionary:
	var result: Dictionary = {"valid": true, "message": ""}
	if data.get("sku_id", "").is_empty():
		result.valid = false
		result.message = _t("module3.message.empty_sku_id")
		return result
	if data.get("sku_name", "").is_empty():
		result.valid = false
		result.message = _t("module3.message.empty_sku_name")
		return result
	if not is_editing_sku:
		for sku: Dictionary in sku_database:
			if sku.get("sku_id", "") == data.get("sku_id", ""):
				result.valid = false
				result.message = _t("module3.message.duplicate_sku_id")
				return result
	return result

func _collect_server_config() -> Dictionary:
	var config: Dictionary = {}
	if _nodes["server_provider"]:
		config["provider"] = PROVIDER_KEYS[_nodes["server_provider"].selected]
	if _nodes["server_env"]:
		config["environment"] = ENVIRONMENT_KEYS[_nodes["server_env"].selected]
	if _nodes["google_key_path"]:
		config["google_key_path"] = _nodes["google_key_path"].text
	if _nodes["google_package_name"]:
		config["google_package_name"] = _nodes["google_package_name"].text
	if _nodes["apple_issuer_id"]:
		config["apple_issuer_id"] = _nodes["apple_issuer_id"].text
	if _nodes["apple_key_id"]:
		config["apple_key_id"] = _nodes["apple_key_id"].text
	if _nodes["apple_bundle_id"]:
		config["apple_bundle_id"] = _nodes["apple_bundle_id"].text
	if _nodes["apple_key_path"]:
		config["apple_key_path"] = _nodes["apple_key_path"].text
	if _nodes["huawei_api_key"]:
		config["huawei_api_key"] = _nodes["huawei_api_key"].text
	if _nodes["huawei_app_id"]:
		config["huawei_app_id"] = _nodes["huawei_app_id"].text
	return config

func _validate_server_config(config: Dictionary) -> Dictionary:
	var result: Dictionary = {"valid": true, "message": ""}
	var provider_key: String = config.get("provider", PROVIDER_KEYS[0])
	match provider_key:
		"google":
			if config.get("google_key_path", "").is_empty():
				result.valid = false
				result.message = _t("module6.message.empty_key_file")
				return result
			if config.get("google_package_name", "").is_empty():
				result.valid = false
				result.message = _t("module6.message.empty_package")
				return result
		"apple":
			if config.get("apple_issuer_id", "").is_empty():
				result.valid = false
				result.message = _t("module6.message.empty_issuer_id")
				return result
			if config.get("apple_key_id", "").is_empty():
				result.valid = false
				result.message = _t("module6.message.empty_key_id")
				return result
			if config.get("apple_bundle_id", "").is_empty():
				result.valid = false
				result.message = _t("module6.message.empty_bundle_id")
				return result
		"huawei":
			if config.get("huawei_api_key", "").is_empty():
				result.valid = false
				result.message = _t("module6.message.empty_api_key")
				return result
			if config.get("huawei_app_id", "").is_empty():
				result.valid = false
				result.message = _t("module6.message.empty_app_id")
				return result
	return result

func _refresh_sku_tree() -> void:
	if not _nodes["sku_tree"]:
		return
	_nodes["sku_tree"].clear()
	var root: TreeItem = _nodes["sku_tree"].create_item()
	_nodes["sku_tree"].hide_root = true
	var show_inactive: bool = true
	if _nodes["show_inactive_checkbox"]:
		show_inactive = _nodes["show_inactive_checkbox"].button_pressed
	var filter_provider: int = 0
	if _nodes["sku_provider_filter"]:
		filter_provider = _nodes["sku_provider_filter"].selected
	var provider_groups: Dictionary = {}
	for i: int in sku_database.size():
		var sku: Dictionary = sku_database[i]
		var status: String = sku.get("status", "active")
		if not show_inactive and status == "inactive":
			continue
		if filter_provider > 0:
			var sku_provider_key: String = sku.get("provider", PROVIDER_KEYS[0])
			if sku_provider_key != PROVIDER_KEYS[filter_provider]:
				continue
		var provider_key: String = sku.get("provider", PROVIDER_KEYS[0])
		if not provider_groups.has(provider_key):
			provider_groups[provider_key] = []
		provider_groups[provider_key].append({"index": i, "sku": sku})
	var sorted_providers: Array = provider_groups.keys()
	sorted_providers.sort()
	for provider_key: String in sorted_providers:
		var provider_items: Array = provider_groups[provider_key]
		var provider_item: TreeItem = _nodes["sku_tree"].create_item(root)
		provider_item.set_text(0, _t("common.provider." + provider_key))
		provider_item.set_text(1, "")
		provider_item.set_text(2, "")
		provider_item.set_text(3, "")
		provider_item.set_text(4, "")
		provider_item.set_text(5, "")
		provider_item.set_text(6, "")
		provider_item.set_selectable(0, false)
		provider_item.set_custom_color(0, Color(0.7, 0.7, 0.9))
		provider_item.collapsed = false
		provider_item.set_tooltip_text(0, _t("common.provider." + provider_key))
		for item_data: Dictionary in provider_items:
			var i: int = item_data.index
			var sku: Dictionary = item_data.sku
			var item: TreeItem = _nodes["sku_tree"].create_item(provider_item)
			item.set_text(0, "")
			item.set_text(1, sku.get("sku_id", ""))
			item.set_text(2, sku.get("sku_name", ""))
			item.set_text(3, str(sku.get("sku_price", "")))
			var type_key: String = sku.get("sku_type", SKU_TYPE_KEYS[0])
			item.set_text(4, _t("module3.type." + type_key))
			var status: String = sku.get("status", "active")
			var status_text: String = ""
			match status:
				"active":
					status_text = _t("module3.status.active")
				"inactive":
					status_text = _t("module3.status.inactive")
				"pending":
					var pending_until: int = sku.get("pending_until", 0)
					status_text = _t("module3.status.pending") + " (" + _get_pending_time_text(pending_until) + ")"
			item.set_text(5, status_text)
			var effect_time: String = sku.get("effect_time", "")
			if effect_time.is_empty():
				effect_time = _get_effect_time_display(sku)
			item.set_text(6, effect_time)
			item.set_metadata(0, i)
			item.set_tooltip_text(1, sku.get("sku_id", ""))
			item.set_tooltip_text(2, sku.get("sku_name", ""))
			item.set_tooltip_text(3, str(sku.get("sku_price", "")))
			item.set_tooltip_text(4, _t("module3.type." + type_key))
			item.set_tooltip_text(5, status_text)
			item.set_tooltip_text(6, effect_time)
	_update_button_states()

func _get_effect_time_display(sku: Dictionary) -> String:
	var status: String = sku.get("status", "active")
	var provider: String = sku.get("provider", PROVIDER_KEYS[0])
	var created_time: int = sku.get("created_time", 0)
	var modified_time: int = sku.get("modified_time", 0)
	if created_time == 0:
		return _t("module3.effect_time.immediate")
	match status:
		"active":
			if provider == "google":
				return _t("module3.effect_time.immediate")
			elif provider == "apple":
				return _t("module3.effect_time.hours_24_48")
			elif provider == "huawei":
				return _t("module3.effect_time.hours_2")
		"pending":
			var pending_until: int = sku.get("pending_until", 0)
			if pending_until > 0:
				return _get_pending_time_text(pending_until)
	return _t("module3.effect_time.immediate")

func _get_selected_sku_index() -> int:
	if not _nodes["sku_tree"]:
		return -1
	var selected: TreeItem = _nodes["sku_tree"].get_selected()
	if not selected:
		return -1
	var metadata: Variant = selected.get_metadata(0)
	if metadata is int:
		return metadata
	return -1

func _check_provider_configured(provider: String) -> bool:
	if not user_configs.has(current_user):
		return false
	var config: Dictionary = user_configs[current_user]
	if config.get("provider", "") != provider:
		return false
	match provider:
		"google":
			return not config.get("google_key_path", "").is_empty() and not config.get("google_package_name", "").is_empty()
		"apple":
			return not config.get("apple_issuer_id", "").is_empty() and not config.get("apple_key_id", "").is_empty() and not config.get("apple_bundle_id", "").is_empty()
		"huawei":
			return not config.get("huawei_api_key", "").is_empty() and not config.get("huawei_app_id", "").is_empty()
	return false

func _sync_sku_to_provider(sku: Dictionary, action: String) -> void:
	var provider: String = sku.get("provider", PROVIDER_KEYS[0])
	if not _check_provider_configured(provider):
		_log_message(_t("module3.log.provider_not_configured").replace("{provider}", _t("common.provider." + provider)))
		return
	var sync_status: String = "synced"
	if not debug_mode:
		var rules: Dictionary = _get_provider_rules(provider)
		match action:
			"add":
				sync_status = "synced"
			"modify":
				if rules.name_modify_needs_approval:
					sync_status = "pending_sync"
			"deactivate":
				sync_status = "synced"
			"activate":
				if rules.reactivate_needs_approval:
					sync_status = "pending_sync"
				else:
					sync_status = "synced"
	sku["sync_status"] = sync_status
	sku["last_sync_time"] = Time.get_unix_time_from_system()
	_log_message(_t("module3.log.sync_success").replace("{sku_id}", sku.get("sku_id", "")).replace("{status}", sync_status))

func _get_effect_time_for_provider(provider: String, action: String) -> String:
	match action:
		"add":
			match provider:
				"google":
					return _t("module3.effect_time.immediate")
				"apple":
					return _t("module3.effect_time.hours_24_48")
				"huawei":
					return _t("module3.effect_time.hours_2")
		"modify":
			var rules: Dictionary = _get_provider_rules(provider)
			if rules.name_modify_needs_approval:
				return _t("module3.effect_time.hours_2")
			else:
				return _t("module3.effect_time.immediate")
		"activate":
			var rules: Dictionary = _get_provider_rules(provider)
			if rules.reactivate_needs_approval:
				return _t("module3.effect_time.hours_2")
			else:
				return _t("module3.effect_time.immediate")
		"deactivate":
			return _t("module3.effect_time.immediate")
	return _t("module3.effect_time.immediate")

func _clear_sku_inputs() -> void:
	if _nodes["sku_id_edit"]:
		_nodes["sku_id_edit"].text = ""
		_nodes["sku_id_edit"].editable = true
	if _nodes["sku_name_edit"]:
		_nodes["sku_name_edit"].text = ""
	if _nodes["sku_price_edit"]:
		_nodes["sku_price_edit"].text = ""
	if _nodes["sku_provider_option"] and _nodes["sku_provider_option"].item_count > 0:
		_nodes["sku_provider_option"].select(0)

func _delete_selected_sku() -> void:
	if not _nodes["sku_tree"]:
		return
	var selected: TreeItem = _nodes["sku_tree"].get_selected()
	if not selected:
		return
	var index: int = selected.get_metadata(0)
	if index >= 0 and index < sku_database.size():
		sku_database.remove_at(index)
		_save_sku_database()
		_refresh_sku_tree()
		_log_message(_t("module3.log.sku_deleted"))

func _clear_all_sku() -> void:
	sku_database.clear()
	_save_sku_database()
	_refresh_sku_tree()
	_log_message(_t("module3.log.list_cleared"))

func _update_provider_config_visibility() -> void:
	var provider_index: int = 0
	if _nodes["server_provider"]:
		provider_index = _nodes["server_provider"].selected
	if _nodes["google_config_container"]:
		_nodes["google_config_container"].visible = (provider_index == 0)
	if _nodes["apple_config_container"]:
		_nodes["apple_config_container"].visible = (provider_index == 1)
	if _nodes["huawei_config_container"]:
		_nodes["huawei_config_container"].visible = (provider_index == 2)

func _update_verify_provider_visibility() -> void:
	var provider_index: int = 0
	if _nodes["verify_provider_option"]:
		provider_index = _nodes["verify_provider_option"].selected
	if _nodes["test_google_container"]:
		_nodes["test_google_container"].visible = (provider_index == 0)
	if _nodes["test_apple_container"]:
		_nodes["test_apple_container"].visible = (provider_index == 1)
	if _nodes["test_huawei_container"]:
		_nodes["test_huawei_container"].visible = (provider_index == 2)

func _simulate_google_verify() -> String:
	var product_id: String = ""
	var token: String = ""
	var order_id: String = ""
	if _nodes["google_product_id_edit"]:
		product_id = _nodes["google_product_id_edit"].text.strip_edges()
	if _nodes["google_token_edit"]:
		token = _nodes["google_token_edit"].text.strip_edges()
	if _nodes["google_order_id_edit"]:
		order_id = _nodes["google_order_id_edit"].text.strip_edges()
	
	if product_id.is_empty() or token.is_empty():
		return JSON.stringify({
			"error": _t("module6.message.empty_field"),
			"provider": "Google Play"
		}, "  ")
	
	var response: Dictionary = {
		"provider": "Google Play",
		"api_version": 3,
		"product_id": product_id,
		"purchase_token": token,
		"order_id": order_id,
		"purchase_state": 1,
		"purchase_state_desc": "PURCHASED",
		"consumption_state": 0,
		"consumption_state_desc": "NOT_CONSUMED",
		"developer_payload": "",
		"purchase_time": Time.get_ticks_msec(),
		"acknowledgement_state": 1,
		"verification_result": "SUCCESS",
		"message": _t("module7.log.verify_completed")
	}
	return JSON.stringify(response, "  ")

func _simulate_apple_verify() -> String:
	var product_id: String = ""
	var transaction_id: String = ""
	var original_tx_id: String = ""
	if _nodes["apple_product_id_edit"]:
		product_id = _nodes["apple_product_id_edit"].text.strip_edges()
	if _nodes["apple_transaction_id_edit"]:
		transaction_id = _nodes["apple_transaction_id_edit"].text.strip_edges()
	if _nodes["apple_original_tx_id_edit"]:
		original_tx_id = _nodes["apple_original_tx_id_edit"].text.strip_edges()
	
	if product_id.is_empty() or transaction_id.is_empty():
		return JSON.stringify({
			"error": _t("module6.message.empty_field"),
			"provider": "Apple App Store"
		}, "  ")
	
	var response: Dictionary = {
		"provider": "Apple App Store",
		"environment": "Sandbox",
		"product_id": product_id,
		"transaction_id": transaction_id,
		"original_transaction_id": original_tx_id,
		"status": 0,
		"status_desc": "VALID",
		"bundle_id": "com.example.app",
		"purchase_date": Time.get_datetime_string_from_system(),
		"expires_date": "",
		"is_trial_period": false,
		"verification_result": "SUCCESS",
		"message": _t("module7.log.verify_completed")
	}
	return JSON.stringify(response, "  ")

func _simulate_huawei_verify() -> String:
	var product_id: String = ""
	var token: String = ""
	var purchase_data: String = ""
	if _nodes["huawei_product_id_edit"]:
		product_id = _nodes["huawei_product_id_edit"].text.strip_edges()
	if _nodes["huawei_token_edit"]:
		token = _nodes["huawei_token_edit"].text.strip_edges()
	if _nodes["huawei_purchase_data_edit"]:
		purchase_data = _nodes["huawei_purchase_data_edit"].text.strip_edges()
	
	if product_id.is_empty() or token.is_empty():
		return JSON.stringify({
			"error": _t("module6.message.empty_field"),
			"provider": "Huawei AppGallery"
		}, "  ")
	
	var response: Dictionary = {
		"provider": "Huawei AppGallery",
		"product_id": product_id,
		"purchase_token": token,
		"purchase_data": purchase_data,
		"response_code": "0",
		"response_code_desc": "ORDER_STATE_PAID",
		"app_id": "123456789",
		"purchase_time": Time.get_ticks_msec(),
		"purchase_type": 0,
		"purchase_type_desc": "IN_APP",
		"verification_result": "SUCCESS",
		"message": _t("module7.log.verify_completed")
	}
	return JSON.stringify(response, "  ")

func _set_service_status(status: String) -> void:
	if _nodes["service_status_label"]:
		_nodes["service_status_label"].text = status

func _set_config_status(status: String) -> void:
	if _nodes["config_status_label"]:
		_nodes["config_status_label"].text = status

func _log_message(message: String) -> void:
	if _nodes["log_text"]:
		var timestamp: String = Time.get_datetime_string_from_system()
		_nodes["log_text"].text += "[%s] %s\n" % [timestamp, message]

func _show_message_dialog(message: String) -> void:
	if _nodes["message_dialog"]:
		_nodes["message_dialog"].title = _t("common.dialog.message")
		_nodes["message_dialog"].dialog_text = message
		_nodes["message_dialog"].popup_centered()

func _show_input_dialog(prompt: String) -> void:
	if _nodes["input_dialog"]:
		_nodes["input_dialog"].title = _t("common.dialog.message")
		_nodes["input_dialog"].dialog_text = prompt
		if _nodes["input_field"]:
			_nodes["input_field"].text = ""
		_nodes["input_dialog"].popup_centered()

func _show_confirm_dialog(message: String) -> void:
	if _nodes["confirm_dialog"]:
		_nodes["confirm_dialog"].title = _t("common.dialog.confirm")
		_nodes["confirm_dialog"].dialog_text = message
		_nodes["confirm_dialog"].popup_centered()

func _load_all_user_configs() -> void:
	var config_path: String = "res://addons/google_iap/user_configs.json"
	if FileAccess.file_exists(config_path):
		var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			var json: JSON = JSON.new()
			if json.parse(json_string) == OK:
				user_configs = json.data
	_refresh_account_selector()

func _ensure_default_user() -> void:
	if user_configs.is_empty():
		_create_new_user(_t("module6.default_user"))
	else:
		var first_user: String = user_configs.keys()[0]
		current_user = first_user
		_load_user_config(current_user)
		if _nodes["account_selector"] and _nodes["account_selector"].item_count > 0:
			_nodes["account_selector"].select(0)

func _create_new_user(user_name: String) -> void:
	var default_config: Dictionary = {
		"provider": PROVIDER_KEYS[0],
		"environment": ENVIRONMENT_KEYS[0],
		"google_key_path": "",
		"google_package_name": "",
		"apple_issuer_id": "",
		"apple_key_id": "",
		"apple_bundle_id": "",
		"apple_key_path": "",
		"huawei_api_key": "",
		"huawei_app_id": ""
	}
	user_configs[user_name] = default_config
	_save_all_user_configs()
	current_user = user_name
	_refresh_account_selector()
	_load_user_config(user_name)
	_log_message(_t("module6.log.account_created") + user_name)

func _save_user_config(user_name: String, config: Dictionary) -> void:
	user_configs[user_name] = config
	_save_all_user_configs()

func _load_user_config(user_name: String) -> void:
	if not user_configs.has(user_name):
		return
	var config: Dictionary = user_configs[user_name]
	if _nodes["server_provider"] and _nodes["server_provider"].item_count > 0:
		var provider_key: String = config.get("provider", PROVIDER_KEYS[0])
		for i: int in PROVIDER_KEYS.size():
			if PROVIDER_KEYS[i] == provider_key:
				if i < _nodes["server_provider"].item_count:
					_nodes["server_provider"].select(i)
				break
	if _nodes["server_env"] and _nodes["server_env"].item_count > 0:
		var env_key: String = config.get("environment", ENVIRONMENT_KEYS[0])
		for i: int in ENVIRONMENT_KEYS.size():
			if ENVIRONMENT_KEYS[i] == env_key:
				if i < _nodes["server_env"].item_count:
					_nodes["server_env"].select(i)
				break
	if _nodes["google_key_path"]:
		_nodes["google_key_path"].text = config.get("google_key_path", "")
	if _nodes["google_package_name"]:
		_nodes["google_package_name"].text = config.get("google_package_name", "")
	if _nodes["apple_issuer_id"]:
		_nodes["apple_issuer_id"].text = config.get("apple_issuer_id", "")
	if _nodes["apple_key_id"]:
		_nodes["apple_key_id"].text = config.get("apple_key_id", "")
	if _nodes["apple_bundle_id"]:
		_nodes["apple_bundle_id"].text = config.get("apple_bundle_id", "")
	if _nodes["apple_key_path"]:
		_nodes["apple_key_path"].text = config.get("apple_key_path", "")
	if _nodes["huawei_api_key"]:
		_nodes["huawei_api_key"].text = config.get("huawei_api_key", "")
	if _nodes["huawei_app_id"]:
		_nodes["huawei_app_id"].text = config.get("huawei_app_id", "")
	_update_provider_config_visibility()

func _delete_user(user_name: String) -> void:
	if not user_configs.has(user_name):
		return
	user_configs.erase(user_name)
	_save_all_user_configs()
	_refresh_account_selector()
	if user_configs.is_empty():
		_create_new_user(_t("module6.default_user"))
	else:
		current_user = user_configs.keys()[0]
		_load_user_config(current_user)
		if _nodes["account_selector"] and _nodes["account_selector"].item_count > 0:
			_nodes["account_selector"].select(0)
	_log_message(_t("module6.log.account_deleted") + user_name)

func _rename_user(old_name: String, new_name: String) -> void:
	if not user_configs.has(old_name):
		return
	var config: Dictionary = user_configs[old_name]
	user_configs.erase(old_name)
	user_configs[new_name] = config
	_save_all_user_configs()
	current_user = new_name
	_refresh_account_selector()
	_log_message(_t("module6.log.account_renamed") + new_name)

func _save_all_user_configs() -> void:
	var config_path: String = "res://addons/google_iap/user_configs.json"
	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(user_configs, "  ")
		file.store_string(json_string)
		file.close()

func _refresh_account_selector() -> void:
	if not _nodes["account_selector"]:
		return
	_nodes["account_selector"].clear()
	for user_name: String in user_configs.keys():
		_nodes["account_selector"].add_item(user_name)
	if _nodes["account_selector"].item_count == 0:
		return
	var select_index: int = 0
	for i: int in _nodes["account_selector"].item_count:
		if _nodes["account_selector"].get_item_text(i) == current_user:
			select_index = i
			break
	if select_index < _nodes["account_selector"].item_count:
		_nodes["account_selector"].select(select_index)

var report_platform: int = 0
var report_type: int = 0
var report_date_range: int = 0
var report_list: Array[Dictionary] = []
var selected_report_index: int = -1
var report_data_cache: Array[Array] = []

const REPORT_PLATFORMS: Array[String] = ["apple", "google", "huawei"]
const APPLE_REPORT_TYPES: Array[String] = ["sales", "financial", "analytics", "subscription"]
const GOOGLE_REPORT_TYPES: Array[String] = ["estimated_sales", "earnings", "crashes", "installs", "ratings"]
const HUAWEI_REPORT_TYPES: Array[String] = ["user_analysis", "distribution_analysis", "fa_distribution"]
const DATE_RANGES: Array[String] = ["yesterday", "last_7_days", "last_30_days", "this_month", "custom"]

func _setup_report_platform_selector() -> void:
	if not _nodes["report_platform_selector"]:
		return
	_nodes["report_platform_selector"].clear()
	for platform: String in REPORT_PLATFORMS:
		_nodes["report_platform_selector"].add_item(_t("common.provider." + platform))

func _setup_report_type_selector() -> void:
	if not _nodes["report_type_selector"]:
		return
	_nodes["report_type_selector"].clear()
	var types: Array = _get_current_report_types()
	for type: String in types:
		_nodes["report_type_selector"].add_item(_t("module8.report_type." + type))

func _get_current_report_types() -> Array:
	match REPORT_PLATFORMS[report_platform]:
		"apple":
			return APPLE_REPORT_TYPES
		"google":
			return GOOGLE_REPORT_TYPES
		"huawei":
			return HUAWEI_REPORT_TYPES
	return []

func _setup_date_range_selector() -> void:
	if not _nodes["date_range_selector"]:
		return
	_nodes["date_range_selector"].clear()
	for range_key: String in DATE_RANGES:
		_nodes["date_range_selector"].add_item(_t("module8.date_range." + range_key))
	_update_date_picker_visibility()

func _setup_report_tree() -> void:
	if not _nodes["report_tree"]:
		return
	_nodes["report_tree"].columns = 4
	_nodes["report_tree"].set_column_title(0, _t("module8.tree.file_name"))
	_nodes["report_tree"].set_column_title(1, _t("module8.tree.date"))
	_nodes["report_tree"].set_column_title(2, _t("module8.tree.type"))
	_nodes["report_tree"].set_column_title(3, _t("module8.tree.size"))
	_nodes["report_tree"].hide_root = true

func _update_date_picker_visibility() -> void:
	var is_custom: bool = DATE_RANGES[report_date_range] == "custom"
	if _nodes["start_date_picker"]:
		_nodes["start_date_picker"].visible = is_custom
	if _nodes["end_date_picker"]:
		_nodes["end_date_picker"].visible = is_custom
	if _nodes["start_date_label"]:
		_nodes["start_date_label"].visible = is_custom
	if _nodes["end_date_label"]:
		_nodes["end_date_label"].visible = is_custom

func _update_report_container_visibility() -> void:
	if _nodes["apple_report_container"]:
		_nodes["apple_report_container"].visible = REPORT_PLATFORMS[report_platform] == "apple"
	if _nodes["google_report_container"]:
		_nodes["google_report_container"].visible = REPORT_PLATFORMS[report_platform] == "google"
	if _nodes["huawei_report_container"]:
		_nodes["huawei_report_container"].visible = REPORT_PLATFORMS[report_platform] == "huawei"

func _on_report_platform_changed(index: int) -> void:
	report_platform = index
	_update_report_container_visibility()
	_setup_report_type_selector()
	_log_message(_t("module8.log.platform_changed").replace("{platform}", _t("common.provider." + REPORT_PLATFORMS[index])))

func _on_report_type_changed(index: int) -> void:
	report_type = index
	var types: Array = _get_current_report_types()
	if index < types.size():
		_log_message(_t("module8.log.type_changed").replace("{type}", _t("module8.report_type." + types[index])))

func _on_date_range_changed(index: int) -> void:
	report_date_range = index
	_update_date_picker_visibility()

func _on_test_report_connection() -> void:
	var platform: String = REPORT_PLATFORMS[report_platform]
	_set_report_status(_t("module8.status.testing"))
	_log_message(_t("module8.log.testing_connection").replace("{platform}", _t("common.provider." + platform)))
	var valid: bool = _validate_report_config(platform)
	if valid:
		_set_report_status(_t("module8.status.connected"))
		_log_message(_t("module8.log.connection_success"))
	else:
		_set_report_status(_t("module8.status.connection_failed"))
		_log_message(_t("module8.log.connection_failed"))

func _validate_report_config(platform: String) -> bool:
	match platform:
		"apple":
			if not _nodes["apple_report_issuer_id"] or _nodes["apple_report_issuer_id"].text.is_empty():
				return false
			if not _nodes["apple_report_key_id"] or _nodes["apple_report_key_id"].text.is_empty():
				return false
			if not _nodes["apple_report_key_path"] or _nodes["apple_report_key_path"].text.is_empty():
				return false
			return true
		"google":
			if not _nodes["google_report_key_path"] or _nodes["google_report_key_path"].text.is_empty():
				return false
			if not _nodes["google_bucket_id"] or _nodes["google_bucket_id"].text.is_empty():
				return false
			return true
		"huawei":
			if not _nodes["huawei_report_client_id"] or _nodes["huawei_report_client_id"].text.is_empty():
				return false
			if not _nodes["huawei_report_app_id"] or _nodes["huawei_report_app_id"].text.is_empty():
				return false
			return true
	return false

func _on_select_apple_report_key() -> void:
	pending_dialog_action = "select_apple_report_key"
	if _nodes["key_file_dialog"]:
		_nodes["key_file_dialog"].filters = PackedStringArray(["*.p8 ; P8 Files"])
		_nodes["key_file_dialog"].popup_centered()

func _on_select_google_report_key() -> void:
	pending_dialog_action = "select_google_report_key"
	if _nodes["key_file_dialog"]:
		_nodes["key_file_dialog"].filters = PackedStringArray(["*.json ; JSON Files"])
		_nodes["key_file_dialog"].popup_centered()

func _on_query_reports() -> void:
	var platform: String = REPORT_PLATFORMS[report_platform]
	if not _validate_report_config(platform):
		_show_message_dialog(_t("module8.message.config_incomplete"))
		return
	_set_report_status(_t("module8.status.querying"))
	_set_report_progress(0.1)
	_log_message(_t("module8.log.querying_reports"))
	report_list.clear()
	match platform:
		"apple":
			_load_apple_reports()
		"google":
			_load_google_reports()
		"huawei":
			_load_huawei_reports()
	_refresh_report_tree()
	_set_report_progress(1.0)
	_set_report_status(_t("module8.status.query_complete"))

func _load_apple_reports() -> void:
	var types: Array = _get_current_report_types()
	var selected_type: String = types[report_type] if report_type < types.size() else types[0]
	var date_range: Dictionary = _get_date_range()
	for i: int in range(5):
		var report: Dictionary = {
			"file_name": "apple_%s_%s.csv" % [selected_type, date_range.start_date],
			"date": date_range.start_date,
			"type": _t("module8.report_type." + selected_type),
			"size": "%d KB" % (randi() % 500 + 50),
			"platform": "apple",
			"report_type": selected_type
		}
		report_list.append(report)
	_set_report_progress(0.5)
	_log_message(_t("module8.log.reports_found").replace("{count}", str(report_list.size())))

func _load_google_reports() -> void:
	var types: Array = _get_current_report_types()
	var selected_type: String = types[report_type] if report_type < types.size() else types[0]
	var date_range: Dictionary = _get_date_range()
	for i: int in range(5):
		var report: Dictionary = {
			"file_name": "google_%s_%s.csv" % [selected_type, date_range.start_date],
			"date": date_range.start_date,
			"type": _t("module8.report_type." + selected_type),
			"size": "%d KB" % (randi() % 800 + 100),
			"platform": "google",
			"report_type": selected_type
		}
		report_list.append(report)
	_set_report_progress(0.5)
	_log_message(_t("module8.log.reports_found").replace("{count}", str(report_list.size())))

func _load_huawei_reports() -> void:
	var types: Array = _get_current_report_types()
	var selected_type: String = types[report_type] if report_type < types.size() else types[0]
	var date_range: Dictionary = _get_date_range()
	for i: int in range(5):
		var report: Dictionary = {
			"file_name": "huawei_%s_%s.csv" % [selected_type, date_range.start_date],
			"date": date_range.start_date,
			"type": _t("module8.report_type." + selected_type),
			"size": "%d KB" % (randi() % 300 + 30),
			"platform": "huawei",
			"report_type": selected_type
		}
		report_list.append(report)
	_set_report_progress(0.5)
	_log_message(_t("module8.log.reports_found").replace("{count}", str(report_list.size())))

func _get_date_range() -> Dictionary:
	var current_time: Dictionary = Time.get_datetime_dict_from_system()
	var start_date: String = ""
	var end_date: String = ""
	match DATE_RANGES[report_date_range]:
		"yesterday":
			var yesterday: Dictionary = Time.get_datetime_dict_from_system()
			yesterday.day -= 1
			start_date = "%04d-%02d-%02d" % [yesterday.year, yesterday.month, yesterday.day]
			end_date = start_date
		"last_7_days":
			var end: Dictionary = current_time.duplicate()
			var start: Dictionary = current_time.duplicate()
			start.day -= 7
			start_date = "%04d-%02d-%02d" % [start.year, start.month, start.day]
			end_date = "%04d-%02d-%02d" % [end.year, end.month, end.day]
		"last_30_days":
			var end: Dictionary = current_time.duplicate()
			var start: Dictionary = current_time.duplicate()
			start.day -= 30
			start_date = "%04d-%02d-%02d" % [start.year, start.month, start.day]
			end_date = "%04d-%02d-%02d" % [end.year, end.month, end.day]
		"this_month":
			start_date = "%04d-%02d-01" % [current_time.year, current_time.month]
			end_date = "%04d-%02d-%02d" % [current_time.year, current_time.month, current_time.day]
		"custom":
			if _nodes["start_date_picker"]:
				start_date = _nodes["start_date_picker"].text
			if _nodes["end_date_picker"]:
				end_date = _nodes["end_date_picker"].text
	return {"start_date": start_date, "end_date": end_date}

func _refresh_report_tree() -> void:
	if not _nodes["report_tree"]:
		return
	_nodes["report_tree"].clear()
	var root: TreeItem = _nodes["report_tree"].create_item()
	_nodes["report_tree"].hide_root = true
	for i: int in report_list.size():
		var report: Dictionary = report_list[i]
		var item: TreeItem = _nodes["report_tree"].create_item(root)
		item.set_text(0, report.get("file_name", ""))
		item.set_text(1, report.get("date", ""))
		item.set_text(2, report.get("type", ""))
		item.set_text(3, report.get("size", ""))
		item.set_metadata(0, i)
		item.set_tooltip_text(0, report.get("file_name", ""))

func _on_report_tree_item_selected() -> void:
	if not _nodes["report_tree"]:
		return
	var selected: TreeItem = _nodes["report_tree"].get_selected()
	if not selected:
		return
	var metadata: Variant = selected.get_metadata(0)
	if metadata is int:
		selected_report_index = metadata
		_preview_report(selected_report_index)

func _preview_report(index: int) -> void:
	if index < 0 or index >= report_list.size():
		return
	var report: Dictionary = report_list[index]
	_set_report_status(_t("module8.status.loading_preview"))
	_log_message(_t("module8.log.loading_preview").replace("{file}", report.get("file_name", "")))
	_generate_mock_preview_data()
	_refresh_preview_table()
	_set_report_status(_t("module8.status.preview_ready"))

func _generate_mock_preview_data() -> void:
	report_data_cache.clear()
	var headers: Array = ["date", "country", "product_id", "units", "revenue"]
	report_data_cache.append(headers)
	for i: int in range(10):
		var row: Array = [
			Time.get_datetime_string_from_system().split(" ")[0],
			["US", "CN", "JP", "GB", "DE"][randi() % 5],
			"product_%d" % (randi() % 5 + 1),
			str(randi() % 1000 + 10),
			"%.2f" % (randf() * 1000)
		]
		report_data_cache.append(row)

func _refresh_preview_table() -> void:
	if not _nodes["report_preview_table"]:
		return
	_nodes["report_preview_table"].clear()
	if report_data_cache.is_empty():
		return
	var root: TreeItem = _nodes["report_preview_table"].create_item()
	_nodes["report_preview_table"].hide_root = true
	var headers: Array = report_data_cache[0]
	for i: int in headers.size():
		_nodes["report_preview_table"].set_column_title(i, headers[i])
	for row_idx: int in range(1, report_data_cache.size()):
		var row: Array = report_data_cache[row_idx]
		var item: TreeItem = _nodes["report_preview_table"].create_item(root)
		for col: int in row.size():
			if col < headers.size():
				item.set_text(col, row[col])

func _on_download_report() -> void:
	if selected_report_index < 0 or selected_report_index >= report_list.size():
		_show_message_dialog(_t("module8.message.no_report_selected"))
		return
	if _nodes["report_file_dialog"]:
		var report: Dictionary = report_list[selected_report_index]
		_nodes["report_file_dialog"].current_file = report.get("file_name", "report.csv")
		_nodes["report_file_dialog"].popup_centered()

func _on_report_file_selected(path: String) -> void:
	_save_report_to_file(path)
	_log_message(_t("module8.log.report_saved").replace("{path}", path))

func _save_report_to_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		for row: Array in report_data_cache:
			var line: String = ",".join(row)
			file.store_line(line)
		file.close()
	_set_report_status(_t("module8.status.saved"))

func _on_open_report_folder() -> void:
	var reports_dir: String = "res://addons/google_iap/reports/"
	if not DirAccess.dir_exists_absolute(reports_dir):
		DirAccess.make_dir_recursive_absolute(reports_dir)
	OS.shell_open(ProjectSettings.globalize_path(reports_dir))

func _set_report_status(status: String) -> void:
	if _nodes["report_status_label"]:
		_nodes["report_status_label"].text = status

func _set_report_progress(value: float) -> void:
	if _nodes["report_progress_bar"]:
		_nodes["report_progress_bar"].value = value * 100
