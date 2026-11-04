import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/app_state.dart';
import 'move_detail_screen.dart';
import 'pokemon_detail_screen.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  void _createTeamDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Nuevo Equipo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre del equipo',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                appState.saveTeam(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _renameTeamDialog(BuildContext context, int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Renombrar Equipo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nuevo nombre',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                appState.renameTeam(index, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // MENÚ PARA EVOLUCIONAR / DESEVOLUCIONAR POKÉMON EN EL EQUIPO
  void _showEvolutionOptions(BuildContext context, int teamIndex, int memberIndex, TeamMember currentMember) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final speciesRes = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/${currentMember.id}')).timeout(const Duration(seconds: 4));
      if (speciesRes.statusCode == 200) {
        final speciesData = jsonDecode(speciesRes.body);
        final evoUrl = speciesData['evolution_chain']['url'];

        final evoRes = await http.get(Uri.parse(evoUrl)).timeout(const Duration(seconds: 4));
        if (evoRes.statusCode == 200) {
          final evoData = jsonDecode(evoRes.body);
          List<Map<String, dynamic>> chain = [];

          void parseChain(Map<String, dynamic> node) {
            final name = node['species']['name'] as String;
            final url = node['species']['url'] as String;
            final parts = url.split('/');
            final idStr = parts[parts.length - 2];
            final int id = int.parse(idStr);

            chain.add({
              'id': id,
              'name': name,
              'image': "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png"
            });

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
          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

          int currentIdxInChain = chain.indexWhere((item) => item['id'] == currentMember.id);
          Map<String, dynamic>? prevEvo = currentIdxInChain > 0 ? chain[currentIdxInChain - 1] : null;
          Map<String, dynamic>? nextEvo = (currentIdxInChain >= 0 && currentIdxInChain < chain.length - 1) ? chain[currentIdxInChain + 1] : null;

          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF262626),
              builder: (_) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cambiar forma de ${currentMember.name.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    if (prevEvo != null)
                      ListTile(
                        leading: Image.network(prevEvo['image'], width: 36),
                        title: Text('Involucionar a ${prevEvo['name'].toString().toUpperCase()}', style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.arrow_downward, color: Colors.orangeAccent),
                        onTap: () {
                          appState.updatePokemonInTeam(
                            teamIndex,
                            memberIndex,
                            TeamMember(
                              id: prevEvo['id'],
                              name: prevEvo['name'],
                              image: prevEvo['image'],
                              moves: currentMember.moves,
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    if (nextEvo != null)
                      ListTile(
                        leading: Image.network(nextEvo['image'], width: 36),
                        title: Text('Evolucionar a ${nextEvo['name'].toString().toUpperCase()}', style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.arrow_upward, color: Colors.greenAccent),
                        onTap: () {
                          appState.updatePokemonInTeam(
                            teamIndex,
                            memberIndex,
                            TeamMember(
                              id: nextEvo['id'],
                              name: nextEvo['name'],
                              image: nextEvo['image'],
                              moves: currentMember.moves,
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    if (prevEvo == null && nextEvo == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Este Pokémon no posee evoluciones adicionales en su línea.', style: TextStyle(color: Colors.grey)),
                      ),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
                      title: const Text('Ver Tarjeta de Detalle', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PokemonDetailScreen(pokemonId: currentMember.id, name: currentMember.name),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
            );
          }
        }
      }
    } catch (_) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _generateRandomTeamDialog(BuildContext context) {
    int genFilter = 0;
    String typeFilter = "todos";
    String evoFilter = "todos";

    final List<String> typesList = [
      "todos", "fire", "water", "grass", "electric", "ice", "fighting",
      "poison", "ground", "flying", "psychic", "bug", "rock", "ghost",
      "dragon", "steel", "fairy", "normal"
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text('Generar Equipo Aleatorio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: genFilter,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Generación', labelStyle: TextStyle(color: Colors.grey)),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Todas (Gen 1-6)')),
                      DropdownMenuItem(value: 1, child: Text('Gen 1 (Kanto)')),
                      DropdownMenuItem(value: 2, child: Text('Gen 2 (Johto)')),
                      DropdownMenuItem(value: 3, child: Text('Gen 3 (Hoenn)')),
                      DropdownMenuItem(value: 4, child: Text('Gen 4 (Sinnoh)')),
                      DropdownMenuItem(value: 5, child: Text('Gen 5 (Unova)')),
                      DropdownMenuItem(value: 6, child: Text('Gen 6 (Kalos)')),
                    ],
                    onChanged: (val) => setDialogState(() => genFilter = val ?? 0),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: typeFilter,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Tipo Específico', labelStyle: TextStyle(color: Colors.grey)),
                    items: typesList.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                    onChanged: (val) => setDialogState(() => typeFilter = val ?? "todos"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: evoFilter,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Estado Evolutivo', labelStyle: TextStyle(color: Colors.grey)),
                    items: const [
                      DropdownMenuItem(value: "todos", child: Text('Cualquier Estado')),
                      DropdownMenuItem(value: "base", child: Text('Fase Inicial (Primera Etapa)')),
                    ],
                    onChanged: (val) => setDialogState(() => evoFilter = val ?? "todos"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _buildRandomTeamProcess(context, genFilter, typeFilter, evoFilter);
                },
                child: const Text('Generar 6 Pokémon', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _buildRandomTeamProcess(BuildContext context, int genFilter, String typeFilter, String evoFilter) async {
    bool loaderDismissed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(
        child: Card(
          color: Color(0xFF2C2C2C),
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.purpleAccent),
                SizedBox(height: 15),
                Text('Generando equipo...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    Timer(const Duration(seconds: 4), () {
      if (!loaderDismissed && context.mounted) {
        loaderDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    try {
      List<int> candidateIds = [];

      if (typeFilter != "todos") {
        final typeRes = await http.get(Uri.parse('https://pokeapi.co/api/v2/type/$typeFilter')).timeout(const Duration(seconds: 3));
        if (typeRes.statusCode == 200) {
          final typeData = jsonDecode(typeRes.body);
          final List pList = typeData['pokemon'] as List;
          for (var item in pList) {
            final String url = item['pokemon']['url'] as String;
            final parts = url.split('/');
            final id = int.parse(parts[parts.length - 2]);
            if (_belongsToGen(id, genFilter)) {
              candidateIds.add(id);
            }
          }
        }
      } else {
        int minId = 1;
        int maxId = 721;
        if (genFilter == 1) { minId = 1; maxId = 151; }
        if (genFilter == 2) { minId = 152; maxId = 251; }
        if (genFilter == 3) { minId = 252; maxId = 386; }
        if (genFilter == 4) { minId = 387; maxId = 493; }
        if (genFilter == 5) { minId = 494; maxId = 649; }
        if (genFilter == 6) { minId = 650; maxId = 721; }

        candidateIds = List.generate(maxId - minId + 1, (i) => minId + i);
      }

      candidateIds.shuffle();
      List<TeamMember> randomMembers = [];
      final random = Random();

      for (int id in candidateIds) {
        if (randomMembers.length >= 6) break;

        try {
          if (evoFilter != "todos") {
            final speciesRes = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$id')).timeout(const Duration(seconds: 2));
            if (speciesRes.statusCode == 200) {
              final speciesData = jsonDecode(speciesRes.body);
              final evolvesFrom = speciesData['evolves_from_species'];
              if (evoFilter == "base" && evolvesFrom != null) continue;
            }
          }

          final res = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id')).timeout(const Duration(seconds: 2));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final name = data['name'] as String;
            final img = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png";

            List<String> moves = [];
            if (data['moves'] != null) {
              var rawMoves = (data['moves'] as List);
              rawMoves.shuffle();
              for (var m in rawMoves.take(4)) {
                moves.add((m['move']['name'] as String).toUpperCase());
              }
            }

            randomMembers.add(TeamMember(id: id, name: name, image: img, moves: moves));
          }
        } catch (_) {}
      }

      if (randomMembers.isNotEmpty) {
        String teamName = "Equipo Aleatorio #${random.nextInt(900) + 100}";
        appState.saveTeam(teamName);
        int newTeamIdx = appState.teams.length - 1;

        for (var m in randomMembers) {
          appState.addPokemonToTeam(newTeamIdx, m);
        }
      }
    } catch (_) {
    } finally {
      if (!loaderDismissed && context.mounted) {
        loaderDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  bool _belongsToGen(int id, int gen) {
    if (gen == 0) return id >= 1 && id <= 721;
    if (gen == 1) return id >= 1 && id <= 151;
    if (gen == 2) return id >= 152 && id <= 251;
    if (gen == 3) return id >= 252 && id <= 386;
    if (gen == 4) return id >= 387 && id <= 493;
    if (gen == 5) return id >= 494 && id <= 649;
    if (gen == 6) return id >= 650 && id <= 721;
    return true;
  }

  void _showMoveSelector(BuildContext context, int teamIndex, int memberIndex, TeamMember member) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/${member.id}')).timeout(const Duration(seconds: 4));
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<String> availableMoves = [];
        if (data['moves'] != null) {
          for (var m in (data['moves'] as List)) {
            availableMoves.add((m['move']['name'] as String).toUpperCase());
          }
        }

        List<String> selectedMoves = List.from(member.moves);

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (dialogCtx) => StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF2C2C2C),
                  title: Text('Movimientos de ${member.name.toUpperCase()} (Máx 4)', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ListView.builder(
                      itemCount: availableMoves.length,
                      itemBuilder: (context, index) {
                        final move = availableMoves[index];
                        final isSelected = selectedMoves.contains(move);
                        return CheckboxListTile(
                          title: Text(move, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          value: isSelected,
                          activeColor: Colors.teal,
                          onChanged: (bool? val) {
                            setDialogState(() {
                              if (val == true) {
                                if (selectedMoves.length < 4) selectedMoves.add(move);
                              } else {
                                selectedMoves.remove(move);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        appState.updatePokemonMoves(teamIndex, memberIndex, selectedMoves);
                        Navigator.pop(dialogCtx);
                      },
                      child: const Text('Guardar Set'),
                    )
                  ],
                );
              },
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text('Mis Equipos Pokémon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          if (appState.teams.isEmpty) {
            return const Center(
              child: Text('No has creado ningún equipo aún.', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            itemCount: appState.teams.length,
            itemBuilder: (context, index) {
              final team = appState.teams[index];
              final members = team.members;
              return Card(
                color: const Color(0xFF242424),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: ExpansionTile(
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.grey,
                  title: Row(
                    children: [
                      const Icon(Icons.catching_pokemon, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.amber, size: 20),
                        onPressed: () => _renameTeamDialog(context, index, team.name),
                        tooltip: 'Renombrar equipo',
                      ),
                    ],
                  ),
                  subtitle: Text('Integrantes: ${members.length}/6', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => appState.deleteTeam(index),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Integrantes (Toca la foto o nombre para Evolucionar / Desevolucionar):', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            itemBuilder: (context, memberIdx) {
                              final m = members[memberIdx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showEvolutionOptions(context, index, memberIdx, m),
                                      child: Image.network(m.image, width: 40, height: 40),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showEvolutionOptions(context, index, memberIdx, m),
                                            child: Text(m.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                          const SizedBox(height: 4),
                                          m.moves.isEmpty
                                              ? const Text('Sin movimientos asignados', style: TextStyle(color: Colors.grey, fontSize: 11))
                                              : Wrap(
                                                  spacing: 4,
                                                  children: m.moves.map((moveName) {
                                                    return InkWell(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => MoveDetailScreen(moveName: moveName),
                                                          ),
                                                        );
                                                      },
                                                      child: Chip(
                                                        padding: EdgeInsets.zero,
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        backgroundColor: Colors.teal.withOpacity(0.3),
                                                        label: Text(moveName, style: const TextStyle(color: Colors.tealAccent, fontSize: 10)),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.transform, color: Colors.greenAccent),
                                      onPressed: () => _showEvolutionOptions(context, index, memberIdx, m),
                                      tooltip: 'Evolucionar / Involucionar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_note, color: Colors.amber),
                                      onPressed: () => _showMoveSelector(context, index, memberIdx, m),
                                      tooltip: 'Editar Movimientos',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                                      onPressed: () => appState.removePokemonFromTeam(index, memberIdx),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'random_btn',
            onPressed: () => _generateRandomTeamDialog(context),
            icon: const Icon(Icons.casino),
            label: const Text('Equipo Aleatorio'),
            backgroundColor: Colors.purple,
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_btn',
            onPressed: () => _createTeamDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}