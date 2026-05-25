import 'package:flutter/material.dart';
import '../../data/models/feed_item.dart';

/// 作者头像工具：相同作者 → 相同头像，使用 picsum seed 稳定映射
class AuthorAvatar {
  static String url(String author) {
    final seed = author.hashCode.abs();
    return 'https://picsum.photos/seed/$seed/200';
  }
}

/// 右侧纵向操作栏（头像 + 互动图标）
class InteractionButtons extends StatelessWidget {
  final FeedItem item;

  const InteractionButtons({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 头像 + 关注按钮 ──
        _buildAvatar(),
        const SizedBox(height: 28),
        _buildIcon(Icons.favorite, '${item.likeCount}'),
        const SizedBox(height: 18),
        _buildIcon(Icons.chat_bubble, '${item.commentCount}'),
        const SizedBox(height: 18),
        _buildIcon(Icons.star, '${item.shareCount}'),
        const SizedBox(height: 18),
        _buildIcon(Icons.reply, '分享'),
      ],
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = AuthorAvatar.url(item.author);
    return SizedBox(
      width: 44,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 头像外圈精细白边框
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 1.5)),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: NetworkImage(avatarUrl),
              onBackgroundImageError: (_, e) {},
            ),
          ),
          // 底部居中红色 + 号关注按钮
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: const Icon(Icons.add, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white,
            size: icon == Icons.favorite
                ? 38
                : icon == Icons.chat_bubble
                    ? 32
                    : icon == Icons.star
                        ? 34
                        : 34),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
