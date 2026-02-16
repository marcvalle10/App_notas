import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/notes_screen.dart';
import 'utils/constants.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniNotas UNISON',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azulUnison,
          primary: AppColors.azulUnison,
          secondary: AppColors.doradoUnison,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.azulOscuroUnison,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.doradoUnison,
          foregroundColor: Colors.black,
        ),
      ),
      routes: {
        '/': (_) => const WelcomeScreen(),
        '/notes': (_) => const NotesScreen(),
      },
    );
  }
}