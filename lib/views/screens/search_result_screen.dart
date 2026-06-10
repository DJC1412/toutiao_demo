import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/video_flow_provider.dart';
import '../../data/models/feed_item.dart';
import 'single_video_screen.dart';

/// 搜索结果页（视频列表，点击进入单独播放页）
class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key});

  void _onTapResult(BuildContext context, FeedItem item) {
    if (item.isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SingleVideoScreen(item: item)),
      );
    } else {
      context.read<VideoFlowProvider>().requestJumpToItem(item.id);
      Navigator.popUntil(context, ModalRoute.withName('/'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final results = provider.searchResults;
    final query = provider.currentQuery;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('搜索 "$query"',
            style: const TextStyle(color: Colors.black, fontSize: 16)),
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('没有找到相关视频',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('换个关键词试试吧',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              separatorBuilder: (_, i) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final item = results[index];
                return _ResultRow(
                  item: item,
                  onTap: () => _onTapResult(context, item),
                );
              },
            ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const _ResultRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // ── 封面缩略图 ──
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.coverUrl,
                  width: 120,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) =>
                      Container(width: 120, height: 72, color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(width: 12),
              // ── 文字信息 ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(item.author,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                        if (item.aiTag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              item.aiTag!,
                              style: TextStyle(
                                  color: Colors.blue.shade400, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.isVideo) ...[
                          Icon(Icons.play_circle_filled,
                              size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 2),
                          Text('视频',
                              style: TextStyle(
                                  color: Colors.red.shade400, fontSize: 11)),
                        ] else ...[
                          Icon(Icons.photo_library,
                              size: 14, color: Colors.blue.shade400),
                          const SizedBox(width: 2),
                          Text('图文',
                              style: TextStyle(
                                  color: Colors.blue.shade400, fontSize: 11)),
                        ],
                        const SizedBox(width: 12),
                        Text('${item.commentCount} 评论',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
