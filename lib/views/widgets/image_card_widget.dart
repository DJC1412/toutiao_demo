import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/feed_item.dart';
import '../../providers/search_provider.dart';
import '../../providers/video_flow_provider.dart';
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
    final maxH = _isExpanded ? 200.0 : 55.0;

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

        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            physics: _isExpanded
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  maxLines: _isExpanded ? null : 1,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.item.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
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

        // 相关搜索推荐胶囊
        _buildRelatedSearchCapsule(context),
      ],
    );
  }

  /// 相关搜索词标签按钮：每个词独立跳转搜索
  Widget _buildRelatedSearchCapsule(BuildContext context) {
    final keyword = widget.item.relatedSearchKeyword.trim();
    if (keyword.isEmpty) return const SizedBox.shrink();

    final tags = keyword.split(RegExp(r'[,，]')).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags.map((tag) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              context.read<VideoFlowProvider>().pauseActive();
              final sp = context.read<SearchProvider>();
              await sp.search(tag);
              if (context.mounted) {
                Navigator.pushNamed(context, '/result');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    tag,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
