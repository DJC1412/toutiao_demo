import 'package:flutter/material.dart';
import '../../data/models/feed_item.dart';
import 'interaction_buttons.dart';

/// 图文流卡片组件 —— 与 VideoCard 保持完全一致的 UI 布局规范
///
/// 核心布局：
///   图层一：全屏横向滑动图片 PageView
///   图层二：右侧互动栏 + 左下角文案（与 VideoCard 100% 对齐）
///   图层三：底部图片页码指示器（替换进度条）
class ImageCardWidget extends StatefulWidget {
  final FeedItem item;

  const ImageCardWidget({super.key, required this.item});

  @override
  State<ImageCardWidget> createState() => _ImageCardWidgetState();
}

class _ImageCardWidgetState extends State<ImageCardWidget> {
  late final PageController _imageController;
  int _currentImageIndex = 0;
  bool _isExpanded = false;

  int get _imageCount =>
      widget.item.imageUrls.isEmpty ? 1 : widget.item.imageUrls.length;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // 全屏 Stack：三层独立图层
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final urls = widget.item.imageUrls;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ═══════════════════════════════════════════════════
        // 图层一：全屏图片轮播 (最底层)
        // ═══════════════════════════════════════════════════
        Positioned.fill(
          child: urls.isEmpty
              ? Container(color: Colors.black)
              : PageView.builder(
                  controller: _imageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (context, index) {
                    return Image.network(
                      urls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, e, s) =>
                          Container(color: Colors.grey.shade900),
                    );
                  },
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
          bottom: 70,
          child: _buildTextLayer(context),
        ),

        // ═══════════════════════════════════════════════════
        // 图层三：图片页码指示器（替代视频进度条）
        // ═══════════════════════════════════════════════════
        if (urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / $_imageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 文字层：与 VideoCard 完全一致的折叠/展开逻辑
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTextLayer(BuildContext context) {
    final text = '${widget.item.title}  ${widget.item.description}';
    final screenH = MediaQuery.of(context).size.height;
    final maxH = _isExpanded ? screenH * 0.35 : 45.0;

    return Column(
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
        const SizedBox(height: 6),

        // 限高滚动区
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

        // 展开/收起按钮
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
      ],
    );
  }
}
