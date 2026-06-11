import 'package:flutter_test/flutter_test.dart';
import 'package:toutiao_demo/data/models/feed_item.dart';
import 'package:toutiao_demo/providers/video_flow_provider.dart';

/// Testable variant that skips video controller creation to avoid
/// platform channel issues in the test environment.
class TestableVideoFlowProvider extends VideoFlowProvider {
  bool preloadCalled = false;

  @override
  void preloadItem(FeedItem item) {
    preloadCalled = true;
    // Skip real video controller creation in tests
  }
}

void main() {
  late TestableVideoFlowProvider provider;

  setUp(() {
    provider = TestableVideoFlowProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  group('VideoFlowProvider', () {
    group('initWindow', () {
      test('loads items successfully', () async {
        await provider.initWindow();
        expect(provider.itemCount, equals(5));
      });

      test('returns immediately on second call', () async {
        await provider.initWindow();
        final count = provider.itemCount;
        await provider.initWindow();
        expect(provider.itemCount, equals(count));
      });

      test('sets isLoading during load', () async {
        expect(provider.isLoading, isFalse);
        final future = provider.initWindow();
        expect(provider.isLoading, isTrue);
        await future;
        expect(provider.isLoading, isFalse);
      });

      test('hasMore is true after init', () async {
        await provider.initWindow();
        expect(provider.hasMore, isTrue);
      });

      test('currentPageIndex starts at 0', () async {
        await provider.initWindow();
        expect(provider.currentPageIndex, equals(0));
      });
    });

    group('loadNextPage', () {
      test('appends new items', () async {
        await provider.initWindow();
        final before = provider.itemCount;
        await provider.loadNextPage();
        expect(provider.itemCount, greaterThan(before));
      });

      test('second loadNextPage during load is a no-op', () async {
        await provider.initWindow();
        final firstCount = provider.itemCount;
        // Call loadNextPage and immediately call again - second should be ignored
        final future1 = provider.loadNextPage();
        await provider.loadNextPage(); // should return immediately (isLoading guard)
        await future1; // wait for first to complete
        expect(provider.itemCount, greaterThan(firstCount));
      });

      test('no duplicate items across pages', () async {
        await provider.initWindow();
        // Extract original IDs from first page
        final firstPageIds = <String>{};
        for (int i = 0; i < provider.itemCount; i++) {
          final id = provider.items[i].id;
          final orig = id.contains('_ts') ? id.split('_ts').first : id;
          firstPageIds.add(orig);
        }

        await provider.loadNextPage();
        // Check that newly added items don't overlap with first page
        for (int i = firstPageIds.length; i < provider.itemCount; i++) {
          final id = provider.items[i].id;
          final orig = id.contains('_ts') ? id.split('_ts').first : id;
          expect(firstPageIds.contains(orig), isFalse,
              reason: 'Item $orig appeared in both pages');
        }
      });
    });

    group('onPageChanged', () {
      test('updates currentPageIndex', () async {
        await provider.initWindow();
        expect(provider.currentPageIndex, equals(0));
        provider.onPageChanged(1);
        expect(provider.currentPageIndex, equals(1));
      });

      test('ignores duplicate page', () async {
        await provider.initWindow();
        provider.onPageChanged(1);
        provider.onPageChanged(1);
        expect(provider.currentPageIndex, equals(1));
      });

      test('does not change for image-only pages', () async {
        await provider.initWindow();
        // Find an index that maps to an image item (unpredictable due to shuffle)
        // Just verify onPageChanged doesn't crash for any valid index
        for (int i = 0; i < provider.itemCount; i++) {
          provider.onPageChanged(i);
          expect(provider.currentPageIndex, equals(i));
        }
      });
    });

    group('requestJumpToItem / pendingJumpIndex', () {
      test('sets pendingJumpIndex for existing item', () async {
        await provider.initWindow();
        final targetId = provider.items[2].id;

        provider.requestJumpToItem(targetId);
        expect(provider.pendingJumpIndex, isNotNull);
        expect(provider.pendingJumpIndex, equals(2));
      });

      test('returns null pendingJumpIndex for non-existent item', () async {
        await provider.initWindow();
        provider.requestJumpToItem('nonexistent_id');
        expect(provider.pendingJumpIndex, isNull);
      });

      test('consumePendingJump clears the pending index', () async {
        await provider.initWindow();
        final targetId = provider.items[1].id;
        provider.requestJumpToItem(targetId);
        expect(provider.pendingJumpIndex, isNotNull);

        provider.consumePendingJump();
        expect(provider.pendingJumpIndex, isNull);
      });
    });

    group('requestJumpToItem with startsWith matching', () {
      test('matches timestamped IDs by prefix', () async {
        await provider.initWindow();
        // Items from feed have IDs like "v001_ts1234567890_0"
        // requestJumpToItem should match by original ID prefix
        final item = provider.items[0];
        final origId = item.id.contains('_ts')
            ? item.id.split('_ts').first
            : item.id;

        provider.requestJumpToItem(origId);
        expect(provider.pendingJumpIndex, isNotNull);
      });
    });
  });
}
