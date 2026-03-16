#!/usr/bin/env python3
"""
SVG转PNG转换工具
用于将SVG图标转换为PNG格式
"""

import os
import sys
from pathlib import Path

def create_conversion_instructions():
    """创建SVG转PNG的转换指南"""
    
    instructions = """# SVG转PNG转换指南

## 🎯 转换方法

### 方法1：使用在线转换工具（推荐）
1. 访问 https://svgtopng.com/
2. 上传SVG文件
3. 设置输出尺寸（推荐：256x256）
4. 下载PNG文件

### 方法2：使用Inkscape（免费开源）
```bash
# 安装Inkscape
# Windows: 从 https://inkscape.org/ 下载安装
# macOS: brew install inkscape
# Linux: sudo apt install inkscape

# 转换命令
inkscape --export-type=png --export-width=256 --export-height=256 github_icon.svg
inkscape --export-type=png --export-width=512 --export-height=512 icon.svg
inkscape --export-type=png --export-width=128 --export-height=128 rabbit_icon.svg
```

### 方法3：使用ImageMagick
```bash
# 安装ImageMagick
# Windows: 从 https://imagemagick.org/ 下载安装
# macOS: brew install imagemagick
# Linux: sudo apt install imagemagick

# 转换命令
magick github_icon.svg github_icon.png
magick icon.svg icon.png
magick rabbit_icon.svg rabbit_icon.png
```

## 📊 推荐尺寸

| 图标文件 | 推荐尺寸 | 用途 |
|----------|----------|------|
| github_icon.svg | 256x256 | GitHub项目展示 |
| icon.svg | 512x512 | 应用图标 |
| rabbit_icon.svg | 128x128 | 小图标 |

## 🎨 颜色配置

所有图标都使用以下颜色方案：
- **主背景**: #478CBF (Godot蓝色)
- **兔子主体**: #FFFFFF (白色)
- **耳朵内部**: #FFB6C1 (粉色)
- **眼睛**: #2C3E50 (深蓝色)
- **鼻子/嘴巴**: #FF6B9D (粉红色)
- **金币**: #FFD700 (金色)

## 📁 文件结构

转换后应生成以下PNG文件：
```
├── github_icon.png      # GitHub展示图标
├── icon.png            # 主项目图标
├── rabbit_icon.png     # 简约兔子图标
└── favicon.ico         # 网站图标（可选）
```

## 🔧 批量转换脚本

如果您需要批量转换，可以使用以下Python脚本：

```python
import os
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM

def convert_svg_to_png(svg_file, png_file, size=256):
    """将SVG文件转换为PNG"""
    drawing = svg2rlg(svg_file)
    renderPM.drawToFile(drawing, png_file, fmt='PNG', dpi=72)

# 批量转换
files_to_convert = [
    ('github_icon.svg', 'github_icon.png', 256),
    ('icon.svg', 'icon.png', 512),
    ('rabbit_icon.svg', 'rabbit_icon.png', 128)
]

for svg, png, size in files_to_convert:
    if os.path.exists(svg):
        convert_svg_to_png(svg, png, size)
        print(f"✅ 已转换: {svg} -> {png}")
    else:
        print(f"❌ 文件不存在: {svg}")
```

## 📝 注意事项

1. **保持比例**: 转换时保持原始宽高比
2. **透明背景**: 确保PNG文件有透明背景
3. **文件大小**: 优化PNG文件大小，避免过大
4. **多尺寸**: 为不同用途创建多个尺寸版本

## 🌐 在线工具推荐

- **SVG to PNG**: https://svgtopng.com/
- **Convertio**: https://convertio.co/svg-png/
- **Online-Convert**: https://image.online-convert.com/convert/svg-to-png
"""
    
    return instructions

def main():
    """主函数"""
    print("🐰 Google IAP Ultimate - SVG转PNG转换指南")
    print("=" * 50)
    
    # 创建转换指南
    instructions = create_conversion_instructions()
    
    # 保存指南文件
    with open("SVG_TO_PNG_GUIDE.md", "w", encoding="utf-8") as f:
        f.write(instructions)
    
    print("✅ 已创建转换指南: SVG_TO_PNG_GUIDE.md")
    print("📋 请查看指南文件获取详细的转换方法")
    
    # 检查SVG文件是否存在
    svg_files = ["github_icon.svg", "icon.svg", "rabbit_icon.svg"]
    print("\n🔍 检查SVG文件:")
    
    for svg_file in svg_files:
        if os.path.exists(svg_file):
            print(f"   ✅ {svg_file} - 存在")
        else:
            print(f"   ❌ {svg_file} - 缺失")

if __name__ == "__main__":
    main()