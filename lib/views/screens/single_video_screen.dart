import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/feed_item.dart';
import 'fullscreen_video_page.dart';
import '../widgets/interaction_buttons.dart';

class SingleVideoScreen extends StatefulWidget {
  final FeedItem item;

  const SingleVideoScreen({super.key, required this.item});

  @override
  State<SingleVideoScreen> createState() => _SingleVideoScreenState();
}

class _SingleVideoScreenState extends State<SingleVideoScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _showControls = true;
  late String _selectedQuality;
  OverlayEntry? _fullscreenEntry;

  bool get _isHorizontal =>
      _isInitialized && _controller!.value.aspectRatio > 1.0;

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.item.quality;
    _initController();
  }

  @override
  void dispose() {
    _fullscreenEntry?.remove();
    _fullscreenEntry = null;
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initController() async {
    final url = widget.item.videoUrl;
    if (url == null) return;

    final controller = url.startsWith('assets/')
        ? VideoPlayerController.asset(url)
        : VideoPlayerController.networkUrl(Uri.parse(url));

    _controller = controller;
    controller.addListener(_onControllerUpdate);
    await controller.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
      controller.play();
      setState(() => _isPlaying = true);
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _isDragging) return;
    setState(() {
      _isPlaying = _controller?.value.isPlaying ?? false;
    });
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  Duration get _position =>
      _isInitialized ? _controller!.value.position : Duration.zero;
  Duration get _duration =>
      _isInitialized ? _controller!.value.duration : Duration.zero;
  double get _progress {
    if (!_isInitialized || _duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final dp = _isDragging ? _dragValue : _progress;
    final dPos = _isDragging && _duration.inMilliseconds > 0
        ? Duration(
            milliseconds:
                (_duration.inMilliseconds.toDouble() * _dragValue).round())
        : _position;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item.title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频层
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // 播放/暂停按钮
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

            // 右侧互动栏
            if (_showControls)
              Positioned(
                right: 12,
                bottom: 100,
                child: InteractionButtons(item: widget.item),
              ),

            // 左下角信息
            if (_showControls)
              Positioned(
                left: 16,
                right: 100,
                bottom: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${widget.item.author}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((widget.item.aiTag ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildAiTags(),
                    ],
                  ],
                ),
              ),

            // 底部进度条
            if (_showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.only(
                        top: 25, bottom: 15, left: 8, right: 8),
                    child: Row(
                      children: [
                        Text(_fmt(dPos),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11)),
                        Expanded(
                          child: SliderTheme(
                            data: const SliderThemeData(
                              trackHeight: 3,
                              thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                              overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 18),
                              activeTrackColor: Colors.redAccent,
                              inactiveTrackColor: Color(0x33FFFFFF),
                              thumbColor: Colors.redAccent,
                              overlayColor: Color(0x0AFF0000),
                            ),
                            child: Slider(
                              value: dp,
                              min: 0.0,
                              max: 1.0,
                              onChangeStart: _isInitialized
                                  ? (v) {
                                      _isDragging = true;
                                      _dragValue = v;
                                      _controller?.pause();
                                      setState(() {});
                                    }
                                  : null,
                              onChanged: _isInitialized
                                  ? (v) {
                                      _dragValue = v;
                                      setState(() {});
                                    }
                                  : null,
                              onChangeEnd: _isInitialized
                                  ? (v) {
                                      final ms =
                                          (_duration.inMilliseconds.toDouble() *
                                                  v)
                                              .round();
                                      _controller?.seekTo(
                                          Duration(milliseconds: ms));
                                      _controller?.play();
                                      _isDragging = false;
                                      setState(() {});
                                    }
                                  : null,
                            ),
                          ),
                        ),
                        Text(_fmt(_duration),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11)),
                        const SizedBox(width: 8),
                        _buildQualityChip(),
                        if (_isHorizontal && !widget.item.isVerticalVideo) ...[
                          const SizedBox(width: 8),
                          _buildFullscreenBtn(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // 视频加载中
            if (!_isInitialized)
              const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen() {
    if (_fullscreenEntry != null || _controller == null || !_isInitialized) return;
    if (widget.item.isVerticalVideo) return;
    final overlay = Overlay.of(context);
    _fullscreenEntry = OverlayEntry(
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: FullscreenVideoPage(
          item: widget.item,
          controller: _controller!,
          onExit: _closeFullscreen,
          initialQuality: _selectedQuality,
          onQualityChanged: (q) => setState(() => _selectedQuality = q),
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

  Widget _buildFullscreenBtn() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openFullscreen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fullscreen, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('全屏',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
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

  Widget _buildAiTags() {
    final tag = widget.item.aiTag!;
    final tags = tag.split(RegExp(r'[,，]'));
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((t) {
        final trimmed = t.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            trimmed,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }
}
