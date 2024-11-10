import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          surface: const Color(0xff000000),
          primary: const Color(0xffFFFFFF),
          onPrimary: Colors.white70,
          brightness: Brightness.dark,
          seedColor: Colors.green,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          surface: const Color(0xffFFFFFF),
          primary: const Color(0xff000000),
          onPrimary: Colors.grey.shade300,
          brightness: Brightness.light,
          seedColor: Colors.blue,
        ),
      );
}
