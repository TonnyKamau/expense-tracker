import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  bool get isDarkMode => state == ThemeMode.dark;
  bool get isLightMode => state == ThemeMode.light;
  bool get isSystemMode => state == ThemeMode.system;

  void updateTheme(ThemeMode? themeMode) {
    if (themeMode == null || state == themeMode) return;
    emit(themeMode); // This will save the new state automatically.
  }

  void toggleTheme() {
    if (state == ThemeMode.system) return;
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  ThemeMode fromJson(Map<String, dynamic> json) {
    try {
      final themeIndex = json['theme'] as int?;
      if (themeIndex == null ||
          themeIndex < 0 ||
          themeIndex >= ThemeMode.values.length) {
        return ThemeMode.system;
      }
      return ThemeMode.values[themeIndex];
    } catch (_) {
      return ThemeMode.system;
    }
  }

  @override
  Map<String, dynamic> toJson(ThemeMode state) {
    return {'theme': state.index};
  }
}
