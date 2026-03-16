# -*- coding: utf-8 -*-
"""
验证语言文件中的模块 7 键值
"""
import json

print("=" * 80)
print("验证模块 7 语言键")
print("=" * 80)

# 读取中文语言文件
with open('zh.json', 'r', encoding='utf-8') as f:
    zh_data = json.load(f)

print("\n中文语言文件 (zh.json):")
print("-" * 80)

# Google
print("\nGoogle:")
print(f"  module7.google.label.product_id = {zh_data['module7']['google']['label']['product_id']}")
print(f"  module7.google.label.purchase_token = {zh_data['module7']['google']['label']['purchase_token']}")
print(f"  module7.google.label.order_id = {zh_data['module7']['google']['label']['order_id']}")

# Apple
print("\nApple:")
print(f"  module7.apple.label.product_id = {zh_data['module7']['apple']['label']['product_id']}")
print(f"  module7.apple.label.transaction_id = {zh_data['module7']['apple']['label']['transaction_id']}")
print(f"  module7.apple.label.original_transaction_id = {zh_data['module7']['apple']['label']['original_transaction_id']}")
print(f"  module7.apple.label.order_id = {zh_data['module7']['apple']['label']['order_id']}")

# Huawei
print("\n华为:")
print(f"  module7.huawei.label.product_id = {zh_data['module7']['huawei']['label']['product_id']}")
print(f"  module7.huawei.label.purchase_token = {zh_data['module7']['huawei']['label']['purchase_token']}")
print(f"  module7.huawei.label.order_id = {zh_data['module7']['huawei']['label']['order_id']}")

# 读取英文语言文件
with open('en.json', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

print("\n" + "=" * 80)
print("英文语言文件 (en.json):")
print("-" * 80)

# Google
print("\nGoogle:")
print(f"  module7.google.label.product_id = {en_data['module7']['google']['label']['product_id']}")
print(f"  module7.google.label.purchase_token = {en_data['module7']['google']['label']['purchase_token']}")
print(f"  module7.google.label.order_id = {en_data['module7']['google']['label']['order_id']}")

# Apple
print("\nApple:")
print(f"  module7.apple.label.product_id = {en_data['module7']['apple']['label']['product_id']}")
print(f"  module7.apple.label.transaction_id = {en_data['module7']['apple']['label']['transaction_id']}")
print(f"  module7.apple.label.original_transaction_id = {en_data['module7']['apple']['label']['original_transaction_id']}")
print(f"  module7.apple.label.order_id = {en_data['module7']['apple']['label']['order_id']}")

# Huawei
print("\nHuawei:")
print(f"  module7.huawei.label.product_id = {en_data['module7']['huawei']['label']['product_id']}")
print(f"  module7.huawei.label.purchase_token = {en_data['module7']['huawei']['label']['purchase_token']}")
print(f"  module7.huawei.label.order_id = {en_data['module7']['huawei']['label']['order_id']}")

print("\n" + "=" * 80)
print("✓ 所有语言键验证通过！")
print("=" * 80)
