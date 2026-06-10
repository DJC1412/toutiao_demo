import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/feed_item.dart';
import '../widgets/interaction_buttons.dart';

/// 横屏全屏沉浸式播放页
///
/// 进入 → 强制横屏 + 隐藏系统 UI
/// 退出 → 恢复竖屏 + 显示系统 UI
class FullscreenVideoPage extends StatefulWidget {
  final FeedItem item;
  final VideoPlayerController controller;
  final VoidCallback? onExit;
  final String initialQuality;
  final ValueChanged<String>? onQualityChanged;

  const FullscreenVideoPage({
    super.key,
    required this.item,
    required this.controller,
    this.onExit,
    this.initialQuality = '1080p',
    this.onQualityChanged,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  VoidCallback? _listener;
  bool _isSliderDragging = false;
  double _sliderValue = 0.0;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _isExiting = false;
  late String _selectedQuality;
  bool _showQualityPanel = false;
  final GlobalKey _qualityKey = GlobalKey();

  VideoPlayerController get _ctrl => widget.controller;

  bool get _initialized => _ctrl.value.isInitialized;
  bool get _isPlaying => _initialized && _ctrl.value.isPlaying;
  Duration get _position =>
      _initialized ? _ctrl.value.position : Duration.zero;
  Duration get _duration =>
      _initialized ? _ctrl.value.duration : Duration.zero;
  double get _progress {
    if (!_initialized || _duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.initialQuality;
    _lockLandscape();
    _attachListener();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _detachListener();
    _restorePortrait();
    super.dispose();
  }

  void _lockLandscape() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restorePortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _attachListener() {
    _listener = () {
      if (!mounted || _isSliderDragging) return;
      _safeSetState();
    };
    _ctrl.addListener(_listener!);
  }

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

  void _detachListener() {
    if (_listener != null) _ctrl.removeListener(_listener!);
    _listener = null;
  }

  /// 退出：黑幕覆盖 → 回调通知外部（由外部处理转屏+移除OverlayEntry）
  void _exit() {
    if (_isExiting) return;
    setState(() => _isExiting = true);
    widget.onExit?.call();
  }

  // ═══════════════════════════════════════════════════════
  // 菜单显隐 + 3 秒自动关闭定时器
  // ═══════════════════════════════════════════════════════
  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  // 定时器在拖拽 Slider 期间暂停
  void _onSliderDragStart(double v) {
    _hideTimer?.cancel();
    _isSliderDragging = true;
    _sliderValue = v;
    _ctrl.pause();
    setState(() {});
  }

  void _onSliderDragUpdate(double v) {
    _sliderValue = v;
    setState(() {});
  }

  void _onSliderDragEnd(double v) {
    final ms = (_duration.inMilliseconds.toDouble() * v).round();
    _ctrl.seekTo(Duration(milliseconds: ms));
    _ctrl.play();
    _isSliderDragging = false;
    setState(() {});
    _startHideTimer(); // 拖拽结束后重新开始倒计时
  }

  // ═══════════════════════════════════════════════════════
  // 播放/暂停 —— 仅由中央按钮触发
  // ═══════════════════════════════════════════════════════
  void _togglePlayPause() {
    if (!_initialized) return;
    if (_isPlaying) {
      _ctrl.pause();
    } else {
      _ctrl.play();
    }
    setState(() {});
    _startHideTimer();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ═══════════════════════════════════════════════════════
  // 渲染
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dp = _isSliderDragging ? _sliderValue : _progress;
    final dPos = _isSliderDragging && _duration.inMilliseconds > 0
        ? Duration(
            milliseconds:
                (_duration.inMilliseconds.toDouble() * _sliderValue).round())
        : _position;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ═════════════════════════════════════════════
              // 第一层：视频像素级填满全屏
              // ═════════════════════════════════════════════
              if (_initialized)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _ctrl.value.size.width,
                      height: _ctrl.value.size.height,
                      child: VideoPlayer(_ctrl),
                    ),
                  ),
                ),

              // ═════════════════════════════════════════════
              // 第二层：播控交互覆盖层
              // ═════════════════════════════════════════════

              // 中央播放/暂停
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(51),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 顶部栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: _buildTopBar(),
                  ),
                ),
              ),

              // 底部栏
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: _buildBottomBar(dp, dPos),
                  ),
                ),
              ),

              // ── 清晰度 popup（定位在芯片正上方）──
              if (_showQualityPanel)
                ..._buildQualityPopup(),

              // ── 纯黑遮罩：退出过渡 ──
              if (_isExiting)
                Positioned.fill(
                  child: Container(color: Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(180), Colors.transparent],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _exit,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage(
                      AuthorAvatar.url(widget.item.author)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        widget.item.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double dp, Duration dPos) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withAlpha(200), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Text(_fmt(dPos),
              style: TextStyle(
                  color: Colors.white.withAlpha(200), fontSize: 10)),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 2.5,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.redAccent,
                inactiveTrackColor: Color(0x33FFFFFF),
                thumbColor: Colors.redAccent,
                overlayColor: Color(0x0AFF0000),
              ),
              child: Slider(
                value: dp,
                min: 0.0,
                max: 1.0,
                onChangeStart: _initialized ? _onSliderDragStart : null,
                onChanged: _initialized ? _onSliderDragUpdate : null,
                onChangeEnd: _initialized ? _onSliderDragEnd : null,
              ),
            ),
          ),
          Text(_fmt(_duration),
              style: TextStyle(
                  color: Colors.white.withAlpha(200), fontSize: 10)),
          const SizedBox(width: 6),
          _buildQualityChip(),
          const SizedBox(width: 12),
          _actionBtn(Icons.favorite, '${widget.item.likeCount}'),
          const SizedBox(width: 16),
          _actionBtn(Icons.chat_bubble, '${widget.item.commentCount}'),
          const SizedBox(width: 16),
          _actionBtn(Icons.star, '${widget.item.shareCount}'),
          const SizedBox(width: 16),
          _actionBtn(Icons.reply, '分享'),
        ],
      ),
    );
  }

  static const _qualities = ['480p', '720p', '1080p'];

  Widget _buildQualityChip() {
    return GestureDetector(
      key: _qualityKey,
      behavior: HitTestBehavior.opaque,
      onTap: _toggleQualityPanel,
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
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 12, color: Colors.white.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  void _toggleQualityPanel() {
    _hideTimer?.cancel();
    setState(() => _showQualityPanel = !_showQualityPanel);
  }

  List<Widget> _buildQualityPopup() {
    final ctx = _qualityKey.currentContext;
    if (ctx == null) return [const SizedBox.shrink()];

    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final chipW = box.size.width;
    final popupH = _qualities.length * 36.0;

    final screenH = MediaQuery.of(context).size.height;
    final top = (offset.dy - popupH - 4).clamp(0.0, screenH);
    final left = (offset.dx + chipW / 2 - 60).clamp(0.0, double.infinity);

    return [
      Positioned.fill(
        child: ModalBarrier(
          onDismiss: () {
            _showQualityPanel = false;
            _startHideTimer();
          },
        ),
      ),
      // popup
      Positioned(
        top: top,
        left: left,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _qualities.map((q) {
                final isSelected = _selectedQuality == q;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectQuality(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ];
  }

  void _selectQuality(String quality) {
    setState(() {
      _selectedQuality = quality;
      _showQualityPanel = false;
    });
    widget.onQualityChanged?.call(quality);
    _startHideTimer();
  }

  Widget _actionBtn(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
