import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../data/models/feed_item.dart';
import '../data/repository/feed_repository.dart';

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
  final FeedRepository _repo = FeedRepository.instance;

  // ── 分页状态 ──
  final List<FeedItem> _items = [];
  final Set<String> _shownOriginalIds = {};
  bool _isLoading = false;
  bool _hasMore = true;

  List<FeedItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  // ── 图片预加载 ──
  final List<String> _nearbyImageUrls = [];
  List<String> get nearbyImageUrls => List.unmodifiable(_nearbyImageUrls);

  // ── 播放器复用池 ──
  static const int _maxPoolSize = 3;
  final Map<String, _PlayerEntry> _pool = {};
  final Map<String, String> _qualityUrlCache = {};
  static const _serverBase = 'http://192.168.2.8:8080';

  /// 控制预加载后是否自动起播：开屏期间 false，进入主界面后 true
  bool allowAutoPlay = false;

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
    // 洗牌后的 ID 带 _ts{timestamp}_{index} 后缀，用 startsWith 模糊匹配原始 ID
    final idx = _items.indexWhere(
      (item) => item.id == itemId || item.id.startsWith('${itemId}_ts'),
    );
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
    // 先暂停上一个活跃视频（防止旧 Widget 被 dispose 后漏停）
    pauseActive();
    _currentPageIndex = index;
    _updateWindow(index);
    notifyListeners();
  }

  /// 滑动窗口：始终维护当前页附近的至多 3 个视频控制器
  void _updateWindow(int centerIndex) {
    if (_items.isEmpty) return;

    final videoIndices = <int>[];
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isVideo) videoIndices.add(i);
    }
    if (videoIndices.isEmpty) return;

    videoIndices.sort((a, b) => (a - centerIndex).abs().compareTo((b - centerIndex).abs()));
    final window = videoIndices.take(_maxPoolSize).toSet();

    for (final id in _pool.keys.toList()) {
      final idx = _items.indexWhere((item) => item.id == id);
      if (!window.contains(idx)) {
        final entry = _pool.remove(id)!;
        entry.controller.dispose();
        developer.log('🗑️  [Pool] 回收实例: $id (${_items[idx].title})',
            name: 'PlayerPool');
      }
    }

    for (final idx in window) {
      final item = _items[idx];
      if (!_pool.containsKey(item.id) && item.videoUrl != null) {
        preloadItem(item);
      }
    }

    final currentItem = _items[centerIndex];
    if (currentItem.isVideo) {
      _activeVideoId = currentItem.id;
    } else {
      _activeVideoId = null;
    }

    // ── 收集附近图片 URL 用于预加载 ──
    _nearbyImageUrls.clear();
    for (int i = centerIndex - 2; i <= centerIndex + 2; i++) {
      if (i >= 0 && i < _items.length && !_items[i].isVideo) {
        final imgs = _items[i].imageUrls;
        _nearbyImageUrls.addAll(imgs);
        if (_items[i].coverUrl.isNotEmpty) _nearbyImageUrls.add(_items[i].coverUrl);
      }
    }

    developer.log(
        '📍 [Pool] 滑窗更新 | center=$centerIndex | 池内=${_pool.length} | '
        '窗口=${window.map((i) => _items[i].id).toList()} | active=$_activeVideoId',
        name: 'PlayerPool');
  }

  /// 异步预加载单个视频控制器（子类可重写用于测试）
  @visibleForTesting
  void preloadItem(FeedItem item) {
    final id = item.id;
    developer.log('⏳ [Preload] 开始预加载: $id — "${item.title}" | url=${item.videoUrl}',
        name: 'PlayerPool');

    final controller = _createController(item);
    final entry = _PlayerEntry(controller);
    _pool[id] = entry;

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

      if (id == _activeVideoId && allowAutoPlay) {
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

  VideoPlayerController _createController(FeedItem item) {
    final url = _qualityUrlCache[item.id] ?? item.videoUrl!;
    return url.startsWith('assets/')
        ? VideoPlayerController.asset(url)
        : VideoPlayerController.networkUrl(
            Uri.parse(url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
  }

  /// 提取原始 ID（去掉时间戳后缀）
  String _originalId(String id) => id.contains('_ts') ? id.split('_ts').first : id;

  /// 初始化首页 → 洗牌全量池，记录已展示 ID
  Future<void> initWindow() async {
    if (_items.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();

    final page = await _repo.fetchRecommendFeeds(page: 0);
    _items.addAll(page);
    for (final item in page) {
      _shownOriginalIds.add(_originalId(item.id));
    }
    _isLoading = false;
    _hasMore = true;

    _updateWindow(_currentPageIndex);
    notifyListeners();
  }

  /// 翻页：从未展示的原始数据中随机抽取，集显不重复
  Future<void> loadNextPage() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    final allItems = _repo.getAllItems();
    // 过滤掉已展示过的
    var remaining = allItems.where((it) => !_shownOriginalIds.contains(it.id)).toList();
    // 全部展示完了 → 重置，从头开始
    if (remaining.isEmpty) {
      _shownOriginalIds.clear();
      remaining = List<FeedItem>.from(allItems);
    }

    remaining.shuffle();
    final batch = remaining.take(5).toList();

    // 注入唯一 ID
    final ts = DateTime.now().microsecondsSinceEpoch;
    final nextPage = <FeedItem>[];
    for (int i = 0; i < batch.length; i++) {
      final original = batch[i];
      nextPage.add(FeedItem(
        id: '${original.id}_ts${ts}_$i',
        title: original.title,
        description: original.description,
        coverUrl: original.coverUrl,
        videoUrl: original.videoUrl,
        type: original.type,
        orientation: original.orientation,
        quality: original.quality,
        aiTag: original.aiTag,
        relatedSearchKeyword: original.relatedSearchKeyword,
        imageUrls: original.imageUrls,
        author: original.author,
        commentCount: original.commentCount,
        likeCount: original.likeCount,
        shareCount: original.shareCount,
      ));
      _shownOriginalIds.add(original.id);
    }

    _items.addAll(nextPage);
    _isLoading = false;
    notifyListeners();
  }

  /// 为本地服务器视频构造不同清晰度的 URL
  String? _buildQualityUrl(String baseUrl, String quality) {
    if (!baseUrl.startsWith(_serverBase)) return null;
    final idx = baseUrl.lastIndexOf('.');
    if (idx == -1) return null;
    var name = baseUrl.substring(0, idx);
    name = name.replaceAll(RegExp(r'_(480p|720p|1080p)$'), '');
    return '${name}_$quality${baseUrl.substring(idx)}';
  }

  /// 切换清晰度：销毁旧控制器 → 用新 URL 重建 → Seek 回原进度
  Future<void> switchQuality(String itemId, String quality) async {
    final entry = _pool[itemId];
    if (entry == null) return;

    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;
    final newUrl = _buildQualityUrl(_items[idx].videoUrl!, quality);
    if (newUrl == null) return;

    final wasPlaying = entry.controller.value.isPlaying;
    final pos = entry.controller.value.position;

    // 销毁旧控制器
    try {
      await entry.controller.pause();
      await entry.controller.dispose();
    } catch (_) {}

    // 用新 URL 创建控制器
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(newUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    final newEntry = _PlayerEntry(controller);
    _pool[itemId] = newEntry;

    controller.addListener(() {
      if (controller.value.hasError) {
        developer.log(
            '🚨 [RuntimeError] $itemId | '
            'errorDescription=${controller.value.errorDescription}',
            name: 'PlayerPool');
      }
    });

    _qualityUrlCache[itemId] = newUrl;

    try {
      await controller.initialize();
    } catch (_) {
      return;
    }
    newEntry.initializedAt = DateTime.now();

    // 恢复进度和播放状态
    try {
      await controller.seekTo(pos);
    } catch (_) {}
    if (wasPlaying && itemId == _activeVideoId) {
      controller.play();
    }

    notifyListeners();
    developer.log('🔄 [Quality] $itemId → $quality, url=$newUrl', name: 'PlayerPool');
  }

  /// 获取当前 item 的可用清晰度列表（仅本地服务器视频）
  List<String> availableQualities(String itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return ['1080p'];
    final baseUrl = _items[idx].videoUrl;
    if (baseUrl == null || !baseUrl.startsWith(_serverBase)) return ['1080p'];
    return ['480p', '720p', '1080p'];
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
