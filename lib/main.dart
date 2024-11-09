import 'package:expense_tracker/helpers/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'pages/pages.dart';
import 'theming/theme.dart';

// Removed extra space

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the HydratedBloc storage
  final storageDirectory = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: storageDirectory,
  );

  // Initialize the database and provide it throughout the app
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppDatabase.instance,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, ThemeMode mode) {
          return GetMaterialApp(
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => const HomePage()),
              GetPage(name: '/settings', page: () => const SettingsPage()),
            ],
            debugShowCheckedModeBanner: false,
            title: 'Expense Tracker',
            themeMode: mode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
