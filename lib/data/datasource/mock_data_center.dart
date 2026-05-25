import '../models/feed_item.dart';

/// 本地 Mock 数据内容库（含模糊检索逻辑）
///
/// 视频 URL 使用阿里云/W3C/Video.js/W3Schools 四大高保活 HTTPS 测试流。
/// 所有标题、描述、推荐词均已对齐对应视频的实际画面语义。
class MockDataCenter {
  final List<FeedItem> _items;

  MockDataCenter() : _items = _buildMockData();

  List<FeedItem> getAllItems() => List.unmodifiable(_items);

  int indexOfItem(String id) {
    return _items.indexWhere((item) => item.id == id);
  }

  List<FeedItem> search(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.trim().toLowerCase();
    return _items.where((item) {
      if (item.type != FeedType.video) return false;
      return item.title.toLowerCase().contains(lower) ||
          item.author.toLowerCase().contains(lower);
    }).toList();
  }

  // 4 个高保活、全 HTTPS 的 MP4 基础测试链接（循环填充 12 条视频）
  static const _u1 = 'https://player.alicdn.com/video/editor.mp4';
  static const _u2 = 'https://media.w3.org/2010/05/sintel/trailer_hd.mp4';
  static const _u3 = 'https://vjs.zencdn.net/v/oceans.mp4';
  static const _u4 = 'https://www.w3schools.com/html/mov_bbb.mp4';

