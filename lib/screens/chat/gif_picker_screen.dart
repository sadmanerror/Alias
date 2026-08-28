import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alias/services/giphy_service.dart';
import 'package:alias/providers/chat_provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GifPickerScreen extends ConsumerStatefulWidget {
  final String? chatId;

  const GifPickerScreen({super.key, this.chatId});

  @override
  ConsumerState<GifPickerScreen> createState() => _GifPickerScreenState();
}

class _GifPickerScreenState extends ConsumerState<GifPickerScreen> {
  static const Color offWhite = Color(0xFFF7F7F7);
  static const Color primarySageGreen = Color(0xFF8DA399);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  
  final List<GiphyGif> _gifs = [];
  bool _isLoading = false;
  int _offset = 0;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTrending();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final giphyService = ref.read(giphyServiceProvider);
      final results = await giphyService.trendingGifs(offset: _offset);
      setState(() {
        _gifs.addAll(results);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.isEmpty) {
      _currentQuery = '';
      _offset = 0;
      _gifs.clear();
      _loadTrending();
      return;
    }

    setState(() {
      _isLoading = true;
      _currentQuery = query;
      _offset = 0;
      _gifs.clear();
    });

    try {
      final giphyService = ref.read(giphyServiceProvider);
      final results = await giphyService.searchGifs(query, offset: _offset);
      setState(() {
        _gifs.addAll(results);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _offset += 20;
      _isLoading = true;
    });
    if (_currentQuery.isEmpty) {
      await _loadTrending();
    } else {
      try {
        final giphyService = ref.read(giphyServiceProvider);
        final results = await giphyService.searchGifs(_currentQuery, offset: _offset);
        setState(() {
          _gifs.addAll(results);
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchGifs(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: offWhite,
        elevation: 0,
        title: const Text('Choose a GIF', style: TextStyle(color: Color(0xFF2C3E35))),
        iconTheme: const IconThemeData(color: Color(0xFF2C3E35)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search Tenor/Giphy...',
                prefixIcon: const Icon(Icons.search, color: primarySageGreen),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _gifs.isEmpty && !_isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('😔', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('No GIFs found', style: TextStyle(color: Color(0xFF6B7C74))),
                ],
              ),
            )
          : MasonryGridView.count(
              controller: _scrollController,
              crossAxisCount: 2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              itemCount: _gifs.length + (_isLoading ? 4 : 0),
              itemBuilder: (context, index) {
                if (index >= _gifs.length) {
                  return Container(
                    height: 150,
                    color: Colors.grey[300], // Simple shimmer placeholder
                  );
                }
                final gif = _gifs[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, gif),
                  child: CachedNetworkImage(
                    imageUrl: gif.previewUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                );
              },
            ),
    );
  }
}
