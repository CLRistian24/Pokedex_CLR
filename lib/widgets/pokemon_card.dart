import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/pokemon_detail_screen.dart';

class PokemonCard extends StatelessWidget {
  final Map<String, dynamic> pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PokemonDetailScreen(
            pokemonId: pokemon['id'],
            name: pokemon['name'],
          ),
        ),
      ),
      child: Card(
        color: const Color(0xFF262626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                child: Text(
                  '#${pokemon['id'].toString().padLeft(3, '0')}',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Hero(
                tag: 'poke-${pokemon['id']}',
                child: CachedNetworkImage(
                  imageUrl: pokemon['image'],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Icon(Icons.catching_pokemon, size: 40, color: Colors.grey),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                pokemon['name'].toString().toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}