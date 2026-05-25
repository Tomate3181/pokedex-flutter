import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'api_service.dart';

class DetailScreen extends StatefulWidget {
  final PokemonSummary pokemonSummary;

  const DetailScreen({super.key, required this.pokemonSummary});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService _apiService = ApiService();
  Color? _dominantColor;
  late Future<PokemonDetail> _detailFuture;
  late Future<List<String>> _evolutionsFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _apiService.fetchPokemonDetail(widget.pokemonSummary.id);
    _evolutionsFuture = _apiService.fetchEvolutions(widget.pokemonSummary.id);
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.pokemonSummary.imageUrl),
      );
      if (mounted) {
        setState(() {
          _dominantColor = palette.dominantColor?.color ?? palette.darkMutedColor?.color ?? Colors.redAccent;
        });
      }
    } catch (_) {
      // Ignore if image fetch fails for palette
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    Color? baseColor = _dominantColor;
    
    // adjust luminance for dark bg
    final bgColor = baseColor != null 
        ? HSLColor.fromColor(baseColor).withLightness(0.2).withSaturation(0.6).toColor()
        : const Color(0xFF2C2C2B);

    final topTextColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: topTextColor),
        title: Text(
          _capitalize(widget.pokemonSummary.name),
          style: TextStyle(color: topTextColor, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Column(
        children: [
          Hero(
            tag: 'poke-${widget.pokemonSummary.id}',
            child: Center(
              child: Image.network(
                widget.pokemonSummary.imageUrl,
                height: 220,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white70,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 80, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: FutureBuilder<PokemonDetail>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar detalhes:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    );
                  }
                  if (!snapshot.hasData) return const SizedBox();

                  final detail = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Types Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: detail.types.map((t) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_dominantColor ?? Colors.redAccent).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _dominantColor ?? Colors.redAccent),
                            ),
                            child: Text(
                              _capitalize(t),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      
                      // Stats Row
                      const Text('Características', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Peso', '${detail.weight} kg', Icons.monitor_weight_outlined),
                          _buildStatItem('Altura', '${detail.height} m', Icons.height),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Base Stats Chart
                      const Text('Stats Base', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      ...detail.stats.map((s) => _buildStatBar(s, _dominantColor ?? Colors.redAccent)),
                      
                      const SizedBox(height: 32),
                      
                      // Evolutions
                      const Text('Cadeia de Evolução', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      FutureBuilder<List<String>>(
                        future: _evolutionsFuture,
                        builder: (context, evoSnapshot) {
                          if (evoSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final evos = evoSnapshot.data ?? [];
                          if (evos.isEmpty) {
                            return const Text('Nenhuma evolução correspondente listada.', style: TextStyle(color: Colors.white54));
                          }
                          
                          // Displaying evolution path
                          return Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: evos.map((e) {
                              bool isLast = e == evos.last;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      _capitalize(e),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    backgroundColor: bgColor.withOpacity(0.5),
                                    side: BorderSide(color: (_dominantColor ?? Colors.grey).withOpacity(0.5)),
                                  ),
                                  if (!isLast)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                                    )
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatBar(PokemonStat stat, Color color) {
    final double percentage = (stat.baseStat / 255.0).clamp(0.0, 1.0);
    
    String shortName = _capitalize(stat.name);
    if (stat.name == 'special-attack') shortName = 'Sp. Atk';
    if (stat.name == 'special-defense') shortName = 'Sp. Def';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              shortName,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              stat.baseStat.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: constraints.maxWidth * percentage,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
