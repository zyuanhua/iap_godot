# Google IAP Ultimate - 项目架构文档

## 🏗️ 系统架构概览

本项目是一个完整的Google Play IAP (In-App Purchase) 插件解决方案，采用模块化设计，支持多平台、多语言、可视化配置。

### 核心架构层次

```
┌─────────────────────────────────────────────────────────────┐
│                   应用层 (Application Layer)                   │
├─────────────────────────────────────────────────────────────┤
│  • 可视化配置面板 (GoogleIAPConfigPanel)                     │
│  • 示例项目 (examples/)                                      │
│  • 游戏集成示例 (example_project/)                          │
├─────────────────────────────────────────────────────────────┤
│                   业务逻辑层 (Business Logic Layer)           │
├─────────────────────────────────────────────────────────────┤
│  • SKU管理模块 (Module3_SKU)                                │
│  • 计费服务模块 (Module2_Billing)                           │
│  • 服务端配置模块 (Module6_ServerConfig)                     │
│  • 验单测试模块 (Module7_Verification)                       │
│  • 数据分析模块 (Module8_Analytics)                         │
├─────────────────────────────────────────────────────────────┤
│                   数据访问层 (Data Access Layer)             │
├─────────────────────────────────────────────────────────────┤
│  • JSON配置文件 (sku_database.json, user_configs.json)      │
│  • 本地化文件 (locales/zh.json, locales/en.json)            │
│  • 设置文件 (settings.cfg)                                  │
├─────────────────────────────────────────────────────────────┤
│                   平台适配层 (Platform Adaptation Layer)     │
├─────────────────────────────────────────────────────────────┤
│  • Android原生插件 (android/build/)                         │
│  • Godot引擎集成 (plugin.cfg)                               │
│  • 跨平台兼容处理                                            │
└─────────────────────────────────────────────────────────────┘
```

## 📁 项目目录结构详解

### 核心插件目录 (`addons/google_iap/`)

```
addons/google_iap/
├── locales/                          # 多语言支持
│   ├── zh.json                       # 中文本地化
│   └── en.json                       # 英文本地化
├── GoogleIAP.gd                      # 核心单例类
├── GoogleIAPEditorPlugin.gd           # 编辑器插件
├── GoogleIAPConfigPanel.tscn         # 配置面板场景
├── GoogleIAPConfigPanel.gd           # 配置面板逻辑
├── ResizableTree.gd                  # 自定义可调整列宽树控件
├── plugin.cfg                        # 插件配置文件
├── sku_database.json                 # SKU数据库
├── user_configs.json                 # 用户配置
├── settings.cfg                      # 应用设置
└── icon.svg                         # 插件图标
```

### Android平台适配 (`android/`)

```
android/
└── build/
    ├── build.gradle                  # Gradle构建配置
    ├── AndroidManifest.xml           # Android清单文件
    └── src/
        └── com/godot/plugin/googleiap/
            └── GoogleIAP.java        # Android原生插件实现
```

### 示例和工具 (`examples/`, `tools/`)

```
examples/                             # 使用示例
├── IAPExample.gd                     # 基础调用示例
├── IAPGameExample.gd                # 游戏集成示例
└── SERVER_VERIFICATION_GUIDE.md     # 服务端验单指南

tools/                                # 开发工具
└── obfuscator.py                    # 代码混淆工具
```

## 🔧 核心模块设计

### 1. 配置面板模块 (GoogleIAPConfigPanel)

**功能特性：**
- 可视化SKU管理
- 多服务商支持 (Google Play, Apple App Store, 华为应用市场)
- 实时预览和测试
- 导入导出功能 (JSON/CSV)

**UI模块结构：**
- **Module6_ServerConfig**: 服务端配置管理
- **Module3_SKU**: SKU商品管理
- **Module2_Billing**: 计费服务控制
- **Module4_Simulation**: 模拟测试
- **Module7_Verification**: 验单测试工具
- **Module5_Log**: 日志系统
- **Module8_Analytics**: 平台数据分析报告

### 2. 核心单例类 (GoogleIAP.gd)

**设计模式：** 单例模式 (Singleton)

**主要功能：**
- IAP生命周期管理
- 购买流程处理
- 错误处理和重试机制
- 与Android原生代码通信

### 3. 数据持久化设计

**配置文件类型：**
- **JSON格式**: SKU数据、用户配置、列宽设置
- **ConfigFile格式**: 应用设置、语言偏好
- **CSV格式**: 批量导入导出

**数据流：**
```
用户操作 → 配置面板 → JSON配置文件 → 运行时内存 → Android原生接口
```

## 🔄 数据流和状态管理

### SKU管理数据流

```
1. 用户添加SKU → 验证数据 → 保存到sku_database.json
2. 配置面板读取JSON → 显示在ResizableTree中
3. 用户修改SKU → 更新JSON文件 → 同步到运行时状态
4. 购买流程使用SKU数据 → 调用Android IAP API
```

### 购买状态机

```
初始化 → 查询商品 → 发起购买 → 处理结果 → 发放道具 → 完成
    ↓        ↓         ↓         ↓         ↓        ↓
  就绪状态  商品列表  购买中状态  验证状态  发放状态  完成状态
```

## 🛡️ 安全设计

### 1. 服务端验单机制
- HTTP请求封装
- 签名验证
- 防重放攻击
- 异步回调处理

### 2. 数据保护
- 配置文件加密选项
- 敏感信息处理
- 错误日志脱敏

### 3. 防作弊措施
- 购买状态验证
- 重复购买检测
- 异常行为监控

## 📊 性能优化

### 1. 内存管理
- 懒加载配置数据
- 对象池技术
- 及时释放资源

### 2. 响应速度
- 异步操作处理
- 批量数据操作
- 缓存机制

### 3. 用户体验
- 实时状态反馈
- 进度指示器
- 错误恢复机制

## 🔌 扩展性设计

### 1. 插件架构
- 模块化设计
- 接口抽象
- 热插拔支持

### 2. 平台扩展
- 多平台适配层
- 统一API接口
- 平台特定功能封装

### 3. 功能扩展
- 插件式功能模块
- 配置驱动开发
- 自定义钩子点

## 🧪 测试策略

### 1. 单元测试
- 核心逻辑测试
- 数据验证测试
- 边界条件测试

### 2. 集成测试
- 模块间交互测试
- 平台兼容性测试
- 端到端流程测试

### 3. 性能测试
- 内存使用测试
- 响应时间测试
- 并发处理测试

## 📈 监控和日志

### 1. 日志系统
- 分级日志记录
- 结构化日志格式
- 日志文件轮转

### 2. 性能监控
- 关键指标监控
- 异常检测
- 用户体验指标

### 3. 错误报告
- 自动错误收集
- 用户反馈机制
- 问题诊断工具

---

**文档版本**: 1.0  
**最后更新**: 2026-03-16  
**维护者**: zyuanhua