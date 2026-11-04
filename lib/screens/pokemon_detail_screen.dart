import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/app_state.dart';
import '../models/pokedex_theme.dart';
import 'move_detail_screen.dart';

class EvolutionItem {
  final int id;
  final String name;
  final String image;

  EvolutionItem({required this.id, required this.name, required this.image});
}

class PokemonMoveInfo {
  final String name;
  final String power;
  final String accuracy;
  final String type;

  PokemonMoveInfo({
    required this.name,
    required this.power,
    required this.accuracy,
    required this.type,
  });
}

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;
  final String name;

  const PokemonDetailScreen({super.key, required this.pokemonId, required this.name});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  Map<String, dynamic>? _details;
  List<EvolutionItem> _evolutionChain = [];
  List<String> _familyNames = [];
  List<PokemonMoveInfo> _moveDetailsList = [];
  bool _isShiny = false;
  bool _loadingEvolutions = true;
  bool _loadingMoves = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/${widget.pokemonId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _details = data;
        });
        _fetchEvolutionChain();
        _fetchMovesData(data['moves'] as List);
      }
    } catch (_) {}
  }

  Future<void> _fetchMovesData(List movesRaw) async {
    List<PokemonMoveInfo> loadedMoves = [];
    final sample = movesRaw.take(15).toList();
    for (var m in sample) {
      final moveName = m['move']['name'] as String;
      final moveUrl = m['move']['url'] as String;
      try {
        final res = await http.get(Uri.parse(moveUrl));
        if (res.statusCode == 200) {
          final moveJson = jsonDecode(res.body);
          loadedMoves.add(PokemonMoveInfo(
            name: moveName.toUpperCase(),
            power: (moveJson['power'] ?? '—').toString(),
            accuracy: (moveJson['accuracy'] ?? '—').toString(),
            type: moveJson['type']['name'].toString().toUpperCase(),
          ));
        }
      } catch (_) {
        loadedMoves.add(PokemonMoveInfo(
          name: moveName.toUpperCase(),
          power: '—',
          accuracy: '—',
          type: 'NORMAL',
        ));
      }
    }
    if (mounted) {
      setState(() {
        _moveDetailsList = loadedMoves;
        _loadingMoves = false;
      });
    }
  }

  Future<void> _fetchEvolutionChain() async {
    try {
      final speciesRes = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/${widget.pokemonId}'));
      if (speciesRes.statusCode == 200) {
        final speciesData = jsonDecode(speciesRes.body);
        final evoUrl = speciesData['evolution_chain']['url'];

        final evoRes = await http.get(Uri.parse(evoUrl));
        if (evoRes.statusCode == 200) {
          final evoData = jsonDecode(evoRes.body);
          List<EvolutionItem> chain = [];
          List<String> family = [];

          void parseChain(Map<String, dynamic> node) {
            final name = node['species']['name'] as String;
            final url = node['species']['url'] as String;
            final parts = url.split('/');
            final idStr = parts[parts.length - 2];
            final int id = int.parse(idStr);

            family.add(name.toLowerCase());
            chain.add(EvolutionItem(
              id: id,
              name: name,
              image: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png",
            ));

            if (node['evolves_to'] != null) {
              var nextList = node['evolves_to'] as List;
              if (nextList.isNotEmpty) {
                for (var nextNode in nextList) {
                  parseChain(nextNode as Map<String, dynamic>);
                }
              }
            }
          }

          parseChain(evoData['chain'] as Map<String, dynamic>);

          if (mounted) {
            setState(() {
              _evolutionChain = chain;
              _familyNames = family;
              _loadingEvolutions = false;
            });
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEvolutions = false);
    }
  }

  void _playCry() async {
    if (_details != null && _details!['cries'] != null) {
      String? cryUrl = _details!['cries']['latest'] ?? _details!['cries']['legacy'];
      if (cryUrl != null) {
        await _audioPlayer.play(UrlSource(cryUrl));
      }
    }
  }

void _showAddToTeamDialog() async {
    if (appState.teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea un equipo primero en la pestaña Equipos')),
      );
      return;
    }

    final String iconUrl = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${widget.pokemonId}.png";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Agregar a Equipo', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(appState.teams.length, (index) {
            final team = appState.teams[index];
            final membersCount = team.members.length;
            final canAdd = appState.canAddPokemonToTeam(index, widget.name, _familyNames);

            return ListTile(
              title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                canAdd ? '$membersCount/6 integrantes' : (membersCount >= 6 ? 'Equipo Lleno (6/6)' : 'Pokémon o línea evolutiva ya en el equipo'),
                style: TextStyle(color: canAdd ? Colors.greenAccent : Colors.redAccent),
              ),
              onTap: canAdd
                  ? () async {
                      Navigator.pop(context);

                      // Asignación de 4 movimientos iniciales automáticos
                      List<String> assignedMoves = [];
                      if (_details != null && _details!['moves'] != null) {
                        var movesRaw = (_details!['moves'] as List);
                        movesRaw.shuffle();
                        for (var m in movesRaw.take(4)) {
                          assignedMoves.add((m['move']['name'] as String).toUpperCase());
                        }
                      }

                      appState.addPokemonToTeam(
                        index,
                        TeamMember(
                          id: widget.pokemonId,
                          name: widget.name,
                          image: iconUrl,
                          moves: assignedMoves,
                        ),
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.name.toUpperCase()} agregado a ${team.name} con 4 movimientos')),
                        );
                      }
                    }
                  : null,
            );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFav = appState.favorites.contains(widget.name);
    final spriteUrl = _isShiny
        ? "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/${widget.pokemonId}.png"
        : "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${widget.pokemonId}.png";

    final themeColor = getPokedexColor(appState.theme);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: Text(widget.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isShiny ? Icons.star : Icons.star_border, color: Colors.amber),
            onPressed: () => setState(() => _isShiny = !_isShiny),
            tooltip: 'Alternar Shiny',
          ),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
            onPressed: () => appState.toggleFavorite(widget.name),
          ),
        ],
      ),
      body: _details == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Hero(
                      tag: 'poke-${widget.pokemonId}',
                      child: CachedNetworkImage(imageUrl: spriteUrl, height: 200),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _playCry,
                        icon: const Icon(Icons.volume_up, color: Colors.white),
                        label: const Text('Escuchar Grito (Audio)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddToTeamDialog,
                        icon: const Icon(Icons.group_add, color: Colors.white),
                        label: const Text('Agregar a Equipo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoChip('Altura', '${(_details!['height'] as int) / 10} m'),
                      _infoChip('Peso', '${(_details!['weight'] as int) / 10} kg'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Tipos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (_details!['types'] as List).map((t) {
                      return Chip(
                        label: Text((t['type']['name'] as String).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: themeColor.withOpacity(0.6),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Estadísticas Base', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  ...(_details!['stats'] as List).map((s) {
                    final statVal = s['base_stat'] as int;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text((s['stat']['name'] as String).toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey))),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: statVal / 150.0,
                              color: themeColor,
                              backgroundColor: Colors.grey[800],
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('$statVal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 25),
                  const Text('Línea Evolutiva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  _loadingEvolutions
                      ? const CircularProgressIndicator()
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: _evolutionChain.map((evo) {
                            final isCurrent = evo.id == widget.pokemonId;
                            return GestureDetector(
                              onTap: isCurrent
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PokemonDetailScreen(pokemonId: evo.id, name: evo.name),
                                        ),
                                      );
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrent ? themeColor.withOpacity(0.3) : const Color(0xFF262626),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isCurrent ? themeColor : Colors.transparent, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: evo.image,
                                      width: 60,
                                      height: 60,
                                      placeholder: (_, __) => const Icon(Icons.catching_pokemon, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      evo.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent ? Colors.amber : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 25),
                  const Text('Movimientos y Especificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 5),
                  const Text('Toca cualquier movimiento para ver su descripción', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 10),
                  _loadingMoves
                      ? const CircularProgressIndicator()
                      : Container(
                          height: 220,
                          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _moveDetailsList.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                            itemBuilder: (context, index) {
                              final m = _moveDetailsList[index];
                              return ListTile(
                                dense: true,
                                title: Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text('Poder: ${m.power}  |  Precisión: ${m.accuracy}%', style: const TextStyle(color: Colors.grey)),
                                trailing: Chip(
                                  label: Text(m.type, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: themeColor.withOpacity(0.5),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MoveDetailScreen(moveName: m.name),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}