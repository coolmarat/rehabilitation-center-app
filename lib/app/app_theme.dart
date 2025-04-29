import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
    ),
    // Добавьте здесь другие настройки темы
  );

  // static final ThemeData darkTheme = ThemeData(
  //   colorScheme: ColorScheme.fromSeed(
  //       seedColor: Colors.blueAccent,
  //       brightness: Brightness.dark
  //   ),
  //   useMaterial3: true,
  //   // Добавьте здесь другие настройки темной темы
  // );
}
