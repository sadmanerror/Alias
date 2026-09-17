import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alias/core/config/app_config.dart';

class GiphyGif {
  final String id;
  final String title;
  final String previewUrl;
  final String originalUrl;
  final double aspectRatio;

  GiphyGif({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.originalUrl,
    required this.aspectRatio,
  });

  String get url => originalUrl;

  factory GiphyGif.fromJson(Map<String, dynamic> json) {
    final preview = json['images']['fixed_width_small']['url'];
    final original = json['images']['original']['url'];
    final width = double.tryParse(json['images']['original']['width']?.toString() ?? '1.0') ?? 1.0;
    final height = double.tryParse(json['images']['original']['height']?.toString() ?? '1.0') ?? 1.0;
    
    return GiphyGif(
      id: json['id'],
      title: json['title'],
      previewUrl: preview,
      originalUrl: original,
      aspectRatio: width / height,
    );
  }
}

class GiphyService {
  final http.Client _client;
  static const String _baseUrl = AppConfig.giphyBaseUrl;

  GiphyService(this._client);

  static bool get isApiKeyConfigured =>
      AppConfig.giphyApiKey.isNotEmpty &&
      AppConfig.giphyApiKey != 'YOUR_GIPHY_API_KEY';

  static final List<GiphyGif> _curatedFallbackGifs = [
    GiphyGif(
      id: 'wave',
      title: 'Hello Wave',
      previewUrl: 'https://media.giphy.com/media/3o7TKMt1VVNkHV2PaE/200w.gif',
      originalUrl: 'https://media.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif',
      aspectRatio: 1.0,
    ),
    GiphyGif(
      id: 'thumbsup',
      title: 'Thumbs Up',
      previewUrl: 'https://media.giphy.com/media/111ebonMs90YLu/200w.gif',
      originalUrl: 'https://media.giphy.com/media/111ebonMs90YLu/giphy.gif',
      aspectRatio: 1.33,
    ),
    GiphyGif(
      id: 'laughing',
      title: 'Laughing',
      previewUrl: 'https://media.giphy.com/media/26n6Gx9moCgs1qxxt/200w.gif',
      originalUrl: 'https://media.giphy.com/media/26n6Gx9moCgs1qxxt/giphy.gif',
      aspectRatio: 1.0,
    ),
    GiphyGif(
      id: 'mindblown',
      title: 'Mind Blown',
      previewUrl: 'https://media.giphy.com/media/26ufdipQqU2lhNA4g/200w.gif',
      originalUrl: 'https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif',
      aspectRatio: 1.0,
    ),
    GiphyGif(
      id: 'party',
      title: 'Party Dance',
      previewUrl: 'https://media.giphy.com/media/blSTtZehjAZ8I/200w.gif',
      originalUrl: 'https://media.giphy.com/media/blSTtZehjAZ8I/giphy.gif',
      aspectRatio: 1.2,
    ),
    GiphyGif(
      id: 'cat',
      title: 'Cat Typing',
      previewUrl: 'https://media.giphy.com/media/JIX9t2j0ZTN9S/200w.gif',
      originalUrl: 'https://media.giphy.com/media/JIX9t2j0ZTN9S/giphy.gif',
      aspectRatio: 1.25,
    ),
    GiphyGif(
      id: 'clapping',
      title: 'Applause',
      previewUrl: 'https://media.giphy.com/media/nbvFVPiEiJH6JOGIok/200w.gif',
      originalUrl: 'https://media.giphy.com/media/nbvFVPiEiJH6JOGIok/giphy.gif',
      aspectRatio: 1.0,
    ),
    GiphyGif(
      id: 'wow',
      title: 'Excited Wow',
      previewUrl: 'https://media.giphy.com/media/5VKbvrjxpVJCM/200w.gif',
      originalUrl: 'https://media.giphy.com/media/5VKbvrjxpVJCM/giphy.gif',
      aspectRatio: 1.33,
    ),
    GiphyGif(
      id: 'confused',
      title: 'Confused',
      previewUrl: 'https://media.giphy.com/media/g01ZnwAUvutuK8GIQn/200w.gif',
      originalUrl: 'https://media.giphy.com/media/g01ZnwAUvutuK8GIQn/giphy.gif',
      aspectRatio: 1.2,
    ),
    GiphyGif(
      id: 'yes',
      title: 'Yes Yes Yes',
      previewUrl: 'https://media.giphy.com/media/3oFzmdYd4bfkv2PWTe/200w.gif',
      originalUrl: 'https://media.giphy.com/media/3oFzmdYd4bfkv2PWTe/giphy.gif',
      aspectRatio: 1.0,
    ),
    GiphyGif(
      id: 'heart',
      title: 'Heart Love',
      previewUrl: 'https://media.giphy.com/media/26BRv0ThflsDTqUXa/200w.gif',
      originalUrl: 'https://media.giphy.com/media/26BRv0ThflsDTqUXa/giphy.gif',
      aspectRatio: 1.0,
    ),
    GiphyGif(
      id: 'cool',
      title: 'Deal With It',
      previewUrl: 'https://media.giphy.com/media/3o7btXkbsV26U95Uly/200w.gif',
      originalUrl: 'https://media.giphy.com/media/3o7btXkbsV26U95Uly/giphy.gif',
      aspectRatio: 1.33,
    ),
  ];

  Future<List<GiphyGif>> searchGifs(String query, {int offset = 0, int limit = 20}) async {
    if (!isApiKeyConfigured) {
      final q = query.toLowerCase().trim();
      if (q.isEmpty) return _curatedFallbackGifs;
      final matched = _curatedFallbackGifs
          .where((g) => g.title.toLowerCase().contains(q))
          .toList();
      return matched.isNotEmpty ? matched : _curatedFallbackGifs;
    }

    try {
      final url = Uri.parse('$_baseUrl/search?api_key=${AppConfig.giphyApiKey}&q=$query&limit=$limit&offset=$offset');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List gifs = data['data'];
        return gifs.map((g) => GiphyGif.fromJson(g)).toList();
      }
    } catch (_) {}
    return _curatedFallbackGifs;
  }

  Future<List<GiphyGif>> trendingGifs({int offset = 0, int limit = 20}) async {
    if (!isApiKeyConfigured) {
      return _curatedFallbackGifs;
    }

    try {
      final url = Uri.parse('$_baseUrl/trending?api_key=${AppConfig.giphyApiKey}&limit=$limit&offset=$offset');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List gifs = data['data'];
        final list = gifs.map((g) => GiphyGif.fromJson(g)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return _curatedFallbackGifs;
  }
}
