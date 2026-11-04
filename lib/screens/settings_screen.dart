import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/pokedex_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(title: const Text('Ajustes de PokéDex', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Color de Carcasa PokéDex', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _colorButton(context, 'Clásico Rojo', PokedexColorTheme.red, const Color(0xFFDC0A2D)),
                _colorButton(context, 'Negro', PokedexColorTheme.black, const Color(0xFF212121)),
                _colorButton(context, 'Gris', PokedexColorTheme.grey, const Color(0xFF757575)),
                _colorButton(context, 'Morado', PokedexColorTheme.purple, const Color(0xFF671da3)),
                _colorButton(context, 'Azul', PokedexColorTheme.blue, const Color(0xFF0000a3)),
                _colorButton(context, 'Verde', PokedexColorTheme.green, const Color(0xFF005500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorButton(BuildContext context, String label, PokedexColorTheme theme, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: () => appState.setTheme(theme),
      child: Text(label),
    );
  }
}