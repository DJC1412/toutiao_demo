import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/video_flow_provider.dart';
import '../widgets/feed_item_dispatcher.dart';
import '../widgets/search_bar_header.dart';

class VideoFlowScreen extends StatefulWidget {
  const VideoFlowScreen({super.key});

  @override
  State<VideoFlowScreen> createState() => _VideoFlowScreenState();
}

class _VideoFlowScreenState extends State<VideoFlowScreen>
    with WidgetsBindingObserver, RouteAware {
  PageController? _pageController;
  int? _lastConsumedJump;
  double _dragStartPage = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    final provider = context.read<VideoFlowProvider>();
    _pageController = PageController(initialPage: provider.currentPageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.initWindow();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  void _onPageOrLoad(int index, VideoFlowProvider p) {
    p.onPageChanged(index);
    _lastConsumedJump = null;
    if (index >= p.itemCount - 2 && p.hasMore && !p.isLoading) {
      p.loadNextPage();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<VideoFlowProvider>().playActive();
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
        final p = context.read<VideoFlowProvider>();
        _pageController!.jumpToPage(targetIndex);
        p.consumePendingJump();
        _onPageOrLoad(targetIndex, p);
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
          NotificationListener<UserScrollNotification>(
            onNotification: (n) {
              if (_isAnimating) return true;
              if (n.direction != ScrollDirection.idle) {
                _dragStartPage = _pageController!.page!;
              } else {
                _isAnimating = true;
                final current = _pageController!.page!;
                final maxPage = (_pageController!.position.maxScrollExtent /
                    _pageController!.position.viewportDimension)
                    .round();
                final start = _dragStartPage.round();
                int target;
                if (current > _dragStartPage + 0.01) {
                  target = (start + 1).clamp(0, maxPage);
                } else if (current < _dragStartPage - 0.01) {
                  target = (start - 1).clamp(0, maxPage);
                } else {
                  target = start;
                }
                final p = context.read<VideoFlowProvider>();
                _pageController!
                    .animateToPage(target,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut)
                    .then((_) {
                  if (mounted) {
                    _isAnimating = false;
                    _onPageOrLoad(target, p);
                  }
                });
              }
              return false;
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              itemCount: items.length,
              pageSnapping: false,
              physics: const ClampingScrollPhysics(),
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
          ),

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
