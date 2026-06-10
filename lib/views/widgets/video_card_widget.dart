import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/feed_item.dart';
import '../../providers/search_provider.dart';
import '../../providers/video_flow_provider.dart';
import '../screens/fullscreen_video_page.dart';
import 'interaction_buttons.dart';

class VideoCardWidget extends StatefulWidget {
  final FeedItem item;
  final VideoPlayerController? controller;
  final bool isActive;
  final VoidCallback? onTogglePlay;

  const VideoCardWidget({
    super.key,
    required this.item,
    this.controller,
    this.isActive = false,
    this.onTogglePlay,
  });

  @override
  State<VideoCardWidget> createState() => _VideoCardWidgetState();
}

class _VideoCardWidgetState extends State<VideoCardWidget> {
  VoidCallback? _listener;
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _isExpanded = false;
  bool _hasAutoStarted = false;
  late String _selectedQuality;

  bool get _isInitialized =>
      widget.controller != null && widget.controller!.value.isInitialized;
  bool get _isPlaying =>
      _isInitialized && widget.controller!.value.isPlaying;
  bool get _isHorizontal =>
      _isInitialized && widget.controller!.value.aspectRatio > 1.0;
  Duration get _position =>
      _isInitialized ? widget.controller!.value.position : Duration.zero;
  Duration get _duration =>
      _isInitialized ? widget.controller!.value.duration : Duration.zero;
  double get _progress {
    if (!_isInitialized || _duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.item.quality;
    _attachListener();
    _tryAutoPlay();
  }

  @override
  void didUpdateWidget(covariant VideoCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 控制器切换：重新挂载 listener
    if (oldWidget.controller != widget.controller ||
        (oldWidget.controller != null &&
            !oldWidget.controller!.value.isInitialized &&
            widget.controller != null &&
            widget.controller!.value.isInitialized)) {
      _detachListener();
      _hasAutoStarted = false;
      _attachListener();
    }
    // 翻到本页 → 立即自动播放（若已初始化）
    if (!oldWidget.isActive && widget.isActive) {
      _isExpanded = false;
      _hasAutoStarted = false;
      _tryAutoPlay();
    }
    // 滑走本页 → 立即暂停
    if (oldWidget.isActive && !widget.isActive) {
      widget.controller?.pause();
    }
  }

  void _attachListener() {
    if (widget.controller == null) return;
    _listener = () {
      if (!mounted || _isDragging) return;
      _tryAutoPlay();
      _safeSetState();
    };
    widget.controller!.addListener(_listener!);
  }

  /// 安全 setState：避免在 build 阶段触发导致 FlutterError
  void _safeSetState() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  /// 条件：已初始化 + 当前激活页 + 还没自动播放过 → 播放
  void _tryAutoPlay() {
    if (!_hasAutoStarted && _isInitialized && widget.isActive) {
      _hasAutoStarted = true;
      widget.controller!.play();
    }
  }

  void _detachListener() {
    if (widget.controller != null && _listener != null) {
      widget.controller!.removeListener(_listener!);
    }
    _listener = null;
  }

  @override
  void dispose() {
    _detachListener();
    _fullscreenEntry?.remove();
    _fullscreenEntry = null;
    super.dispose();
  }

  void _onDragStart(double v) {
    if (!_isInitialized) return;
    _isDragging = true;
    _dragValue = v;
    widget.controller!.pause();
    setState(() {});
  }

  void _onDragUpdate(double v) {
    _dragValue = v;
    setState(() {});
  }

  void _onDragEnd(double v) {
    if (!_isInitialized) return;
    final ms = (_duration.inMilliseconds.toDouble() * v).round();
    widget.controller!.seekTo(Duration(milliseconds: ms));
    widget.controller!.play();
    _isDragging = false;
    setState(() {});
  }

  // ═══════════════════════════════════════════════════════════════
  // 全屏 Stack：三层独立图层，彻底隔离
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dp = _isDragging ? _dragValue : _progress;
    final dPos = _isDragging && _duration.inMilliseconds > 0
        ? Duration(
            milliseconds: (_duration.inMilliseconds.toDouble() * _dragValue).round())
        : _position;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ═══════════════════════════════════════════════════
        // 图层一：全屏视频 (最底层)
        // ═══════════════════════════════════════════════════
        if (_isInitialized)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTogglePlay,
              child: Center(
                child: _isHorizontal
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio: widget.controller!.value.aspectRatio,
                            child: VideoPlayer(widget.controller!),
                          ),
                          const SizedBox(height: 6),
                          _buildFullscreenBtn(context),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio: widget.controller!.value.aspectRatio,
                            child: VideoPlayer(widget.controller!),
                          ),
                          if (!widget.item.isVerticalVideo) ...[
                            const SizedBox(height: 6),
                            _buildFullscreenBtn(context),
                          ],
                        ],
                      ),
              ),
            ),
          )
        else
          Positioned.fill(child: _buildCover()),

        // 居中播放按钮 —— 独立手势，点击图标也能触发播控
        if (!_isPlaying)
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTogglePlay,
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 56),
            ),
          ),

        // 加载指示器
        if (!_isInitialized && widget.isActive)
          const Center(
            child: SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          ),

        // ═══════════════════════════════════════════════════
        // 图层二：右侧互动栏 + 左下角文字 (中间层)
        // ═══════════════════════════════════════════════════
        Positioned(
          right: 12,
          bottom: 100,
          child: InteractionButtons(item: widget.item),
        ),

        Positioned(
          left: 16,
          right: 100,
          bottom: 70, // ★ 死命令：距离屏幕底部悬空 70px
          child: _buildTextLayer(),
        ),

        // ═══════════════════════════════════════════════════
        // 图层三：进度条 (Z 轴最高层，独立于文字)
        // ═══════════════════════════════════════════════════
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(top: 25, bottom: 15, left: 8, right: 8),
              child: Row(
                  children: [
                    Text(_fmt(dPos),
                        style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11)),
                    Expanded(
                      child: SliderTheme(
                        data: const SliderThemeData(
                          trackHeight: 3,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
                          activeTrackColor: Colors.redAccent,
                          inactiveTrackColor: Color(0x33FFFFFF),
                          thumbColor: Colors.redAccent,
                          overlayColor: Color(0x0AFF0000),
                        ),
                        child: Slider(
                          value: dp,
                          min: 0.0,
                          max: 1.0,
                          onChangeStart: _isInitialized ? _onDragStart : null,
                          onChanged: _isInitialized ? _onDragUpdate : null,
                          onChangeEnd: _isInitialized ? _onDragEnd : null,
                        ),
                      ),
                    ),
                    Text(_fmt(_duration),
                        style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11)),
                    const SizedBox(width: 8),
                    _buildQualityChip(),
                  ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  OverlayEntry? _fullscreenEntry;

  void _openFullscreen() {
    if (_fullscreenEntry != null || widget.controller == null || widget.item.isVerticalVideo) return;
    final overlay = Overlay.of(context);
    _fullscreenEntry = OverlayEntry(
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: FullscreenVideoPage(
          item: widget.item,
          controller: widget.controller!,
          onExit: _closeFullscreen,
          initialQuality: _selectedQuality,
          onQualityChanged: (q) { _selectedQuality = q; },
        ),
      ),
    );
    overlay.insert(_fullscreenEntry!);
  }

  Future<void> _closeFullscreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Future.delayed(const Duration(milliseconds: 200));
    _fullscreenEntry?.remove();
    _fullscreenEntry = null;
  }

  Widget _buildFullscreenBtn(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openFullscreen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withAlpha(100), width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fullscreen, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text('全屏播放',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 文字层：作者 + 描述(限高局部滚动) + 展开/收起按钮(在滚动区外)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTextLayer() {
    final text = '${widget.item.title}  ${widget.item.description}';
    final screenH = MediaQuery.of(context).size.height;
    // 描述区最大高度：展开时 35% 屏高，折叠时严格限 45px 保证不出界
    final maxH = _isExpanded ? screenH * 0.35 : 45.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 作者名
        GestureDetector(
          onTap: widget.onTogglePlay,
          child: Text(
            '@${widget.item.author}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // ── 限高滚动区（仅包裹文本，不包含按钮）──
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            physics: _isExpanded
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Text(
              text,
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),

        // ── 展开/收起按钮（在滚动区外，永远在 hit-test 范围内）──
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _isExpanded ? '收起' : '展开',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

        // ── 相关搜索推荐胶囊（今日头条同款）──
        _buildRelatedSearchCapsule(context),
      ],
    );
  }

  /// 今日头条同款"相关搜索"推荐胶囊
  ///
  /// 位置：作者/标题信息下方，进度条上方
  /// 样式：半透明圆角胶囊 + 搜索图标 + 关键词 + 右箭头
  /// 交互：点击携带关键词跳转搜索结果页
  Widget _buildRelatedSearchCapsule(BuildContext context) {
    final keyword = widget.item.relatedSearchKeyword.trim();
    if (keyword.isEmpty) return const SizedBox.shrink();

    // 取第一个关键词作为展示项（若以逗号分隔）
    final display = keyword.split(RegExp(r'[,，]')).first.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        context.read<VideoFlowProvider>().pauseActive();
        final sp = context.read<SearchProvider>();
        await sp.search(keyword);
        if (context.mounted) {
          Navigator.pushNamed(context, '/result');
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 14, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                '相关搜索: $display',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 14, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  static const _qualities = ['480p', '720p', '1080p'];
  final GlobalKey _qualityKey = GlobalKey();

  Widget _buildQualityChip() {
    return GestureDetector(
      key: _qualityKey,
      behavior: HitTestBehavior.opaque,
      onTap: () => _showQualityMenu(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedQuality,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: Colors.white.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  void _showQualityMenu() {
    final ctx = _qualityKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    showMenu<String>(
      context: context,
      color: const Color(0xFF2A2A2A),
      elevation: 8,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - (_qualities.length * 40 + 8),
        offset.dx + size.width,
        offset.dy - 4,
      ),
      items: _qualities.map((q) {
        final isSelected = _selectedQuality == q;
        return PopupMenuItem<String>(
          value: q,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(q,
                  style: TextStyle(
                    color: isSelected ? Colors.redAccent : Colors.white,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  )),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, color: Colors.redAccent, size: 14),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((v) {
      if (v != null) setState(() => _selectedQuality = v);
    });
  }

  Widget _buildCover() {
    final url = widget.item.coverUrl;
    final fit = widget.item.isVerticalVideo ? BoxFit.cover : BoxFit.contain;
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: fit);
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, e, s) => Container(color: Colors.black),
    );
  }
}
