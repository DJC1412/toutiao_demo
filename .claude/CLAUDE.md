# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (Android API 21+)
flutter run

# Static analysis / lint
flutter analyze

# Run tests
flutter test                    # all tests
flutter test test/widget_test.dart  # single test file

# View PlayerPool performance logs
flutter logs | grep "PlayerPool"
```

## Architecture

仿今日头条全屏视频流与搜索联动的 Flutter 项目。严格遵循 **MVVM** 分层架构，状态管理使用 **Provider**。

### Layer Map

| 层 | 位置 | 职责 |
|---|---|---|
| Model | `lib/data/models/` | `FeedItem` — 混合流统一数据模型（video/image 枚举，多图，AI标签，推荐词） |
| Repository | `lib/data/repository/` | `FeedRepository` — 单例数据仓库：分页查询、Fisher-Yates 洗牌推荐、权重评分搜索 |
| ViewModel | `lib/providers/` | `VideoFlowProvider` + `SearchProvider` — 状态管理、播放器复用池、搜索历史持久化 |
| View | `lib/views/` | Screens + Widgets — 纯 UI 渲染，通过 Provider 消费状态 |

### Directory Structure

```
lib/
├── data/
│   ├── models/
│   │   └── feed_item.dart          # FeedItem 数据模型（FeedType 枚举）
│   └── repository/
│       └── feed_repository.dart    # 单例仓库：12条假数据、分页/洗牌/权重搜索
├── providers/
│   ├── video_flow_provider.dart    # 【红线】视频流状态 + 播放器复用池（上限3个Controller）
│   └── search_provider.dart        # 搜索历史（SharedPreferences）+ 检索 + 结果过滤
├── views/
│   ├── screens/
│   │   ├── video_flow_screen.dart       # 首页：全屏垂直滑动 PageView
│   │   ├── search_middle_screen.dart    # 搜索中间页：键盘 + 历史词网格
│   │   ├── search_result_screen.dart    # 搜索结果页：视频列表 → 点击回跳首页
│   │   └── fullscreen_video_page.dart   # 横屏全屏 OverlayEntry（非 Navigator push）
│   └── widgets/
│       ├── feed_item_dispatcher.dart    # 视频/图文模板分发器
│       ├── video_card_widget.dart       # 视频卡片：播控 UI + 展开文案 + 进度条
│       ├── image_card_widget.dart       # 图文卡片：横向多图轮播 + 页码器
│       ├── interaction_buttons.dart     # 右侧互动挂件（头像/点赞/评论/分享）
│       └── search_bar_header.dart       # 顶部搜索入口
└── main.dart                            # MultiProvider 初始化 + 命名路由表
```

### Key Design Decisions

**1. Player Pool Pattern** (`video_flow_provider.dart`)
池上限 3 个 `VideoPlayerController`（Prev / Current / Next），滑动窗口算法自动回收超出距离的实例。`_updateWindow(centerIndex)` 按距离排序视频索引，截取最近 3 个进池，超出窗口的立即 `dispose()`。

**2. OverlayEntry 全屏方案**（非 Navigator push）
竖屏切横屏全屏不使用 `Navigator.push`，而是通过 `OverlayEntry` 插入透明 `Material` 包裹的 `FullscreenVideoPage`，**复用同一个 Controller 实例**，避免路由出栈时的黑屏抖动和视频重载。退出时先旋转屏幕方向 → `await 200ms` → `entry.remove()`，保证转屏在贴纸下完成后再撕掉。

**3. 跨页面搜索回跳**
搜索结果页点击视频 → `VideoFlowProvider.requestJumpToItem(itemId)` 设置 `pendingJumpIndex` → `Navigator.popUntil` 回到首页 → `VideoFlowScreen` 检测到 pending index → `PageController.jumpToPage(targetIndex)` 定位播放。

**4. FeedRepository 洗牌引擎**
`fetchRecommendFeeds()` 每次调用 Fisher-Yates 洗牌 + 时间戳注入唯一 ID（`{原ID}_ts{timestamp}_{序号}`），防止 PageView key 冲突，支持无限下拉。

**5. _safeSetState 防崩溃**
全屏 `play()` 回调可能触发竖屏 Widget 的 listener → `setState() called during build`。`_safeSetState()` 检测 `SchedulerPhase`，build 阶段推迟到 `postFrame` 执行。

### Route Table

| 路径 | 页面 | 说明 |
|---|---|---|
| `/` | `VideoFlowScreen` | 首页视频流 |
| `/search` | `SearchMiddleScreen` | 搜索中间页 |
| `/result` | `SearchResultScreen` | 搜索结果页 |
