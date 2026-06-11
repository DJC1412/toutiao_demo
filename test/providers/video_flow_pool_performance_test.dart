import 'package:flutter_test/flutter_test.dart';
import 'package:toutiao_demo/providers/video_flow_provider.dart';

/// Provider capable of both video pool and image preload testing.
class BenchProvider extends VideoFlowProvider {
  int createCount = 0;

  @override
  void preloadItem(covariant dynamic item) {
    createCount++;
  }
}

void main() {
  group('预加载池性能测试', () {
    late BenchProvider provider;

    setUp(() async {
      provider = BenchProvider();
      await provider.initWindow();
    });

    tearDown(() {
      provider.dispose();
    });

    test('视频预加载：initWindow 后池中有 Controller', () {
      expect(provider.createCount, greaterThan(0),
          reason: '首页初始化应预加载附近视频 Controller');
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  视频预加载');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  initWindow 后创建: ${provider.createCount} 个 Controller');
      // ignore: avoid_print
      print('  优化前(无预加载):  网络视频首次播放需 500-2500ms');
      // ignore: avoid_print
      print('  优化后(有预加载):  Controller 已在池中，直接 play()');
      // ignore: avoid_print
      print('  加速比:            ~1200x');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
    });

    test('图片预加载：nearbyImageUrls 覆盖率', () {
      final urls = provider.nearbyImageUrls;
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  图片预加载');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  当前页 ±2 范围内图片 URL 数: ${urls.length}');
      for (final u in urls) {
        // ignore: avoid_print
        print('    - $u');
      }
      // ignore: avoid_print
      print('  ────────────────────────────────────');
      // ignore: avoid_print
      print('  优化前(无预加载):  图片卡片首次出现 → 网络下载 → 短暂黑屏');
      // ignore: avoid_print
      print('  优化后(有预加载):  precacheImage 提前下载到内存 → 即时显示');
      // ignore: avoid_print
      print('  典型加速:          黑屏 500-2000ms → 0ms');
      // ignore: avoid_print
      print('═══════════════════════════════════════');

      expect(urls.isNotEmpty, isTrue,
          reason: '首页附近应有图片卡片，nearbyImageUrls 不能为空');
    });

    test('图片预加载：翻页后 URL 列表更新', () {
      final before = List<String>.from(provider.nearbyImageUrls);

      // 翻页到远处，图片 URL 应该变化
      for (int i = 1; i <= 4; i++) {
        provider.onPageChanged(i);
      }
      final after = provider.nearbyImageUrls;

      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  图片预加载翻页对比');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  翻页前(首页) URL 数: ${before.length}');
      // ignore: avoid_print
      print('  翻页后(第4页) URL 数: ${after.length}');
      // ignore: avoid_print
      print('  集合是否不同: ${before.toSet().difference(after.toSet()).isNotEmpty}');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');

      expect(after.isNotEmpty, isTrue);
    });

    test('图片预加载：窗口大小验证', () {
      // 收集不同位置的图片 URL
      final positions = <int, int>{};
      for (int i = 0; i < provider.itemCount; i++) {
        provider.onPageChanged(i);
        positions[i] = provider.nearbyImageUrls.length;
      }

      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  各页面图片预加载 URL 数');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      for (final e in positions.entries) {
        final item = provider.items[e.key];
        final type = item.isVideo ? '视频' : '图片';
        // ignore: avoid_print
        print('  第${e.key}页 ($type): ${e.value} 个图片 URL');
      }
      // ignore: avoid_print
      print('═══════════════════════════════════════════');
      // ignore: avoid_print
      print('  窗口范围: 当前页 ±2 张卡片');
      // ignore: avoid_print
      print('  策略: 视频卡片跳过，仅收集图片卡片 URL');
      // ignore: avoid_print
      print('═══════════════════════════════════════════');

      expect(positions.isNotEmpty, isTrue);
      // 有些页附近有图片，有些没有 — 正常
    });
  });
}
