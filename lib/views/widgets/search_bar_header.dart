import 'package:flutter/material.dart';

/// 顶部搜索按钮（放大镜图标）
class SearchBarHeader extends StatelessWidget {
  const SearchBarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.white, size: 28),
      onPressed: () => Navigator.pushNamed(context, '/search'),
    );
  }
}
