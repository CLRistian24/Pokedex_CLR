import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'models/pokedex_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        final mainColor = getPokedexColor(appState.theme);
        return MaterialApp(
          title: 'PokéDex UPIIT',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF141414),
            primaryColor: mainColor,
            colorScheme: ColorScheme.dark(
              primary: mainColor,
              surface: const Color(0xFF1E1E1E),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}