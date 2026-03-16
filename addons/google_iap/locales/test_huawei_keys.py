# -*- coding: utf-8 -*-
"""
测试华为语言键的访问
"""
import json

with open('zh.json', 'r', encoding='utf-8') as f:
    zh_data = json.load(f)

with open('en.json', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

print("中文语言文件 - 华为相关键:")
print("=" * 60)
print(f"module7.huawei.label.product_id = {zh_data['module7']['huawei']['label']['product_id']}")
print(f"module7.huawei.label.purchase_token = {zh_data['module7']['huawei']['label']['purchase_token']}")
print(f"module7.huawei.label.order_id = {zh_data['module7']['huawei']['label']['order_id']}")
print(f"module7.huawei.placeholder.product_id = {zh_data['module7']['huawei']['placeholder']['product_id']}")
print(f"module7.huawei.placeholder.purchase_token = {zh_data['module7']['huawei']['placeholder']['purchase_token']}")
print(f"module7.huawei.placeholder.order_id = {zh_data['module7']['huawei']['placeholder']['order_id']}")

print("\n英文语言文件 - 华为相关键:")
print("=" * 60)
print(f"module7.huawei.label.product_id = {en_data['module7']['huawei']['label']['product_id']}")
print(f"module7.huawei.label.purchase_token = {en_data['module7']['huawei']['label']['purchase_token']}")
print(f"module7.huawei.label.order_id = {en_data['module7']['huawei']['label']['order_id']}")
print(f"module7.huawei.placeholder.product_id = {en_data['module7']['huawei']['placeholder']['product_id']}")
print(f"module7.huawei.placeholder.purchase_token = {en_data['module7']['huawei']['placeholder']['purchase_token']}")
print(f"module7.huawei.placeholder.order_id = {en_data['module7']['huawei']['placeholder']['order_id']}")
