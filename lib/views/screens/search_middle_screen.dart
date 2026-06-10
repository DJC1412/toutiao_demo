import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';

/// 页面2：搜索中间页（含键盘拉起、历史词网格）
class SearchMiddleScreen extends StatefulWidget {
  const SearchMiddleScreen({super.key});

  @override
  State<SearchMiddleScreen> createState() => _SearchMiddleScreenState();
}

class _SearchMiddleScreenState extends State<SearchMiddleScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<SearchProvider>().loadHistory();
    // 延迟拉起键盘，确保页面过渡动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final provider = context.read<SearchProvider>();
    provider.search(trimmed); // 异步权重搜索，结果通过 notifyListeners 更新
    Navigator.pushNamed(context, '/result');
  }

  void _onTapHistory(String keyword) {
    _controller.text = keyword;
    _onSearch(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final history = provider.searchHistory;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '搜索视频',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearch,
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    provider.clearResults();
                  },
                  child:
                      Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 历史记录标题栏 ──
          if (history.isNotEmpty) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('搜索历史',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('清空搜索历史'),
                          content: const Text('确定要清空所有搜索历史吗？'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('取消')),
                            TextButton(
                                onPressed: () {
                                  context.read<SearchProvider>().clearHistory();
                                  Navigator.pop(ctx);
                                },
                                child: const Text('确定',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                    },
                    child: Icon(Icons.delete_outline,
                        size: 20, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // ── 历史词网格 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(history.length, (index) {
                  final keyword = history[index];
                  return GestureDetector(
                    onTap: () => _onTapHistory(keyword),
                    child: Chip(
                      label: Text(keyword, style: const TextStyle(fontSize: 13)),
                      backgroundColor: Colors.grey.shade100,
                      deleteIcon: Icon(Icons.close,
                          size: 16, color: Colors.grey.shade500),
                      onDeleted: () =>
                          provider.deleteHistoryItem(index),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }),
              ),
            ),
          ],

          // ── 热门推荐（引导词，取自 MockData 中的 relatedSearchKeyword） ──
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 24, bottom: 12),
            child: Text('热门搜索',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          _buildHotWords(),
        ],
      ),
    );
  }

  Widget _buildHotWords() {
    const hotWords = [
      '华为Mate80价格',
      '天水麻辣烫',
      '318国道最新路况',
      '湖人vs勇士全场回放',
      '周杰伦演唱会',
      '黑神话悟空DLC',
      '小米SU7落地价',
      '哪吒之魔童闹海',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: hotWords.map((word) {
          return ActionChip(
            label: Text(word,
                style:
                    TextStyle(fontSize: 13, color: Colors.red.shade600)),
            backgroundColor: Colors.red.shade50,
            onPressed: () => _onTapHistory(word),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }
}
