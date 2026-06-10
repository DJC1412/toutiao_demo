/// 内容类型枚举
enum FeedType { video, image }

/// 混合流内容数据模型（含视频/图文、AI推荐词）
class FeedItem {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String? videoUrl;
  final FeedType type;
  final String? orientation;
  final String quality;
  final String? aiTag;
  final String relatedSearchKeyword;
  final List<String> imageUrls;
  final String author;
  final int commentCount;
  final int likeCount;
  final int shareCount;

  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    this.videoUrl,
    required this.type,
    this.orientation,
    this.quality = '1080p',
    this.aiTag,
    required this.relatedSearchKeyword,
    this.imageUrls = const [],
    this.author = '',
    this.commentCount = 0,
    this.likeCount = 0,
    this.shareCount = 0,
  });

  bool get isVideo => type == FeedType.video;

  bool get isVerticalVideo => orientation == 'vertical';
}
