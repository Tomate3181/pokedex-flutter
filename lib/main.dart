import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex Flutter',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.redAccent,
          surface: Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
