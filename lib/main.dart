import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/video_flow_provider.dart';
import 'providers/search_provider.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/video_flow_screen.dart';
import 'views/screens/search_middle_screen.dart';
import 'views/screens/search_result_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoFlowProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: MaterialApp(
        title: '今日头条',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/': (context) => const VideoFlowScreen(),
          '/search': (context) => const SearchMiddleScreen(),
          '/result': (context) => const SearchResultScreen(),
        },
      ),
    );
  }
}
