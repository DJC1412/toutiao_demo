import 'dart:math';
import '../models/feed_item.dart';

/// 本地 Mock 数据仓库（单例）
///
/// - `fetchFeedByPage`：顺序分页（搜索回跳等场景）
/// - `fetchRecommendFeeds`：洗牌算法随机抽取 + 时间戳防重 ID（无限流场景）
/// - `searchFeed`：权重评分搜索
class FeedRepository {
  FeedRepository._();
  static final FeedRepository _instance = FeedRepository._();
  static FeedRepository get instance => _instance;

  final _random = Random();

  static const _base = 'http://192.168.2.8:8080';

  // ═══════════════════════════════════════════════════════
  // 中央数据池
  // ═══════════════════════════════════════════════════════
  final List<FeedItem> _centralPool = [
    // ── 网络视频 (公开测试源) ──
    const FeedItem(
      id: 'v001',
      title: '国产 3D 动画史诗级黑马预告！这特效和画质直接燃爆了',
      description: '东方奇幻大作震撼来袭，全程高能打斗，国漫崛起的巅峰之作？',
      coverUrl: 'https://picsum.photos/seed/dragon/400/600',
      videoUrl: 'https://media.w3.org/2010/05/sintel/trailer_hd.mp4',
      type: FeedType.video,
      orientation: 'horizontal',
      aiTag: '动漫,3D,预告片',
      relatedSearchKeyword: '国漫推荐,3D动画电影,燃向剪辑',
      author: '动画学术趴',
      commentCount: 5600,
      likeCount: 132000,
      shareCount: 28900,
    ),
    const FeedItem(
      id: 'v002',
      title: '极度治愈！4K 深海潜水：与水母和热带鱼共舞',
      description: '跟随镜头探索未知海洋世界，解压放松必看，戴上耳机效果更佳。',
      coverUrl: 'https://picsum.photos/seed/jellyfish/400/600',
      videoUrl: 'https://vjs.zencdn.net/v/oceans.mp4',
      type: FeedType.video,
      orientation: 'horizontal',
      aiTag: '自然,海洋,治愈',
      relatedSearchKeyword: '4K壁纸,深海纪录片,解压视频',
      author: '海洋摄影师',
      commentCount: 8900,
      likeCount: 215000,
      shareCount: 67000,
    ),
    const FeedItem(
      id: 'v003',
      title: '爆笑解压：森林里的大胖兔子被小松鼠整蛊，结局笑翻了',
      description: '疯狂动物城现实版！专治各种不开心。',
      coverUrl: 'https://picsum.photos/seed/bunny/400/600',
      videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      type: FeedType.video,
      orientation: 'horizontal',
      aiTag: '搞笑,动画,解压',
      relatedSearchKeyword: '搞笑短片,动物动画,治愈系',
      author: '每日一笑',
      commentCount: 15600,
      likeCount: 380000,
      shareCount: 92000,
    ),

    // ── 本地服务器视频 ──
    const FeedItem(
      id: 'BV1EpccznEyu',
      title: '六年青春，两座坟墓，4分40秒',
      description: '海浪拍打着汐斯塔的沙滩，圆梦村的雪依旧无声飘落。\n\n生命是迫近的死亡，死亡是活过的生命。',
      coverUrl: '$_base/covers/BV1EpccznEyu.jpg',
      videoUrl: '$_base/videos/BV1EpccznEyu.mp4',
      type: FeedType.video,
      orientation: 'vertical',
      quality: '1080p',
      aiTag: '我的世界,厦门,明日方舟',
      relatedSearchKeyword: '我的世界,厦门,热门推荐',
      author: '四月十六April',
      commentCount: 17141,
      likeCount: 500028,
      shareCount: 29431,
    ),
    const FeedItem(
      id: 'BV1DSC8BkE7R',
      title: '帝国VS家庭',
      description: '帝国VS家庭',
      coverUrl: '$_base/covers/BV1DSC8BkE7R.jpg',
      videoUrl: '$_base/videos/BV1DSC8BkE7R.mp4',
      type: FeedType.video,
      orientation: 'horizontal',
      quality: '1080p',
      aiTag: '亲情,剪辑,无敌少侠',
      relatedSearchKeyword: '亲情,剪辑,热门推荐',
      author: 'HH_DKN',
      commentCount: 1642,
      likeCount: 130774,
      shareCount: 2260,
    ),

    // ── 图文类 ──
    const FeedItem(
      id: 'i001',
      title: '全球十大最美书店：每一家都值得专程飞一趟',
      description: '从巴黎莎士比亚到东京茑屋，那些让阅读变成朝圣的地方。',
      coverUrl: 'https://picsum.photos/seed/bookstore/400/600',
      type: FeedType.image,
      aiTag: '旅行,文艺,书店',
      relatedSearchKeyword: '最美书店,旅行打卡,文艺生活',
      imageUrls: [
        'https://picsum.photos/seed/bs1/400/300',
        'https://picsum.photos/seed/bs2/400/300',
        'https://picsum.photos/seed/bs3/400/300',
      ],
      author: '孤独星球',
      commentCount: 7800,
      likeCount: 210000,
      shareCount: 87000,
    ),
    const FeedItem(
      id: 'i002',
      title: '2026 秋冬时装周街拍精选：60 张图看尽最新穿搭趋势',
      description: '米兰、巴黎、纽约三大时装周场外街拍，教你穿出高级感。',
      coverUrl: 'https://picsum.photos/seed/fashion/400/600',
      type: FeedType.image,
      aiTag: '时尚,穿搭,时装周',
      relatedSearchKeyword: '穿搭灵感,时尚趋势,秋冬穿搭',
      imageUrls: [
        'https://picsum.photos/seed/fw1/400/300',
        'https://picsum.photos/seed/fw2/400/300',
        'https://picsum.photos/seed/fw3/400/300',
        'https://picsum.photos/seed/fw4/400/300',
      ],
      author: 'VOGUE中国',
      commentCount: 3400,
      likeCount: 125000,
      shareCount: 56000,
    ),
    const FeedItem(
      id: 'i003',
      title: '烘焙新手必看：7 天做出比面包店还好吃的欧包',
      description: '从鲁邦种到出炉全图解，家庭烤箱也能烤出完美气孔。',
      coverUrl: 'https://picsum.photos/seed/bread/400/600',
      type: FeedType.image,
      aiTag: '美食,烘焙,教程',
      relatedSearchKeyword: '烘焙新手,面包教程,家庭烘焙',
      imageUrls: [
        'https://picsum.photos/seed/br1/400/300',
        'https://picsum.photos/seed/br2/400/300',
        'https://picsum.photos/seed/br3/400/300',
        'https://picsum.photos/seed/br4/400/300',
        'https://picsum.photos/seed/br5/400/300',
      ],
      author: '君之烘焙',
      commentCount: 12300,
      likeCount: 320000,
      shareCount: 156000,
    ),
    const FeedItem(
      id: 'i004',
      title: '韦伯望远镜拍下宇宙最深处：130 亿年前的星系光芒',
      description: 'NASA 公布最新深空照片合集，令人窒息的宇宙之美。',
      coverUrl: 'https://picsum.photos/seed/webb/400/600',
      type: FeedType.image,
      aiTag: '科学,天文,科普',
      relatedSearchKeyword: '宇宙探索,天文摄影,韦伯望远镜',
      imageUrls: [
        'https://picsum.photos/seed/wb1/400/300',
        'https://picsum.photos/seed/wb2/400/300',
        'https://picsum.photos/seed/wb3/400/300',
      ],
      author: 'NASA中文',
      commentCount: 8900,
      likeCount: 245000,
      shareCount: 78000,
    ),
  ];

