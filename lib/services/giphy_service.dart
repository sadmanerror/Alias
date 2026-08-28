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

  Future<List<GiphyGif>> searchGifs(String query, {int offset = 0, int limit = 20}) async {
    final url = Uri.parse('$_baseUrl/search?api_key=${AppConfig.giphyApiKey}&q=$query&limit=$limit&offset=$offset');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List gifs = data['data'];
      return gifs.map((g) => GiphyGif.fromJson(g)).toList();
    }
    return [];
  }

  Future<List<GiphyGif>> trendingGifs({int offset = 0, int limit = 20}) async {
    final url = Uri.parse('$_baseUrl/trending?api_key=${AppConfig.giphyApiKey}&limit=$limit&offset=$offset');
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List gifs = data['data'];
      return gifs.map((g) => GiphyGif.fromJson(g)).toList();
    }
    return [];
  }
}
