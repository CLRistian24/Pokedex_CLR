import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/app_state.dart';
import 'pokemon_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  void _openFavoriteDetail(BuildContext context, String name) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/${name.toLowerCase()}'));
      if (context.mounted) Navigator.pop(context); // Cierra loader

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PokemonDetailScreen(
                pokemonId: data['id'] as int,
                name: data['name'] as String,
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text('Pokémon Favoritos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          if (appState.favorites.isEmpty) {
            return const Center(
              child: Text('No tienes Pokémon guardados como favoritos.', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            itemCount: appState.favorites.length,
            itemBuilder: (context, index) {
              final name = appState.favorites[index];
              return ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Toca para ver tarjeta de detalle', style: TextStyle(color: Colors.grey, fontSize: 11)),
                onTap: () => _openFavoriteDetail(context, name),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => appState.toggleFavorite(name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}