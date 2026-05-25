# Claude Code Project Guidelines: 今日头条视频播放流与搜索模块

## 1. 规约与技术栈 (Technology Stack & System Prompt)
本工程为仿今日头条全屏视频流与搜索联动的跨平台项目。Claude Code 必须严格基于以下技术栈进行开发，确保 UI 与业务逻辑高度解耦：

* **核心框架**: Flutter (Dart) - 负责全链路 100% 全栈开发（含视频流、搜索中间页、搜索结果页）。
* **状态管理**: `provider` (声明式状态管理)。
* **核心插件**: 
    * `video_player` (基础视频渲染与解码)
    * `chewie` (负责手势控制、播控面板与进度条联动)
    * `shared_preferences` (负责本地搜索历史的持久化存取)
* **设计模式**: 严格遵守 MVVM (Model - View - ViewModel) 架构。

---

## 2. 目录树与核心文件结构约束 (Directory Tree & File Constraints)
Claude Code **必须且只能**在以下定义好的路径中创建、修改对应的 Dart 文件。禁止擅自更改目录结构或跨层引用：

```text
lib/
├── data/
│   ├── models/
│   │   └── feed_item.dart          # 【红线】混合流内容数据模型（含视频/图文、AI推荐词）
│   └── datasource/
│       └── mock_data_center.dart   # 本地 Mock 数据内容库（含模糊检索逻辑）
├── providers/
│   ├── video_flow_provider.dart    # 【性能红线】管理全局视频流状态、分页加载、以及播放器实例复用池
│   └── search_provider.dart        # 管理搜索历史（SharedPreferences）、检索词触发、结果过滤状态
├── views/
│   ├── screens/
│   │   ├── video_flow_screen.dart   # 页面1：视频播放流主页（含全屏滑动容器）
│   │   ├── search_middle_screen.dart# 页面2：搜索中间页（含键盘拉起、历史词网格）
│   │   └── search_result_screen.dart# 页面3：搜索结果页（视频列表，支持点击反哺回跳）
│   └── widgets/
│       ├── feed_item_dispatcher.dart# 混合模板分发器（判断渲染视频卡片还是图文卡片）
│       ├── video_card_widget.dart   # 视频流卡片组件（手势单击、双击、进度条快进）
│       ├── image_card_widget.dart   # 图文流卡片组件（进阶要求：多图混排卡片）
│       ├── interaction_buttons.dart # 右侧静态互动挂件（头像、点赞、评论、分享）
│       └── search_bar_header.dart   # 顶部通栏搜索框组件
└── main.dart                        # 应用全局入口、Provider 初始化与二级路由表配置
