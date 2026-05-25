import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../data/models/feed_item.dart';
import '../data/datasource/mock_data_center.dart';

/// 单一播放器缓存条目
class _PlayerEntry {
  final VideoPlayerController controller;
  DateTime preloadStart;
  DateTime? initializedAt;

  _PlayerEntry(this.controller)
      : preloadStart = DateTime.now(),
        initializedAt = null;
}

/// 管理全局视频流状态、分页加载、以及播放器实例复用池
///
/// 【性能红线】池上限 = 3 个 VideoPlayerController（Prev / Current / Next），
/// 超出窗口的实例立即 dispose 回收内存。
class VideoFlowProvider extends ChangeNotifier {
  final MockDataCenter _dataCenter = MockDataCenter();

  // ── 播放器复用池 ──
  static const int _maxPoolSize = 3;
  final Map<String, _PlayerEntry> _pool = {};

  List<FeedItem> get items => _dataCenter.getAllItems();
  int get itemCount => items.length;

  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  /// 当前正在播放的视频 ID
  String? _activeVideoId;

  /// 获取指定视频的池化控制器（可能为 null，表示尚未初始化）
  VideoPlayerController? getControllerFor(String itemId) {
    return _pool[itemId]?.controller;
  }

  /// 当前激活视频是否已就绪
  bool get isActiveReady {
    if (_activeVideoId == null) return false;
    final entry = _pool[_activeVideoId!];
    return entry != null && entry.controller.value.isInitialized;
  }

  // ── 搜索跳转 ──
  int? _pendingJumpIndex;

  int? get pendingJumpIndex => _pendingJumpIndex;

  void requestJumpToItem(String itemId) {
    final idx = _dataCenter.indexOfItem(itemId);
    if (idx >= 0) {
      _pendingJumpIndex = idx;
      notifyListeners();
    }
  }

  void consumePendingJump() {
    if (_pendingJumpIndex != null) {
      _pendingJumpIndex = null;
    }
  }

  // ── 页面切换与预加载调度 ──
  void onPageChanged(int index) {
    if (_currentPageIndex == index) return;
    _currentPageIndex = index;
    _updateWindow(index);
    notifyListeners();
  }

  /// 滑动窗口：始终维护当前页附近的至多 3 个视频控制器
  void _updateWindow(int centerIndex) {
    final allItems = _dataCenter.getAllItems();

    // 收集所有视频项的索引
    final videoIndices = <int>[];
    for (int i = 0; i < allItems.length; i++) {
      if (allItems[i].isVideo) videoIndices.add(i);
    }
    if (videoIndices.isEmpty) return;

    // 按距离中心页的远近排序，取最近的 3 个
    videoIndices.sort((a, b) => (a - centerIndex).abs().compareTo((b - centerIndex).abs()));
    final window = videoIndices.take(_maxPoolSize).toSet();

    // 回收窗口外的控制器
    for (final id in _pool.keys.toList()) {
      final idx = _dataCenter.indexOfItem(id);
      if (!window.contains(idx)) {
        final entry = _pool.remove(id)!;
        entry.controller.dispose();
        developer.log('🗑️  [Pool] 回收实例: $id (${allItems[idx].title})',
            name: 'PlayerPool');
      }
    }

    // 为窗口内的视频创建并预加载控制器
    for (final idx in window) {
      final item = allItems[idx];
      if (!_pool.containsKey(item.id) && item.videoUrl != null) {
        _preloadItem(item);
      }
    }

    // 更新当前激活视频
    final currentItem = allItems[centerIndex];
    if (currentItem.isVideo) {
      _activeVideoId = currentItem.id;
    } else {
      // 图文页：激活最近的视频
      _activeVideoId = window.isNotEmpty
          ? allItems[window.first].id
          : null;
    }

    developer.log(
        '📍 [Pool] 滑窗更新 | center=$centerIndex | 池内=${_pool.length} | '
        '窗口=${window.map((i) => allItems[i].id).toList()} | active=$_activeVideoId',
        name: 'PlayerPool');
  }