  static List<FeedItem> _buildMockData() {
    return [
      // ── 视频类 (1-12)：标题/描述/AI推荐词严格对齐视频画面语义 ──
      // ── _u1 = editor.mp4 → 视频剪辑教程 ──
      const FeedItem(
        id: 'v001',
        title: '如何用手机5分钟剪出高赞短视频？大厂导师手把手教你神级转场',
        description: '全网最详细的短视频剪辑调色教程，小白也能轻松上手的爆款公式。',
        coverUrl: 'https://picsum.photos/seed/edit/400/600',
        videoUrl: _u1,
        type: FeedType.video,
        aiTag: '视频剪辑',
        relatedSearchKeyword: '短视频剪辑技巧',
        author: '极客公园',
        commentCount: 3241,
        likeCount: 85200,
        shareCount: 12600,
      ),
      // ── _u2 = sintel trailer → 3D 动漫大片预告 ──
      const FeedItem(
        id: 'v002',
        title: '国产3D动画史诗级黑马预告！这特效和画质直接燃爆了！',
        description: '东方奇幻大作震撼来袭，全程高能打斗，国漫崛起的巅峰之作？',
        coverUrl: 'https://picsum.photos/seed/dragon/400/600',
        videoUrl: _u2,
        type: FeedType.video,
        aiTag: '动漫预告',
        relatedSearchKeyword: '国漫神作推荐',
        author: '盗月社',
        commentCount: 5600,
        likeCount: 132000,
        shareCount: 28900,
      ),
      // ── _u3 = oceans.mp4 → 高清海底世界 ──
      const FeedItem(
        id: 'v003',
        title: '极度治愈！带你潜入4K高清深海，沉浸式感受蔚蓝海底生命',
        description: '跟随镜头一起探索未知的海洋世界，解压放松必看，戴上耳机效果更佳。',
        coverUrl: 'https://picsum.photos/seed/jellyfish/400/600',
        videoUrl: _u3,
        type: FeedType.video,
        aiTag: '海洋世界',
        relatedSearchKeyword: '唯美海底壁纸',
        author: '开车吧兄弟',
        commentCount: 8900,
        likeCount: 215000,
        shareCount: 67000,
      ),
      // ── _u4 = mov_bbb.mp4 → 搞笑动画《大雄兔》 ──
      const FeedItem(
        id: 'v004',
        title: '爆笑解压：当森林里的大胖兔子被小松鼠恶作剧，结局笑翻了',
        description: '疯狂动物城现实版！胖兔子的复仇记，专治各种不开心。',
        coverUrl: 'https://picsum.photos/seed/bunny/400/600',
        videoUrl: _u4,
        type: FeedType.video,
        aiTag: '搞笑动画',
        relatedSearchKeyword: '爆笑动物短片',
        author: '腾讯体育',
        commentCount: 15600,
        likeCount: 380000,
        shareCount: 92000,
      ),
      const FeedItem(
        id: 'v005',
        title: '如何用手机5分钟剪出高赞短视频？大厂导师手把手教你神级转场',
        description: '全网最详细的短视频剪辑调色教程，小白也能轻松上手的爆款公式。',
        coverUrl: 'https://picsum.photos/seed/transition/400/600',
        videoUrl: _u1,
        type: FeedType.video,
        aiTag: '视频剪辑',
        relatedSearchKeyword: '短视频剪辑技巧',
        author: 'QQ音乐现场',
        commentCount: 22300,
        likeCount: 560000,
        shareCount: 134000,
      ),
      const FeedItem(
        id: 'v006',
        title: '国产3D动画史诗级黑马预告！这特效和画质直接燃爆了！',
        description: '东方奇幻大作震撼来袭，全程高能打斗，国漫崛起的巅峰之作？',
        coverUrl: 'https://picsum.photos/seed/fantasy/400/600',
        videoUrl: _u2,
        type: FeedType.video,
        aiTag: '动漫预告',
        relatedSearchKeyword: '国漫神作推荐',
        author: '老郭科技',
        commentCount: 1800,
        likeCount: 42000,
        shareCount: 9800,
      ),
      const FeedItem(
        id: 'v007',
        title: '极度治愈！带你潜入4K高清深海，沉浸式感受蔚蓝海底生命',
        description: '跟随镜头一起探索未知的海洋世界，解压放松必看，戴上耳机效果更佳。',
        coverUrl: 'https://picsum.photos/seed/coral/400/600',
        videoUrl: _u3,
        type: FeedType.video,
        aiTag: '海洋世界',
        relatedSearchKeyword: '唯美海底壁纸',
        author: '游民星空',
        commentCount: 18900,
        likeCount: 430000,
        shareCount: 105000,
      ),
      const FeedItem(
        id: 'v008',
        title: '爆笑解压：当森林里的大胖兔子被小松鼠恶作剧，结局笑翻了',
        description: '疯狂动物城现实版！胖兔子的复仇记，专治各种不开心。',
        coverUrl: 'https://picsum.photos/seed/squirrel/400/600',
        videoUrl: _u4,
        type: FeedType.video,
        aiTag: '搞笑动画',
        relatedSearchKeyword: '爆笑动物短片',
        author: '猫眼电影',
        commentCount: 25600,
        likeCount: 780000,
        shareCount: 210000,
      ),
      const FeedItem(
        id: 'v009',
        title: '如何用手机5分钟剪出高赞短视频？大厂导师手把手教你神级转场',
        description: '全网最详细的短视频剪辑调色教程，小白也能轻松上手的爆款公式。',
        coverUrl: 'https://picsum.photos/seed/filter/400/600',
        videoUrl: _u1,
        type: FeedType.video,
        aiTag: '视频剪辑',
        relatedSearchKeyword: '短视频剪辑技巧',
        author: '央视新闻',
        commentCount: 9800,
        likeCount: 290000,
        shareCount: 45000,
      ),
      const FeedItem(
        id: 'v010',
        title: '国产3D动画史诗级黑马预告！这特效和画质直接燃爆了！',
        description: '东方奇幻大作震撼来袭，全程高能打斗，国漫崛起的巅峰之作？',
        coverUrl: 'https://picsum.photos/seed/animefight/400/600',
        videoUrl: _u2,
        type: FeedType.video,
        aiTag: '动漫预告',
        relatedSearchKeyword: '国漫神作推荐',
        author: '汽车之家',
        commentCount: 6700,
        likeCount: 156000,
        shareCount: 34000,
      ),
      const FeedItem(
        id: 'v011',
        title: '极度治愈！带你潜入4K高清深海，沉浸式感受蔚蓝海底生命',
        description: '跟随镜头一起探索未知的海洋世界，解压放松必看，戴上耳机效果更佳。',
        coverUrl: 'https://picsum.photos/seed/deepsea/400/600',
        videoUrl: _u3,
        type: FeedType.video,
        aiTag: '海洋世界',
        relatedSearchKeyword: '唯美海底壁纸',
        author: '中国天气',
        commentCount: 12300,
        likeCount: 189000,
        shareCount: 145000,
      ),
      const FeedItem(
        id: 'v012',
        title: '爆笑解压：当森林里的大胖兔子被小松鼠恶作剧，结局笑翻了',
        description: '疯狂动物城现实版！胖兔子的复仇记，专治各种不开心。',
        coverUrl: 'https://picsum.photos/seed/forest/400/600',
        videoUrl: _u4,
        type: FeedType.video,
        aiTag: '搞笑动画',
        relatedSearchKeyword: '爆笑动物短片',
        author: '钟文泽',
        commentCount: 4100,
        likeCount: 98000,
        shareCount: 15200,
      ),

      // ── 图文类 (13-20) ──
      const FeedItem(
        id: 'i001',
        title: '全球十大最美书店：每一家都值得专程飞一趟',
        description: '从巴黎莎士比亚到东京茑屋，那些让阅读变成朝圣的地方。',
        coverUrl: 'https://picsum.photos/seed/bookstore/400/600',
        type: FeedType.image,
        aiTag: '旅行种草',
        relatedSearchKeyword: '最美书店打卡攻略',
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
        title: '2026秋冬时装周街拍精选：60张图看尽最新穿搭趋势',
        description: '米兰、巴黎、纽约三大时装周场外街拍，教你穿出高级感。',
        coverUrl: 'https://picsum.photos/seed/fashion/400/600',
        type: FeedType.image,
        aiTag: '时尚穿搭',
        relatedSearchKeyword: '2026秋冬流行色',
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
        title: '探索三星堆新一轮发掘：新发现的青铜神坛细节图曝光',
        description: '考古队最新公布6号坑出土文物高清大图，首次发现古蜀文字符号。',
        coverUrl: 'https://picsum.photos/seed/sanxingdui/400/600',
        type: FeedType.image,
        aiTag: '考古发现',
        relatedSearchKeyword: '三星堆未解之谜',
        imageUrls: [
          'https://picsum.photos/seed/sxd1/400/300',
          'https://picsum.photos/seed/sxd2/400/300',
        ],
        author: '国家文物局',
        commentCount: 5600,
        likeCount: 167000,
        shareCount: 43000,
      ),
      const FeedItem(
        id: 'i004',
        title: '一图看懂：2026年中国新能源汽车市场格局全景图',
        description: '比亚迪、特斯拉、小米、蔚小理——销量、市值、技术路线全面对比。',
        coverUrl: 'https://picsum.photos/seed/evmarket/400/600',
        type: FeedType.image,
        aiTag: '行业分析',
        relatedSearchKeyword: '新能源汽车销量排行榜',
        imageUrls: [
          'https://picsum.photos/seed/ev1/400/300',
          'https://picsum.photos/seed/ev2/400/300',
          'https://picsum.photos/seed/ev3/400/300',
        ],
        author: '36氪',
        commentCount: 2100,
        likeCount: 89000,
        shareCount: 34000,
      ),
      const FeedItem(
        id: 'i005',
        title: '教你7天做出比面包店还好吃的欧包：从鲁邦种到出炉全图解',
        description: '不需要专业设备，家庭烤箱也能烤出气孔完美的酸面包。',
        coverUrl: 'https://picsum.photos/seed/bread/400/600',
        type: FeedType.image,
        aiTag: '烘焙教程',
        relatedSearchKeyword: '欧包失败原因',
        imageUrls: [
          'https://picsum.photos/seed/br1/400/300',
          'https://picsum.photos/seed/br2/400/300',
          'https://picsum.photos/seed/br3/400/300',
          'https://picsum.photos/seed/br4/400/300',
          'https://picsum.photos/seed/br5/400/300',
          'https://picsum.photos/seed/br6/400/300',
        ],
        author: '君之烘焙',
        commentCount: 12300,
        likeCount: 320000,
        shareCount: 156000,
      ),
      const FeedItem(
        id: 'i006',
        title: '哈勃望远镜接班人：韦伯望远镜拍下宇宙最深处的震撼画面',
        description: 'NASA公布最新深空照片合集，捕捉到130亿年前的星系光芒。',
        coverUrl: 'https://picsum.photos/seed/webb/400/600',
        type: FeedType.image,
        aiTag: '天文科普',
        relatedSearchKeyword: '韦伯望远镜最新发现',
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
      const FeedItem(
        id: 'i007',
        title: '2026世界杯抽签结果出炉：死亡之组英法同组，国足签运如何？',
        description: '一张图看懂8个小组对阵形势，各队出线概率分析。',
        coverUrl: 'https://picsum.photos/seed/worldcup/400/600',
        type: FeedType.image,
        aiTag: '世界杯',
        relatedSearchKeyword: '世界杯赛程表',
        imageUrls: [
          'https://picsum.photos/seed/wc1/400/300',
          'https://picsum.photos/seed/wc2/400/300',
        ],
        author: '懂球帝',
        commentCount: 34500,
        likeCount: 520000,
        shareCount: 198000,
      ),
      const FeedItem(
        id: 'i008',
        title: '一篇文章读懂：量子计算为什么能让AI再次进化？',
        description: '从量子比特到Shor算法，用图解方式讲清楚量子计算的底层原理。',
        coverUrl: 'https://picsum.photos/seed/quantum/400/600',
        type: FeedType.image,
        aiTag: '科技前沿',
        relatedSearchKeyword: '量子计算机最新进展',
        imageUrls: [
          'https://picsum.photos/seed/qc1/400/300',
          'https://picsum.photos/seed/qc2/400/300',
          'https://picsum.photos/seed/qc3/400/300',
        ],
        author: '返朴',
        commentCount: 4500,
        likeCount: 112000,
        shareCount: 56000,
      ),
    ];
  }
}
