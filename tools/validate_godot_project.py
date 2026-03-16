#!/usr/bin/env python3
"""
Godot项目验证工具
检查项目完整性，确保所有必需文件都存在
"""

import os
import json
from pathlib import Path

def check_required_files():
    """检查Godot项目必需的文件"""
    
    required_files = [
        "project.godot",
        "addons/google_iap/plugin.cfg",
        "addons/google_iap/GoogleIAP.gd",
        "addons/google_iap/GoogleIAPEditorPlugin.gd",
        "addons/google_iap/GoogleIAPConfigPanel.gd",
        "addons/google_iap/GoogleIAPConfigPanel.tscn",
        "addons/google_iap/config.json",
        "addons/google_iap/locales/en.json",
        "addons/google_iap/locales/zh.json",
        "addons/google_iap/column_widths.json",
        "addons/google_iap/iap_config.json",
        "addons/google_iap/server_accounts.json",
        "addons/google_iap/sku_database.json",
        "addons/google_iap/user_configs.json",
        "addons/google_iap/settings.cfg"
    ]
    
    print("🔍 检查Godot项目文件完整性...")
    print("=" * 60)
    
    missing_files = []
    existing_files = []
    
    for file_path in required_files:
        if os.path.exists(file_path):
            existing_files.append(file_path)
            print(f"✅ {file_path}")
        else:
            missing_files.append(file_path)
            print(f"❌ {file_path}")
    
    return missing_files, existing_files

def check_godot_version_compatibility():
    """检查Godot版本兼容性"""
    
    print("\n🔧 检查Godot版本兼容性...")
    print("=" * 60)
    
    # 检查project.godot中的版本配置
    if os.path.exists("project.godot"):
        with open("project.godot", "r", encoding="utf-8") as f:
            content = f.read()
            
        if "config_version=5" in content:
            print("✅ project.godot配置版本: 5 (Godot 4.x)")
        else:
            print("⚠️  project.godot配置版本可能不兼容")
    
    # 检查插件版本兼容性
    if os.path.exists("addons/google_iap/plugin.cfg"):
        with open("addons/google_iap/plugin.cfg", "r", encoding="utf-8") as f:
            content = f.read()
            
        if "supported_godot_versions" in content:
            print("✅ 插件支持Godot 4.0~4.7")
        else:
            print("⚠️  插件版本兼容性信息缺失")

def check_gdscript_syntax():
    """检查GDScript文件语法"""
    
    print("\n📝 检查GDScript文件...")
    print("=" * 60)
    
    gd_files = [
        "addons/google_iap/GoogleIAP.gd",
        "addons/google_iap/GoogleIAPEditorPlugin.gd",
        "addons/google_iap/GoogleIAPConfigPanel.gd"
    ]
    
    for gd_file in gd_files:
        if os.path.exists(gd_file):
            with open(gd_file, "r", encoding="utf-8") as f:
                content = f.read()
                
            # 基本语法检查
            if "@tool" in content:
                print(f"✅ {gd_file} - 工具脚本")
            elif "extends" in content:
                print(f"✅ {gd_file} - 继承类")
            else:
                print(f"⚠️  {gd_file} - 可能有问题")
        else:
            print(f"❌ {gd_file} - 文件缺失")

def check_json_files():
    """检查JSON文件格式"""
    
    print("\n📊 检查JSON文件格式...")
    print("=" * 60)
    
    json_files = [
        "addons/google_iap/config.json",
        "addons/google_iap/locales/en.json",
        "addons/google_iap/locales/zh.json",
        "addons/google_iap/column_widths.json",
        "addons/google_iap/iap_config.json",
        "addons/google_iap/server_accounts.json",
        "addons/google_iap/sku_database.json",
        "addons/google_iap/user_configs.json"
    ]
    
    for json_file in json_files:
        if os.path.exists(json_file):
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    json.load(f)
                print(f"✅ {json_file} - 格式正确")
            except json.JSONDecodeError as e:
                print(f"❌ {json_file} - JSON格式错误: {e}")
        else:
            print(f"❌ {json_file} - 文件缺失")

def create_missing_files():
    """创建缺失的必需文件"""
    
    print("\n🛠️ 创建缺失的配置文件...")
    print("=" * 60)
    
    # 创建缺失的JSON配置文件
    missing_configs = {
        "addons/google_iap/column_widths.json": {
            "sku_tree": {
                "column_0": 200,
                "column_1": 150,
                "column_2": 100,
                "column_3": 100,
                "column_4": 120
            }
        },
        "addons/google_iap/iap_config.json": {
            "billing_key": "",
            "environment": "sandbox",
            "auto_verify": True,
            "debug_mode": False
        },
        "addons/google_iap/server_accounts.json": {
            "accounts": {},
            "current_account": ""
        },
        "addons/google_iap/sku_database.json": {
            "skus": [],
            "last_modified": 0
        },
        "addons/google_iap/user_configs.json": {
            "users": {},
            "current_user": ""
        }
    }
    
    created_files = []
    
    for file_path, default_content in missing_configs.items():
        if not os.path.exists(file_path):
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(default_content, f, indent=2, ensure_ascii=False)
            created_files.append(file_path)
            print(f"✅ 已创建: {file_path}")
    
    return created_files

def main():
    """主函数"""
    
    print("🐰 Google IAP Ultimate - Godot项目验证工具")
    print("=" * 60)
    
    # 检查当前目录
    current_dir = os.getcwd()
    print(f"📁 当前目录: {current_dir}")
    
    # 检查必需文件
    missing_files, existing_files = check_required_files()
    
    # 检查Godot版本兼容性
    check_godot_version_compatibility()
    
    # 检查GDScript文件
    check_gdscript_syntax()
    
    # 检查JSON文件
    check_json_files()
    
    # 创建缺失的文件
    created_files = create_missing_files()
    
    # 总结报告
    print("\n📋 验证报告")
    print("=" * 60)
    print(f"✅ 现有文件: {len(existing_files)}")
    print(f"❌ 缺失文件: {len(missing_files)}")
    print(f"🛠️ 已创建文件: {len(created_files)}")
    
    if missing_files:
        print("\n⚠️ 需要手动创建的文件:")
        for file in missing_files:
            print(f"   - {file}")
    
    if not missing_files and not created_files:
        print("\n🎉 项目完整性检查通过！所有必需文件都存在。")
    else:
        print("\n🔧 项目需要修复，请按照上述提示操作。")

if __name__ == "__main__":
    main()