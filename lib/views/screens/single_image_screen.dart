import 'package:flutter/material.dart';
import '../../data/models/feed_item.dart';
import '../widgets/interaction_buttons.dart';

class SingleImageScreen extends StatefulWidget {
  final FeedItem item;

  const SingleImageScreen({super.key, required this.item});

  @override
  State<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends State<SingleImageScreen> {
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

  @override
  Widget build(BuildContext context) {
    final urls = widget.item.imageUrls;

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 图片层
          Positioned.fill(
            child: urls.isEmpty
                ? Container(color: Colors.grey.shade900)
                : PageView.builder(
                    controller: _imageController,
                    scrollDirection: Axis.horizontal,
                    itemCount: urls.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      final url = urls[index];
                      if (url.startsWith('assets/')) {
                        return Image.asset(url, fit: BoxFit.contain);
                      }
                      return Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, e, s) =>
                            Container(color: Colors.grey.shade900),
                      );
                    },
                  ),
          ),

          // 右侧互动栏
          Positioned(
            right: 12,
            bottom: 100,
            child: InteractionButtons(item: widget.item),
          ),

          // 左下角信息
          Positioned(
            left: 16,
            right: 100,
            bottom: 80,
            child: _buildTextLayer(),
          ),

          // 图片页码
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
      ),
    );
  }

  Widget _buildTextLayer() {
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
        if ((widget.item.aiTag ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildAiTags(),
        ],
      ],
    );
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