  /// 异步预加载单个视频控制器
  void _preloadItem(FeedItem item) {
    final id = item.id;
    developer.log('⏳ [Preload] 开始预加载: $id — "${item.title}" | url=${item.videoUrl}',
        name: 'PlayerPool');

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(item.videoUrl!),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    final entry = _PlayerEntry(controller);
    _pool[id] = entry;

    // ── 持久错误监听（initialize 成功后仍可能出现运行时错误）──
    controller.addListener(() {
      if (controller.value.hasError) {
        developer.log(
            '🚨 [RuntimeError] $id | '
            'errorDescription=${controller.value.errorDescription}',
            name: 'PlayerPool');
      }
    });

    controller.initialize().then((_) {
      entry.initializedAt = DateTime.now();
      final elapsed = entry.initializedAt!.difference(entry.preloadStart).inMilliseconds;
      developer.log(
          '✅ [Preload] 预加载完成: $id | '
          '耗时=${elapsed}ms | '
          'size=${controller.value.size} | '
          'duration=${controller.value.duration.inSeconds}s | '
          'isInitialized=${controller.value.isInitialized} | '
          'hasError=${controller.value.hasError}',
          name: 'PlayerPool');

      if (controller.value.hasError) {
        developer.log(
            '🚨 [Preload] 初始化返回但有错误: $id | '
            'errorDescription=${controller.value.errorDescription}',
            name: 'PlayerPool');
        return;
      }

      // 首帧就绪 → 自动起播
      if (id == _activeVideoId) {
        final ttff = entry.initializedAt!.difference(entry.preloadStart).inMilliseconds;
        developer.log(
            '🎬 [TTFF] 首帧就绪 (Time to First Frame): $id | '
            'TTFF=${ttff}ms | autoPlay=true',
            name: 'PlayerPool');
        controller.play();
      }

      notifyListeners();
    }).catchError((e, stack) {
      developer.log(
          '❌ [Preload] 预加载异常: $id | '
          'exception=${e.runtimeType} | '
          'message=$e | '
          'stack=$stack',
          name: 'PlayerPool');
    });
  }

  /// 初始化首页窗口（VideoFlowScreen initState 时调用）
  void initWindow() {
    _updateWindow(_currentPageIndex);
  }

  // ── 播控操作 ──
  void togglePlay() {
    if (_activeVideoId == null) return;
    final entry = _pool[_activeVideoId!];
    if (entry == null || !entry.controller.value.isInitialized) return;
    if (entry.controller.value.isPlaying) {
      entry.controller.pause();
    } else {
      entry.controller.play();
    }
    notifyListeners();
  }

  void seekTo(Duration position) {
    if (_activeVideoId == null) return;
    final entry = _pool[_activeVideoId!];
    if (entry == null || !entry.controller.value.isInitialized) return;
    entry.controller.seekTo(position);
    notifyListeners();
  }

  /// 当前激活控制器的播放状态（供卡片的 overlay 使用）
  bool get isPlaying {
    if (_activeVideoId == null) return false;
    final entry = _pool[_activeVideoId!];
    if (entry == null || !entry.controller.value.isInitialized) return false;
    return entry.controller.value.isPlaying;
  }

  /// 当前激活控制器的播放位置
  Duration get currentPosition {
    if (_activeVideoId == null) return Duration.zero;
    final entry = _pool[_activeVideoId!];
    if (entry == null || !entry.controller.value.isInitialized) return Duration.zero;
    return entry.controller.value.position;
  }

  /// 当前激活控制器的总时长
  Duration get totalDuration {
    if (_activeVideoId == null) return Duration.zero;
    final entry = _pool[_activeVideoId!];
    if (entry == null || !entry.controller.value.isInitialized) return Duration.zero;
    return entry.controller.value.duration;
  }

  // ── 资源全量释放 ──
  /// 销毁池中所有控制器，应用退出或 Provider 销毁时调用
  void disposePool() {
    for (final entry in _pool.values) {
      entry.controller.dispose();
    }
    _pool.clear();
    _activeVideoId = null;
    developer.log('🧹 [Pool] 池已清空，所有控制器已 dispose', name: 'PlayerPool');
  }

  @override
  void dispose() {
    disposePool();
    super.dispose();
  }

  /// 处理非视频页的情况 —— 暂停当前视频
  void pauseActive() {
    if (_activeVideoId == null) return;
    final entry = _pool[_activeVideoId!];
    if (entry != null && entry.controller.value.isPlaying) {
      entry.controller.pause();
      notifyListeners();
    }
  }

  /// 播放当前激活视频
  void playActive() {
    if (_activeVideoId == null) return;
    final entry = _pool[_activeVideoId!];
    if (entry != null && entry.controller.value.isInitialized && !entry.controller.value.isPlaying) {
      entry.controller.play();
      notifyListeners();
    }
  }
}
