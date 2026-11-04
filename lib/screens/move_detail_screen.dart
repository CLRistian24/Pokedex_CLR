import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/app_state.dart';
import '../models/pokedex_theme.dart';

class MoveDetailScreen extends StatefulWidget {
  final String moveName;

  const MoveDetailScreen({super.key, required this.moveName});

  @override
  State<MoveDetailScreen> createState() => _MoveDetailScreenState();
}

class _MoveDetailScreenState extends State<MoveDetailScreen> {
  Map<String, dynamic>? _moveData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMoveDetails();
  }

  Future<void> _fetchMoveDetails() async {
    final formattedName = widget.moveName.toLowerCase().replaceAll(' ', '-');
    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/move/$formattedName'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _moveData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getDescription() {
    if (_moveData == null || _moveData!['flavor_text_entries'] == null) return "Sin descripción disponible.";
    final entries = _moveData!['flavor_text_entries'] as List;
    
    // Intentar buscar texto en español, si no tomar en inglés
    for (var entry in entries) {
      if (entry['language']['name'] == 'es') {
        return entry['flavor_text'].toString().replaceAll('\n', ' ');
      }
    }
    for (var entry in entries) {
      if (entry['language']['name'] == 'en') {
        return entry['flavor_text'].toString().replaceAll('\n', ' ');
      }
    }
    return "Sin descripción disponible.";
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = getPokedexColor(appState.theme);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: Text(widget.moveName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _moveData == null
              ? const Center(child: Text('No se encontró información del movimiento.', style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          widget.moveName.toUpperCase(),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeColor),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: themeColor.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Descripción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(_getDescription(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoStat('Tipo', _moveData!['type']['name'].toString().toUpperCase(), Colors.amber),
                          _infoStat('Clase', _moveData!['damage_class']['name'].toString().toUpperCase(), Colors.cyanAccent),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoStat('Poder', '${_moveData!['power'] ?? '—'}', Colors.redAccent),
                          _infoStat('Precisión', '${_moveData!['accuracy'] ?? '—'}%', Colors.lightGreenAccent),
                          _infoStat('PP', '${_moveData!['pp'] ?? '—'}', Colors.purpleAccent),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoStat(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}