  /// 获取指定 ID 在全量池中的索引
  int indexOfItem(String id) {
    return _centralPool.indexWhere((item) => item.id == id);
  }

  /// 获取全量池（仅 PageView 初始化用）
  List<FeedItem> getAllItems() => List.unmodifiable(_centralPool);

  // ═══════════════════════════════════════════════════════
  // 分页拉取
  // ═══════════════════════════════════════════════════════

  /// 模拟网络分页：延迟 500ms 返回裁剪后的数据页
  Future<List<FeedItem>> fetchFeedByPage({
    required int page,
    int pageSize = 5,
  }) async {
    final start = page * pageSize;
    if (start >= _centralPool.length) return [];
    final end = (start + pageSize).clamp(0, _centralPool.length);
    return List.unmodifiable(_centralPool.sublist(start, end));
  }

  // ═══════════════════════════════════════════════════════
  // 随机推荐流（洗牌算法 + 时间戳防重 ID）
  // ═══════════════════════════════════════════════════════

  Future<List<FeedItem>> fetchRecommendFeeds({
    required int page,
    int pageSize = 5,
  }) async {
    final pool = List<FeedItem>.from(_centralPool);
    pool.shuffle(_random);

    final end = pageSize.clamp(0, pool.length);
    final batch = pool.sublist(0, end);

    final ts = DateTime.now().microsecondsSinceEpoch;
    final result = <FeedItem>[];
    for (int i = 0; i < batch.length; i++) {
      final original = batch[i];
      result.add(
        FeedItem(
          id: '${original.id}_ts${ts}_$i',
          title: original.title,
          description: original.description,
          coverUrl: original.coverUrl,
          videoUrl: original.videoUrl,
          type: original.type,
          orientation: original.orientation,
          quality: original.quality,
          aiTag: original.aiTag,
          relatedSearchKeyword: original.relatedSearchKeyword,
          imageUrls: original.imageUrls,
          author: original.author,
          commentCount: original.commentCount,
          likeCount: original.likeCount,
          shareCount: original.shareCount,
        ),
      );
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════
  // 权重评分搜索
  // ═══════════════════════════════════════════════════════

  Future<List<FeedItem>> searchFeed(String keyword) async {
    final lower = keyword.trim().toLowerCase();
    if (lower.isEmpty) return [];

    final scored = <_ScoredItem>[];
    for (final item in _centralPool) {
      int score = 0;
      if (item.title.toLowerCase().contains(lower)) score += 10;
      if (item.relatedSearchKeyword.toLowerCase().contains(lower)) score += 6;
      if ((item.aiTag ?? '').toLowerCase().contains(lower)) score += 4;
      if (item.description.toLowerCase().contains(lower)) score += 2;
      if (score > 0) scored.add(_ScoredItem(item, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.item).toList();
  }
}

/// 评分条目（内部使用）
class _ScoredItem {
  final FeedItem item;
  final int score;
  const _ScoredItem(this.item, this.score);
}
