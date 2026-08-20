# 🧪 Paster (胶棒剪切板)

一款专为 macOS 打造的**极简、极速、超低系统资源占用**的菜单栏剪切板管理工具。

![macOS Version](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square&logo=apple)
![Swift Version](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## ✨ 核心特性

- 🚀 **极速原生与超低占用**：纯 Swift + AppKit / SwiftUI 原生架构，安装包仅 ~2MB，运行时常驻内存低于 20MB，空闲 CPU 占用 0.0%。
- 🧴 **胶棒（Glue Stick）专属图标**：定制手绘菜单栏矢量模板图标，完美适配 macOS 深色与浅色模式。
- 📋 **50条图文历史记录**：
  - 支持纯文本、富文本、代码片段、颜色 Hex/RGB、网址链接与图片/截图。
  - 图片生成高清晰度轻量缩略图，智能去重并按使用频率更新时间。
  - 支持**置顶收藏（Pin）**功能，收藏项不受容量限制，永远不被轮替淘汰。
- ⚡️ **智能自动填入（Auto-Paste）**：
  - 点击列表中的任意一项，自动切回您先前工作的输入框并模拟 `⌘V` 自动粘贴填入。
  - 内置便捷的辅助功能（Accessibility）授权检测与一键引导。
- 🔍 **秒级实时搜索与分类筛选**：
  - 支持关键字实时模糊匹配。
  - 提供「全部 / 文本 / 图片 / 收藏」快速筛选 Tab。
  - 顶部 9 项支持 `⌘1` ~ `⌘9` 快捷键极速选取。

---

## 🛠️ 构建与运行

### 1. 快速编译并启动
在终端中进入项目目录，执行：

```bash
# 编译并打包生成 Paster.app
make app

# 编译并立即启动
make run
```

### 2. 安装到系统应用程序目录
```bash
make install
```
安装后即可在「访达 -> 应用程序」或聚焦搜索（Spotlight）中直接打开 **Paster**。

---

## 💡 权限说明（重要）

为了实现**「点击历史记录后直接自动填入输入框（Auto-Paste）」**功能，macOS 需要开启辅助功能权限：

1. 首次使用或在 Paster 的「偏好设置 -> 自动填入」中点击**「去授权」**。
2. 在系统弹出的「系统设置 -> 隐私与安全性 -> 辅助功能」中，勾选允许 **Paster**。
3. 授权后，点击任意记录即可实现光标处瞬间自动填入！

> 💡 *若未授权辅助功能，点击仍会自动将内容拷贝到系统剪切板中，您只需手动按 `⌘V` 即可粘贴。*

---

## 📁 目录结构

```
paster/
├── Makefile                     // 快速构建与安装指令
├── Package.swift                // Swift Package 配置
├── scripts/
│   ├── build_app.sh             // 自动编译打包脚本
│   └── generate_icon.swift      // 高清 AppIcon 生成器
├── Sources/
│   ├── Main.swift               // 启动入口
│   ├── AppDelegate.swift        // 菜单栏常驻与弹窗管理
│   ├── Models/                  // 数据模型 (ClipboardItem, ItemType)
│   ├── Services/                // 后台服务 (监听、模拟粘贴、文件存储、焦点追踪)
│   ├── Views/                   // SwiftUI 界面 (搜索栏、列表行、设置、胶棒图标)
│   └── Utils/                   // 工具拓展 (权限检测、时间格式化、图像处理)
└── Resources/
    └── Info.plist               // macOS 应用配置 (LSUIElement=true)
```

---

## 📄 开源许可

基于 MIT 许可证开源。
