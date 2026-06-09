import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/game_screen.dart';

void main() {
  runApp(const ProviderScope(child: LegendOfHeroesApp()));
}

class LegendOfHeroesApp extends StatelessWidget {
  const LegendOfHeroesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legend of Heroes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
