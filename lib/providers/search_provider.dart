import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/feed_item.dart';
import '../data/datasource/mock_data_center.dart';

/// 管理搜索历史（SharedPreferences）、检索词触发、结果过滤状态
class SearchProvider extends ChangeNotifier {
  final MockDataCenter _dataCenter = MockDataCenter();

  List<String> _searchHistory = [];
  List<FeedItem> _searchResults = [];
  String _currentQuery = '';

  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<FeedItem> get searchResults => _searchResults;
  String get currentQuery => _currentQuery;
  bool get hasHistory => _searchHistory.isNotEmpty;

  static const _key = 'search_history';

  /// 从 SharedPreferences 加载搜索历史
  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList(_key) ?? [];
    notifyListeners();
  }

  /// 追加搜索词到历史（去重，最多保留 20 条）
  Future<void> addToHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.remove(trimmed);
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.sublist(0, 20);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _searchHistory);
    notifyListeners();
  }

  /// 删除单条历史
  Future<void> deleteHistoryItem(int index) async {
    if (index < 0 || index >= _searchHistory.length) return;
    _searchHistory.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _searchHistory);
    notifyListeners();
  }

  /// 一键清空搜索历史
  Future<void> clearHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  /// 执行模糊检索（title + author），仅返回视频，同时记入历史
  void search(String query) {
    _currentQuery = query.trim();
    if (_currentQuery.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _dataCenter.search(_currentQuery);
      addToHistory(_currentQuery);
    }
    notifyListeners();
  }

  /// 清空搜索结果
  void clearResults() {
    _searchResults = [];
    _currentQuery = '';
    notifyListeners();
  }
}
