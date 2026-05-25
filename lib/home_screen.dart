import 'package:flutter/material.dart';
import 'api_service.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<PokemonSummary> _pokemonList = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isSearching = false;
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _fetchList();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >= 400 && !_showBackToTopButton) {
      setState(() {
        _showBackToTopButton = true;
      });
    } else if (_scrollController.offset < 400 && _showBackToTopButton) {
      setState(() {
        _showBackToTopButton = false;
      });
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && !_isSearching) {
        _fetchList();
      }
    }
  }

  Future<void> _fetchList() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newPokemon = await _apiService.fetchInitialList(offset: _offset, limit: _limit);
      setState(() {
        _offset += _limit;
        _pokemonList.addAll(newPokemon);
        if (newPokemon.length < _limit) {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _pokemonList.clear();
        _offset = 0;
        _hasMore = true;
      });
      _fetchList();
      FocusScope.of(context).unfocus();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _hasError = false;
      _pokemonList.clear();
    });

    try {
      final result = await _apiService.searchPokemon(query);
      setState(() {
        _pokemonList = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
    FocusScope.of(context).unfocus();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pokédex', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFF1E1E1E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _performSearch(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou ID...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                    onPressed: _performSearch,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError && _pokemonList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sensors_off, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSearching ? _performSearch : _fetchList,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      );
    }

    if (_pokemonList.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    if (_pokemonList.isEmpty && !_isLoading) {
      return const Center(
        child: Text('Nenhum Pokémon encontrado.', style: TextStyle(fontSize: 16, color: Colors.white70)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _pokemonList.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _pokemonList.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
          );
        }

        final pokemon = _pokemonList[index];
        return StaggeredCard(
          index: index,
          child: Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.black45,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Hero(
                tag: 'poke-${pokemon.id}',
                child: Image.network(
                  pokemon.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.redAccent,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
              ),
              title: Text(
                _capitalize(pokemon.name),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              subtitle: Text('#${pokemon.id.toString().padLeft(3, '0')}', style: const TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 600),
                    reverseTransitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(pokemonSummary: pokemon),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class StaggeredCard extends StatefulWidget {
  final Widget child;
  final int index;
  const StaggeredCard({super.key, required this.child, required this.index});

  @override
  State<StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<StaggeredCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 50 * (widget.index % 20)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
