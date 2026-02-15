import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/notes_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Notas',
      theme: ThemeData(
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const WelcomeScreen(),
        '/notes': (_) => const NotesScreen(),
      },
    );
  }
}