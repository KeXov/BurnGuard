import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: BurnGuardApp()));
}

class BurnGuardApp extends StatelessWidget {
  const BurnGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BurnGuard',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: const CardThemeData(elevation: 2),
    );
  }
}
