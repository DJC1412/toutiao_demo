import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/video_flow_provider.dart';
import '../widgets/feed_item_dispatcher.dart';
import '../widgets/search_bar_header.dart';

/// 页面1：视频播放流主页（含全屏滑动容器）
class VideoFlowScreen extends StatefulWidget {
  const VideoFlowScreen({super.key});

  @override
  State<VideoFlowScreen> createState() => _VideoFlowScreenState();
}

class _VideoFlowScreenState extends State<VideoFlowScreen>
    with WidgetsBindingObserver {
  PageController? _pageController;
  int? _lastConsumedJump;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 设置浅色状态栏（白色文字，透明背景，在黑色视频背景上可见）
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    final provider = context.read<VideoFlowProvider>();
    _pageController = PageController(initialPage: provider.currentPageIndex);
    provider.initWindow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<VideoFlowProvider>();
    if (state == AppLifecycleState.paused) {
      provider.pauseActive();
    }
  }

  void _executeJump(int targetIndex) {
    if (_lastConsumedJump == targetIndex) return;
    _lastConsumedJump = targetIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController != null && _pageController!.hasClients) {
        _pageController!.jumpToPage(targetIndex);
        context.read<VideoFlowProvider>().consumePendingJump();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoFlowProvider>();
    final items = provider.items;

    final pendingJump = provider.pendingJumpIndex;
    if (pendingJump != null) {
      _executeJump(pendingJump);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (index) {
              provider.onPageChanged(index);
              _lastConsumedJump = null;
            },
            itemBuilder: (context, index) {
              final item = items[index];
              final isActive = index == provider.currentPageIndex;
              final controller = provider.getControllerFor(item.id);

              return FeedItemDispatcher(
                item: item,
                controller: controller,
                isActive: isActive,
                onTogglePlay: () => provider.togglePlay(),
              );
            },
          ),

          // ── 右上角放大镜搜索按钮 ──
          const Positioned(
            top: 0,
            right: 0,
            child: SafeArea(child: SearchBarHeader()),
          ),
        ],
      ),
    );
  }
}
