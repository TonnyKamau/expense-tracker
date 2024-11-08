import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theming /theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return SwitchListTile(
                title: themeMode == ThemeMode.dark
                    ? const Text('Dark Mode')
                    : const Text('Light Mode'),
                value: themeMode == ThemeMode.dark,
                onChanged: (bool value) {
                  context
                      .read<ThemeCubit>()
                      .updateTheme(value ? ThemeMode.dark : ThemeMode.light);
                },
                secondary: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
              );
            },
          ),
          
        ],
      ),
    );
  }
}
