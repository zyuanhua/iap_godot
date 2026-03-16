# -*- coding: utf-8 -*-
import json
import sys

files_to_check = ['zh.json', 'en.json']

for filename in files_to_check:
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            json.load(f)
        print(f"✓ {filename} 格式正确")
    except Exception as e:
        print(f"✗ {filename} 格式错误：{e}")
        sys.exit(1)

print("\n所有语言文件格式验证通过！")
