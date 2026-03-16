# -*- coding: utf-8 -*-
"""
验证模块 7 的所有语言键是否存在
"""
import json

# 读取语言文件
with open('zh.json', 'r', encoding='utf-8') as f:
    zh_data = json.load(f)

with open('en.json', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

# 需要验证的模块 7 语言键
required_keys = {
    # 基础键
    "module7.title": True,
    "module7.description": True,
    "module7.label.provider": True,
    "module7.btn.simulate_verify": True,
    "module7.btn.clear_response": True,
    "module7.provider_option.google": True,
    "module7.provider_option.apple": True,
    "module7.provider_option.huawei": True,
    
    # Google 专属键
    "module7.google.label.product_id": True,
    "module7.google.label.purchase_token": True,
    "module7.google.label.order_id": True,
    "module7.google.placeholder.product_id": True,
    "module7.google.placeholder.purchase_token": True,
    "module7.google.placeholder.order_id": True,
    
    # Apple 专属键
    "module7.apple.label.product_id": True,
    "module7.apple.label.transaction_id": True,
    "module7.apple.label.original_transaction_id": True,
    "module7.apple.label.order_id": True,
    "module7.apple.placeholder.product_id": True,
    "module7.apple.placeholder.transaction_id": True,
    "module7.apple.placeholder.original_transaction_id": True,
    "module7.apple.placeholder.order_id": True,
    
    # 华为专属键
    "module7.huawei.label.product_id": True,
    "module7.huawei.label.purchase_token": True,
    "module7.huawei.label.order_id": True,
    "module7.huawei.placeholder.product_id": True,
    "module7.huawei.placeholder.purchase_token": True,
    "module7.huawei.placeholder.order_id": True,
    
    # Tooltip 键
    "module7.tooltip.test_provider": True,
    "module7.tooltip.btn_test_verification": True,
    "module7.tooltip.btn_clear_response": True,
    "module7.tooltip.test_response_display": True,
    "module7.tooltip.product_id": True,
    "module7.tooltip.purchase_token": True,
    "module7.tooltip.order_id": True,
    "module7.tooltip.transaction_id": True,
    "module7.tooltip.original_transaction_id": True,
}

def check_nested_key(data, key_path):
    """检查嵌套的 JSON 键是否存在"""
    keys = key_path.split('.')
    current = data
    for key in keys:
        if key not in current:
            return False
        current = current[key]
    return True

print("验证中文语言文件 (zh.json):")
print("=" * 60)
missing_zh = []
for key in required_keys:
    if check_nested_key(zh_data, key):
        print(f"✓ {key}")
    else:
        print(f"✗ {key} - 缺失")
        missing_zh.append(key)

print("\n" + "=" * 60)
print("验证英文语言文件 (en.json):")
print("=" * 60)
missing_en = []
for key in required_keys:
    if check_nested_key(en_data, key):
        print(f"✓ {key}")
    else:
        print(f"✗ {key} - 缺失")
        missing_en.append(key)

print("\n" + "=" * 60)
print("验证结果汇总:")
print("=" * 60)

if missing_zh:
    print(f"\n✗ zh.json 缺失 {len(missing_zh)} 个键:")
    for key in missing_zh:
        print(f"  - {key}")
else:
    print("\n✓ zh.json 所有必需键都存在")

if missing_en:
    print(f"\n✗ en.json 缺失 {len(missing_en)} 个键:")
    for key in missing_en:
        print(f"  - {key}")
else:
    print("\n✓ en.json 所有必需键都存在")

if not missing_zh and not missing_en:
    print("\n🎉 所有模块 7 语言键验证通过！")
    exit(0)
else:
    print("\n❌ 存在缺失的语言键，请补充！")
    exit(1)
