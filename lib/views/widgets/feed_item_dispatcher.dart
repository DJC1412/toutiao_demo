import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/feed_item.dart';
import 'video_card_widget.dart';
import 'image_card_widget.dart';

/// 混合模板分发器（判断渲染视频卡片还是图文卡片）
class FeedItemDispatcher extends StatelessWidget {
  final FeedItem item;
  final VideoPlayerController? controller;
  final bool isActive;
  final VoidCallback? onTogglePlay;

  const FeedItemDispatcher({
    super.key,
    required this.item,
    this.controller,
    this.isActive = false,
    this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    if (item.type == FeedType.video) {
      return VideoCardWidget(
        item: item,
        controller: controller,
        isActive: isActive,
        onTogglePlay: onTogglePlay,
      );
    }
    return ImageCardWidget(item: item);
  }
}
