import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokedex_theme.dart';

class TeamMember {
  final int id;
  final String name;
  final String image;
  List<String> moves;

  TeamMember({
    required this.id,
    required this.name,
    required this.image,
    List<String>? moves,
  }) : moves = moves ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'moves': moves,
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    var rawMoves = json['moves'] as List? ?? [];
    return TeamMember(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String,
      moves: rawMoves.map((m) => m.toString()).toList(),
    );
  }
}

class TeamModel {
  String name;
  final List<TeamMember> members;

  TeamModel({required this.name, required this.members});

  Map<String, dynamic> toJson() => {
        'name': name,
        'members': members.map((m) => m.toJson()).toList(),
      };

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List;
    List<TeamMember> memberList = rawMembers
        .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
        .toList();
    return TeamModel(name: json['name'] as String, members: memberList);
  }
}

class AppState with ChangeNotifier {
  PokedexColorTheme _theme = PokedexColorTheme.red;
  List<String> _favorites = [];
  List<TeamModel> _teams = [];

  PokedexColorTheme get theme => _theme;
  List<String> get favorites => _favorites;
  List<TeamModel> get teams => _teams;

  AppState() {
    _loadState();
  }

  void setTheme(PokedexColorTheme newTheme) async {
    _theme = newTheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_index', newTheme.index);
  }

  void toggleFavorite(String name) async {
    if (_favorites.contains(name)) {
      _favorites.remove(name);
    } else {
      _favorites.add(name);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites', _favorites);
  }

  void saveTeam(String name) async {
    _teams.add(TeamModel(name: name, members: []));
    _saveTeamsToPrefs();
  }

  void renameTeam(int teamIndex, String newName) {
    _teams[teamIndex].name = newName;
    _saveTeamsToPrefs();
  }

  bool canAddPokemonToTeam(int teamIndex, String pokemonName, List<String> evolutionFamily) {
    List<TeamMember> members = _teams[teamIndex].members;
    if (members.length >= 6) return false;

    for (var m in members) {
      String memberName = m.name.toLowerCase();
      if (memberName == pokemonName.toLowerCase() || evolutionFamily.contains(memberName)) {
        return false;
      }
    }
    return true;
  }

  void addPokemonToTeam(int teamIndex, TeamMember member) async {
    List<TeamMember> members = _teams[teamIndex].members;
    if (members.length < 6) {
      members.add(member);
      _saveTeamsToPrefs();
    }
  }

  void updatePokemonMoves(int teamIndex, int memberIndex, List<String> newMoves) {
    _teams[teamIndex].members[memberIndex].moves = newMoves;
    _saveTeamsToPrefs();
  }

  void updatePokemonInTeam(int teamIndex, int memberIndex, TeamMember newMember) {
    _teams[teamIndex].members[memberIndex] = newMember;
    _saveTeamsToPrefs();
  }

  void removePokemonFromTeam(int teamIndex, int pokemonIndex) async {
    _teams[teamIndex].members.removeAt(pokemonIndex);
    _saveTeamsToPrefs();
  }

  void deleteTeam(int index) async {
    _teams.removeAt(index);
    _saveTeamsToPrefs();
  }

  void _saveTeamsToPrefs() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final rawData = _teams.map((t) => t.toJson()).toList();
    prefs.setString('teams', jsonEncode(rawData));
  }

  void _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    int themeIdx = prefs.getInt('theme_index') ?? 0;
    _theme = PokedexColorTheme.values[themeIdx];
    _favorites = prefs.getStringList('favorites') ?? [];
    String? teamsJson = prefs.getString('teams');
    if (teamsJson != null) {
      List rawList = jsonDecode(teamsJson) as List;
      _teams = rawList
          .map((item) => TeamModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }
}

final appState = AppState();