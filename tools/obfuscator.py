#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google IAP 插件 - GDScript 混淆工具
用于混淆核心逻辑代码，保护源码
"""

import re
import sys
import os
import random
import string


class GDScriptObfuscator:
    def __init__(self):
        # 公共API - 这些不应该被混淆
        self.public_apis = set([
            'initialize', 'is_billing_ready', 'query_products',
            'purchase_product', 'restore_purchases', 'consume_product',
            'get_cached_products', 'get_cached_purchases',
            'set_product_item_mapping', 'add_product_item_mapping',
            'remove_product_item_mapping', 'get_item_data_for_product',
            'grant_item_to_player', 'verify_purchase_on_server',
            'retry_pending_verifications', 'products_loaded',
            'products_load_failed', 'purchase_success', 'purchase_failed',
            'purchase_pending', 'purchase_cancelled', 'item_granted',
            'item_grant_failed', 'server_verify_success',
            'server_verify_failed', 'purchases_restored',
            'purchases_restore_failed', 'consume_success', 'consume_failed',
            'billing_connected', 'billing_disconnected',
            'billing_connection_failed', 'show_ui_message',
            'show_retry_dialog', 'product_item_mapping', 'auto_grant_items',
            'require_server_verification', 'server_verification_url',
            'server_request_timeout', 'log_level', 'enable_logging',
            'log_prefix', 'max_query_retry_count', 'query_retry_interval',
            'fallback_on_verify_failed', 'pending_verify_cache',
            'LogLevel', 'ProductType', 'PurchaseState', 'DEBUG', 'INFO', 'ERROR',
            'IN_APP', 'SUBS', 'UNSPECIFIED_STATE', 'PURCHASED', 'PENDING',
            'authorize_current_device', 'show_device_id', 'license_manager'
        ])
        
        # 生成的变量名映射
        self.var_map = {}
        self.func_map = {}
        self.class_map = {}
        
        # 计数器
        self.var_counter = 0
        self.func_counter = 0
        self.class_counter = 0
        
        # Godot关键字
        self.godot_keywords = set([
            'if', 'elif', 'else', 'for', 'while', 'match', 'break', 'continue',
            'pass', 'return', 'func', 'class', 'extends', 'signal', 'enum',
            'const', 'var', 'static', 'onready', 'export', 'tool', 'remote',
            'master', 'puppet', 'remotesync', 'mastersync', 'puppetsync',
            'void', 'bool', 'int', 'float', 'String', 'Vector2', 'Vector3',
            'Color', 'Rect2', 'Transform2D', 'Plane', 'Quat', 'AABB',
            'Basis', 'Transform', 'NodePath', 'RID', 'Object', 'Array',
            'Dictionary', 'PoolByteArray', 'PoolIntArray', 'PoolRealArray',
            'PoolStringArray', 'PoolVector2Array', 'PoolVector3Array',
            'PoolColorArray', 'null', 'true', 'false', 'and', 'or', 'not',
            'in', 'is', 'as', 'self', 'super', 'yield', 'await', 'preload',
            'load', 'instance_from_id', 'print', 'printt', 'prints', 'printerr',
            'printraw', 'var2str', 'str2var', 'var2bytes', 'bytes2var',
            'hash', 'ColorN', 'typeof', 'type_exists', 'char', 'ord',
            'str', 'min', 'max', 'clamp', 'abs', 'sign', 'sqrt', 'modf',
            'fmod', 'posmod', 'floor', 'ceil', 'round', 'trunc', 'decimal',
            'pow', 'log', 'exp', 'isnan', 'isinf', 'ease', 'step_decimals',
            'range', 'lerp', 'lerp_angle', 'inverse_lerp', 'smoothstep',
            'move_toward', 'dectime', 'randomize', 'randi', 'randf', 'rand_range',
            'seed', 'rand_seed', 'deg2rad', 'rad2deg', 'sin', 'cos', 'tan',
            'sinh', 'cosh', 'tanh', 'asin', 'acos', 'atan', 'atan2', 'pi',
            'tau', 'inf', 'nan', 'PI', 'TAU', 'INF', 'NAN'
        ])
    
    def generate_var_name(self):
        """生成混淆后的变量名"""
        self.var_counter += 1
        return f"_v{self.var_counter}"
    
    def generate_func_name(self):
        """生成混淆后的函数名"""
        self.func_counter += 1
        return f"_f{self.func_counter}"
    
    def generate_class_name(self):
        """生成混淆后的类名"""
        self.class_counter += 1
        return f"_C{self.class_counter}"
    
    def should_keep(self, name):
        """判断是否应该保留原名"""
        return (name in self.public_apis or 
                name in self.godot_keywords or
                name.startswith('_') and len(name) <= 2 or
                name.isupper())  # 常量通常全大写
    
    def obfuscate(self, content):
        """混淆GDScript代码"""
        lines = content.split('\n')
        result = []
        
        for line in lines:
            # 跳过空行和纯注释行
            stripped = line.strip()
            if not stripped:
                result.append('')
                continue
            if stripped.startswith('#'):
                continue
            
            # 处理行
            processed_line = self._process_line(line)
            if processed_line.strip():
                result.append(processed_line)
        
        return '\n'.join(result)
    
    def _process_line(self, line):
        """处理单行代码"""
        # 移除行内注释
        line = re.sub(r'#.*$', '', line)
        
        # 处理变量声明
        line = self._process_var_declarations(line)
        
        # 处理函数声明
        line = self._process_func_declarations(line)
        
        # 处理类声明
        line = self._process_class_declarations(line)
        
        # 替换已映射的变量和函数
        line = self._replace_names(line)
        
        return line
    
    def _process_var_declarations(self, line):
        """处理变量声明"""
        # 匹配: var name = ... 或 var name: Type = ...
        var_pattern = r'\bvar\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[=:]?'
        
        matches = re.finditer(var_pattern, line)
        for match in matches:
            var_name = match.group(1)
            if not self.should_keep(var_name) and var_name not in self.var_map:
                self.var_map[var_name] = self.generate_var_name()
        
        return line
    
    def _process_func_declarations(self, line):
        """处理函数声明"""
        # 匹配: func name(...)
        func_pattern = r'\bfunc\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\('
        
        matches = re.finditer(func_pattern, line)
        for match in matches:
            func_name = match.group(1)
            if not self.should_keep(func_name) and func_name not in self.func_map:
                self.func_map[func_name] = self.generate_func_name()
        
        return line
    
    def _process_class_declarations(self, line):
        """处理类声明"""
        # 匹配: class_name Name 或 class Name
        class_pattern1 = r'\bclass_name\s+([a-zA-Z_][a-zA-Z0-9_]*)'
        class_pattern2 = r'\bclass\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:extends|{)'
        
        matches = re.finditer(class_pattern1, line)
        for match in matches:
            class_name = match.group(1)
            if not self.should_keep(class_name) and class_name not in self.class_map:
                self.class_map[class_name] = self.generate_class_name()
        
        matches = re.finditer(class_pattern2, line)
        for match in matches:
            class_name = match.group(1)
            if not self.should_keep(class_name) and class_name not in self.class_map:
                self.class_map[class_name] = self.generate_class_name()
        
        return line
    
    def _replace_names(self, line):
        """替换变量和函数名"""
        # 优先替换长名称，避免部分匹配问题
        all_names = sorted(
            list(self.var_map.items()) + 
            list(self.func_map.items()) + 
            list(self.class_map.items()),
            key=lambda x: len(x[0]),
            reverse=True
        )
        
        for old_name, new_name in all_names:
            # 使用单词边界确保完整匹配
            line = re.sub(r'\b' + re.escape(old_name) + r'\b', new_name, line)
        
        return line


def main():
    if len(sys.argv) < 3:
        print("=" * 50)
        print("Google IAP GDScript 混淆工具")
        print("=" * 50)
        print()
        print("用法: python obfuscator.py <输入文件> <输出文件>")
        print()
        print("示例:")
        print("  python obfuscator.py GoogleIAP.gd GoogleIAP.gd.obfuscated")
        print()
        print("注意:")
        print("  - 公共API不会被混淆")
        print("  - 请备份原始文件")
        print("  - 混淆后请测试功能是否正常")
        print()
        return 1
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"错误: 输入文件不存在: {input_file}")
        return 1
    
    print("=" * 50)
    print("Google IAP GDScript 混淆工具")
    print("=" * 50)
    print()
    print(f"输入文件: {input_file}")
    print(f"输出文件: {output_file}")
    print()
    
    # 读取输入文件
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"错误: 无法读取输入文件: {e}")
        return 1
    
    # 混淆代码
    print("正在混淆代码...")
    obfuscator = GDScriptObfuscator()
    obfuscated_content = obfuscator.obfuscate(content)
    
    # 添加文件头
    header = """# ========================================
# Google IAP Ultimate - 混淆版本
# 警告: 此文件已被混淆，请勿直接修改
# 请使用原始源码进行开发和修改
# ========================================

"""
    obfuscated_content = header + obfuscated_content
    
    # 写入输出文件
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(obfuscated_content)
    except Exception as e:
        print(f"错误: 无法写入输出文件: {e}")
        return 1
    
    # 输出统计信息
    print()
    print("混淆完成！")
    print()
    print("统计信息:")
    print(f"  混淆变量数: {len(obfuscator.var_map)}")
    print(f"  混淆函数数: {len(obfuscator.func_map)}")
    print(f"  混淆类数: {len(obfuscator.class_map)}")
    print()
    print("请测试混淆后的代码是否正常工作！")
    print()
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
