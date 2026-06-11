import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toutiao_demo/providers/search_provider.dart';
import 'package:toutiao_demo/data/models/feed_item.dart';

void main() {
  late SearchProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = SearchProvider();
  });

  group('SearchProvider', () {
    group('loadHistory', () {
      test('loads empty history when no data stored', () async {
        await provider.loadHistory();
        expect(provider.searchHistory, isEmpty);
      });

      test('loadHistory initializes hasHistory to false', () async {
        await provider.loadHistory();
        expect(provider.hasHistory, isFalse);
      });

      test('notifyListeners is called on load', () async {
        bool notified = false;
        provider.addListener(() => notified = true);
        await provider.loadHistory();
        expect(notified, isTrue);
      });
    });

    group('addToHistory', () {
      test('adds new keyword at beginning', () async {
        await provider.addToHistory('Flutter');
        expect(provider.searchHistory.first, equals('Flutter'));
      });

      test('deduplicates keywords (moves to front)', () async {
        await provider.addToHistory('Dart');
        await provider.addToHistory('Flutter');
        await provider.addToHistory('Dart');
        expect(provider.searchHistory.first, equals('Dart'));
        expect(provider.searchHistory.where((h) => h == 'Dart').length, equals(1));
      });

      test('ignores empty keyword', () async {
        await provider.addToHistory('');
        await provider.addToHistory('   ');
        expect(provider.searchHistory, isEmpty);
      });

      test('caps at 20 entries', () async {
        for (int i = 0; i < 25; i++) {
          await provider.addToHistory('keyword$i');
        }
        expect(provider.searchHistory.length, equals(20));
        // Most recent should be 'keyword24'
        expect(provider.searchHistory.first, equals('keyword24'));
        // Oldest should be 'keyword5' (keywords 0-4 dropped, 5 is oldest remaining)
        expect(provider.searchHistory.last, equals('keyword5'));
      });

      test('persists after reload', () async {
        await provider.addToHistory('Flutter');
        await provider.addToHistory('Dart');

        // Create a new provider instance to test persistence
        final provider2 = SearchProvider();
        await provider2.loadHistory();
        expect(provider2.searchHistory, contains('Flutter'));
        expect(provider2.searchHistory, contains('Dart'));
      });
    });

    group('deleteHistoryItem', () {
      test('deletes item at valid index', () async {
        await provider.addToHistory('A');
        await provider.addToHistory('B');
        await provider.addToHistory('C');
        await provider.deleteHistoryItem(1); // Remove 'B'
        expect(provider.searchHistory, equals(['C', 'A']));
      });

      test('does nothing for invalid index', () async {
        await provider.addToHistory('A');
        await provider.deleteHistoryItem(-1);
        await provider.deleteHistoryItem(100);
        expect(provider.searchHistory.length, equals(1));
      });
    });

    group('clearHistory', () {
      test('clears all history', () async {
        await provider.addToHistory('A');
        await provider.addToHistory('B');
        await provider.clearHistory();
        expect(provider.searchHistory, isEmpty);
        expect(provider.hasHistory, isFalse);
      });
    });

    group('search', () {
      test('sets results and currentQuery', () async {
        await provider.search('动画');
        expect(provider.currentQuery, equals('动画'));
        expect(provider.searchResults, isNotEmpty);
      });

      test('adds search term to history', () async {
        await provider.search('旅游');
        expect(provider.searchHistory, contains('旅游'));
      });

      test('returns results with matching items', () async {
        await provider.search('帝国');
        final results = provider.searchResults;
        expect(results.isNotEmpty, isTrue);
        // All results should match in some way
        for (final item in results) {
          final matchesTitle = item.title.contains('帝国');
          final matchesDesc = item.description.contains('帝国');
          final matchesTag = (item.aiTag ?? '').contains('帝国');
          final matchesKeyword = item.relatedSearchKeyword.contains('帝国');
          expect(matchesTitle || matchesDesc || matchesTag || matchesKeyword, isTrue);
        }
      });

      test('empty query returns empty results', () async {
        await provider.search('');
        expect(provider.searchResults, isEmpty);
        await provider.search('   ');
        expect(provider.searchResults, isEmpty);
      });
    });

    group('clearResults', () {
      test('clears results and query', () async {
        await provider.search('动画');
        expect(provider.searchResults, isNotEmpty);
        provider.clearResults();
        expect(provider.searchResults, isEmpty);
        expect(provider.currentQuery, isEmpty);
      });
    });

    group('state management', () {
      test('notifyListeners fires on search', () async {
        bool notified = false;
        provider.addListener(() => notified = true);
        await provider.search('测试');
        expect(notified, isTrue);
      });

      test('notifyListeners fires on addToHistory', () async {
        bool notified = false;
        provider.addListener(() => notified = true);
        await provider.addToHistory('test');
        expect(notified, isTrue);
      });

      test('notifyListeners fires on clearHistory', () async {
        bool notified = false;
        provider.addListener(() => notified = true);
        await provider.clearHistory();
        expect(notified, isTrue);
      });

      test('notifyListeners fires on clearResults', () async {
        bool notified = false;
        provider.addListener(() => notified = true);
        provider.clearResults();
        expect(notified, isTrue);
      });
    });
  });
}
