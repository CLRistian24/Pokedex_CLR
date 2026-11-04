import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

class PokemonSimpleItem {
  final int id;
  final String name;
  final String image;
  final String url;

  PokemonSimpleItem({
    required this.id,
    required this.name,
    required this.image,
    required this.url,
  });
}

class PokedexListScreen extends StatefulWidget {
  const PokedexListScreen({super.key});

  @override
  State<PokedexListScreen> createState() => _PokedexListScreenState();
}

class _PokedexListScreenState extends State<PokedexListScreen> {
  final List<PokemonSimpleItem> _pokemonList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 30;
  String _searchQuery = "";

  // Variables de Control de Filtros
  String _selectedType = "todos";
  int _selectedGen = 0;
  String _relationFilter = "base";

  List<PokemonSimpleItem> _filteredApiList = [];
  bool _isCustomFiltering = false;

  final List<String> _typesList = [
    "todos", "fire", "water", "grass", "electric", "ice", "fighting",
    "poison", "ground", "flying", "psychic", "bug", "rock", "ghost",
    "dragon", "steel", "fairy", "normal"
  ];

  final Map<int, String> _genList = {
    0: "Todas las Generaciones",
    1: "Gen 1 (Kanto: 1-151)",
    2: "Gen 2 (Johto: 152-251)",
    3: "Gen 3 (Hoenn: 252-386)",
    4: "Gen 4 (Sinnoh: 387-493)",
    5: "Gen 5 (Unova: 494-649)",
    6: "Gen 6 (Kalos: 650-721)",
  };

  @override
  void initState() {
    super.initState();
    _fetchPokemonPage();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isCustomFiltering) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _fetchPokemonPage();
    }
  }

  Future<void> _fetchPokemonPage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$_limit&offset=$_offset'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] as List;

        List<PokemonSimpleItem> fetched = [];
        for (var item in results) {
          final String url = item['url'] as String;
          final parts = url.split('/');
          final idStr = parts[parts.length - 2];
          final int id = int.parse(idStr);
          final spriteUrl = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png";

          fetched.add(PokemonSimpleItem(
            id: id,
            name: item['name'] as String,
            image: spriteUrl,
            url: url,
          ));
        }

        setState(() {
          _pokemonList.addAll(fetched);
          _offset += _limit;
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyAdvancedTypeFilter() async {
    if (_selectedType == "todos") {
      setState(() {
        _isCustomFiltering = false;
        _filteredApiList.clear();
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final typeRes = await http.get(Uri.parse('https://pokeapi.co/api/v2/type/$_selectedType'));
      if (typeRes.statusCode == 200) {
        final data = jsonDecode(typeRes.body);
        String targetType = _selectedType;

        if (_relationFilter == "fortalezas") {
          final doubleDamageTo = data['damage_relations']['double_damage_to'] as List;
          if (doubleDamageTo.isNotEmpty) {
            targetType = doubleDamageTo.first['name'];
          }
        } else if (_relationFilter == "debilidades") {
          final doubleDamageFrom = data['damage_relations']['double_damage_from'] as List;
          if (doubleDamageFrom.isNotEmpty) {
            targetType = doubleDamageFrom.first['name'];
          }
        }

        final targetRes = await http.get(Uri.parse('https://pokeapi.co/api/v2/type/$targetType'));
        if (targetRes.statusCode == 200) {
          final targetData = jsonDecode(targetRes.body);
          final List pokeRaw = targetData['pokemon'] as List;

          List<PokemonSimpleItem> fetched = [];
          for (var item in pokeRaw) {
            final pObj = item['pokemon'];
            final String url = pObj['url'] as String;
            final parts = url.split('/');
            final idStr = parts[parts.length - 2];
            final int id = int.parse(idStr);
            final spriteUrl = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png";

            fetched.add(PokemonSimpleItem(
              id: id,
              name: pObj['name'] as String,
              image: spriteUrl,
              url: url,
            ));
          }

          setState(() {
            _filteredApiList = fetched;
            _isCustomFiltering = true;
          });
        }
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _searchDirectlyInApi(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$term'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pokémon no encontrado en PokéAPI')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al conectar con el servidor')),
        );
      }
    }
  }

  bool _belongsToGen(int id, int gen) {
    if (gen == 0) return true;
    if (gen == 1) return id >= 1 && id <= 151;
    if (gen == 2) return id >= 152 && id <= 251;
    if (gen == 3) return id >= 252 && id <= 386;
    if (gen == 4) return id >= 387 && id <= 493;
    if (gen == 5) return id >= 494 && id <= 649;
    if (gen == 6) return id >= 650 && id <= 721;
    return true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseList = _isCustomFiltering ? _filteredApiList : _pokemonList;

    final filtered = baseList.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || p.id.toString() == _searchQuery.trim();
      final matchesGen = _belongsToGen(p.id, _selectedGen);
      return matchesSearch && matchesGen;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon)),
            const SizedBox(width: 10),
            const Text('PokéDex CLR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar local o Enter para buscar por ID/Nombre...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
              onSubmitted: (val) => _searchDirectlyInApi(val),
            ),
          ),
          
          // APERTURA DE FILTROS EN EL SCROLL (ExpansionTile)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.tune, color: Colors.tealAccent),
              title: const Text('Filtros Avanzados (Tipos, Fortalezas y Gen)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              dropdownColor: const Color(0xFF262626),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Tipo Base', labelStyle: TextStyle(color: Colors.grey)),
                              items: _typesList.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedType = val);
                                  _applyAdvancedTypeFilter();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _relationFilter,
                              dropdownColor: const Color(0xFF262626),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(labelText: 'Relación de Tipo', labelStyle: TextStyle(color: Colors.grey)),
                              items: const [
                                DropdownMenuItem(value: "base", child: Text('Normal (Pertenece)')),
                                DropdownMenuItem(value: "fortalezas", child: Text('Fortaleza (Hace 2x)')),
                                DropdownMenuItem(value: "debilidades", child: Text('Debilidad (Sufre 2x)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _relationFilter = val);
                                  _applyAdvancedTypeFilter();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _selectedGen,
                        dropdownColor: const Color(0xFF262626),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(labelText: 'Generación', labelStyle: TextStyle(color: Colors.grey)),
                        items: _genList.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (val) => setState(() => _selectedGen = val ?? 0),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filtered.length + (_isLoading ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= filtered.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final item = filtered[index];
                return PokemonCard(pokemon: {'id': item.id, 'name': item.name, 'image': item.image});
              },
            ),
          ),
        ],
      ),
    );
  }
}