import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PokemonSummary {
  final int id;
  final String name;

  PokemonSummary({required this.id, required this.name});

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    String url = json['url'];
    // Extrai o ID da URL que vem no formato: "https://pokeapi.co/api/v2/pokemon/1/"
    List<String> segments = url.split('/').where((s) => s.isNotEmpty).toList();
    int id = int.tryParse(segments.last) ?? 0;
    return PokemonSummary(id: id, name: json['name']);
  }
}

class PokemonStat {
  final String name;
  final int baseStat;

  PokemonStat({required this.name, required this.baseStat});
}

class PokemonDetail {
  final int id;
  final String name;
  final List<String> types;
  final double weight;
  final double height;
  final List<PokemonStat> stats;

  PokemonDetail({
    required this.id,
    required this.name,
    required this.types,
    required this.weight,
    required this.height,
    required this.stats,
  });

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    return PokemonDetail(
      id: json['id'],
      name: json['name'],
      types: (json['types'] as List).map((t) => t['type']['name'].toString()).toList(),
      weight: (json['weight'] ?? 0) / 10.0, // convert to kg
      height: (json['height'] ?? 0) / 10.0, // convert to m
      stats: (json['stats'] as List)
          .map((s) => PokemonStat(
                name: s['stat']['name'].toString(),
                baseStat: s['base_stat'],
              ))
          .toList(),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  Future<List<PokemonSummary>> fetchInitialList({int offset = 0, int limit = 20}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pokemon?offset=$offset&limit=$limit'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List results = data['results'];
        return results.map((e) => PokemonSummary.fromJson(e)).toList();
      } else {
        throw Exception('Falha ao carregar a lista de Pokémon.');
      }
    } on SocketException {
      throw Exception('Você parece estar offline. Verifique sua conexão.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<List<PokemonSummary>> searchPokemon(String query) async {
    try {
      // API requires lowercase search queries
      final response = await http.get(Uri.parse('$baseUrl/pokemon/${query.toLowerCase()}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Map the full detail back to a summary format for the list
        return [PokemonSummary(id: data['id'], name: data['name'])];
      } else if (response.statusCode == 404) {
        throw Exception('Pokémon não encontrado (Erro 404). Verifique o nome ou ID.');
      } else {
        throw Exception('Falha ao buscar o Pokémon.');
      }
    } on SocketException {
      throw Exception('Você parece estar offline. Verifique sua conexão.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<PokemonDetail> fetchPokemonDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/pokemon/$id'));
    if (response.statusCode == 200) {
      return PokemonDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao detalhar o Pokémon.');
    }
  }

  Future<List<String>> fetchEvolutions(int pokemonId) async {
    try {
      // 1. Fetch species to get evolution chain URL
      final speciesResponse = await http.get(Uri.parse('$baseUrl/pokemon-species/$pokemonId/'));
      if (speciesResponse.statusCode != 200) return [];
      
      final speciesData = jsonDecode(speciesResponse.body);
      final evolutionChainUrl = speciesData['evolution_chain']['url'];

      // 2. Fetch evolution chain
      final evoResponse = await http.get(Uri.parse(evolutionChainUrl));
      if (evoResponse.statusCode != 200) return [];
      
      final evoData = jsonDecode(evoResponse.body);
      List<String> evolutions = [];
      var chain = evoData['chain'];
      
      while (chain != null) {
        evolutions.add(chain['species']['name']);
        if (chain['evolves_to'] != null && (chain['evolves_to'] as List).isNotEmpty) {
          chain = chain['evolves_to'][0]; // Selects primary evolution branch only
        } else {
          chain = null;
        }
      }
      return evolutions;
    } catch (e) {
      return []; // Return empty list on failure for progressive degradation
    }
  }
}
