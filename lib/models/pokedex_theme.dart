import 'package:flutter/material.dart';

enum PokedexColorTheme { red, black, grey, purple, blue, green }

Color getPokedexColor(PokedexColorTheme theme) {
  switch (theme) {
    case PokedexColorTheme.red:
      return const Color(0xFFDC0A2D); // Rojo PokéDex Clásico (Modifica este valor)
    case PokedexColorTheme.black:
      return const Color(0xFF212121); // Negro Mate / Oscuro (Modifica este valor)
    case PokedexColorTheme.grey:
      return const Color(0xFF757575); // Gris Acero (Modifica este valor)
    case PokedexColorTheme.purple:
      return const Color(0xFF671da3); // Morado Psíquico / Veneno (Modifica este valor)
    case PokedexColorTheme.blue:
      return const Color(0xFF0000a3); // Azul Agua / Lapras (Modifica este valor)
    case PokedexColorTheme.green:
      return const Color(0xFF005500); // Verde Planta (Modifica este valor)
  }
}