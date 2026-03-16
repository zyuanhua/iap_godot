#!/usr/bin/env python3
"""
Google IAP Ultimate 项目验证脚本
用于验证项目结构和文件完整性
"""

import os
import json
import sys
from pathlib import Path

def validate_project_structure():
    """验证项目基本结构"""
    print("🔍 验证项目结构...")
    
    required_files = [
        "addons/google_iap/plugin.cfg",
        "addons/google_iap/GoogleIAP.gd",
        "addons/google_iap/GoogleIAPConfigPanel.gd",
        "README.md",
        "LICENSE"
    ]
    
    for file_path in required_files:
        if not os.path.exists(file_path):
            print(f"❌ 缺失必要文件: {file_path}")
            return False
        else:
            print(f"✅ {file_path}")
    
    return True

def validate_json_files():
    """验证JSON文件格式"""
    print("\n🔍 验证JSON文件...")
    
    json_files = []
    for root, dirs, files in os.walk("addons/google_iap"):
        for file in files:
            if file.endswith('.json'):
                json_files.append(os.path.join(root, file))
    
    for json_file in json_files:
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                json.load(f)
            print(f"✅ {json_file}")
        except Exception as e:
            print(f"❌ JSON格式错误 {json_file}: {e}")
            return False
    
    return True

def validate_plugin_config():
    """验证插件配置文件"""
    print("\n🔍 验证插件配置...")
    
    try:
        with open("addons/google_iap/plugin.cfg", 'r', encoding='utf-8') as f:
            content = f.read()
            
        required_sections = ['plugin', 'dependencies']
        for section in required_sections:
            if f'[{section}]' not in content:
                print(f"❌ 插件配置缺少 [{section}] 部分")
                return False
        
        print("✅ plugin.cfg")
        return True
        
    except Exception as e:
        print(f"❌ 插件配置验证失败: {e}")
        return False

def validate_localization():
    """验证本地化文件"""
    print("\n🔍 验证本地化文件...")
    
    locales_dir = "addons/google_iap/locales"
    if not os.path.exists(locales_dir):
        print("❌ 本地化目录不存在")
        return False
    
    required_locales = ['en.json', 'zh.json']
    for locale in required_locales:
        locale_path = os.path.join(locales_dir, locale)
        if not os.path.exists(locale_path):
            print(f"❌ 缺失本地化文件: {locale}")
            return False
        
        try:
            with open(locale_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # 检查基本键值
            required_keys = ['app_name', 'sku_management', 'billing_service']
            for key in required_keys:
                if key not in data:
                    print(f"❌ {locale} 缺少必要键: {key}")
                    return False
            
            print(f"✅ {locale}")
            
        except Exception as e:
            print(f"❌ 本地化文件验证失败 {locale}: {e}")
            return False
    
    return True

def main():
    """主验证函数"""
    print("🚀 Google IAP Ultimate 项目验证")
    print("=" * 50)
    
    # 切换到项目根目录
    project_root = Path(__file__).parent.parent
    os.chdir(project_root)
    
    checks = [
        ("项目结构", validate_project_structure),
        ("JSON文件", validate_json_files),
        ("插件配置", validate_plugin_config),
        ("本地化文件", validate_localization),
    ]
    
    all_passed = True
    for check_name, check_func in checks:
        if not check_func():
            all_passed = False
            break
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 所有验证通过！项目结构完整。")
        return 0
    else:
        print("❌ 验证失败，请检查上述错误。")
        return 1

if __name__ == "__main__":
    sys.exit(main())