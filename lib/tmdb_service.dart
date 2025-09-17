import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TMDBService {

  // In-memory cache for TMDB poster paths, keyed by 'type:id'
  static final Map<String, String> _posterCache = {};
  static const String _posterPrefsPrefix = 'tmdb_poster_';

  static Future<String?> getPosterFromPrefs(String type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_posterPrefsPrefix$type:$id');
  }

  static Future<void> savePosterToPrefs(String type, String id, String posterPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_posterPrefsPrefix$type:$id', posterPath);
  }

  static Future<String?> fetchTmdbPosterPath(String id, String type) async {
    final cacheKey = '$type:$id';
    // 1. Check in-memory cache
    if (_posterCache.containsKey(cacheKey)) {
      return _posterCache[cacheKey];
    }
    // 2. Check persistent cache
    final local = await getPosterFromPrefs(type, id);
    if (local != null) {
      _posterCache[cacheKey] = local;
      return local;
    }
    // 3. Fetch from TMDB
    final apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
    final endpoint = type == 'show' ? 'tv' : 'movie';
    final url = Uri.parse('https://api.themoviedb.org/3/$endpoint/$id?api_key=$apiKey');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final posterPath = data['poster_path'];
        if (posterPath != null && posterPath is String) {
          _posterCache[cacheKey] = posterPath;
          await savePosterToPrefs(type, id, posterPath);
          return posterPath;
        }
      }
    } catch (_) {}
    _posterCache[cacheKey] = '';
    await savePosterToPrefs(type, id, '');
    return null;
  }
  static String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';


  // In-memory cache for TMDB titles, keyed by 'type:id'
  static final Map<String, String> _titleCache = {};

  // Persistent cache key prefix
  static const String _prefsPrefix = 'tmdb_title_';

  // Get from persistent cache
  static Future<String?> getTitleFromPrefs(String type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefsPrefix$type:$id');
  }

  // Save to persistent cache
  static Future<void> saveTitleToPrefs(String type, String id, String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix$type:$id', title);
  }

  static Future<String> fetchTmdbTitle(String id, String type) async {
    final cacheKey = '$type:$id';
    // 1. Check in-memory cache
    if (_titleCache.containsKey(cacheKey)) {
      return _titleCache[cacheKey]!;
    }
    // 2. Check persistent cache
    final local = await getTitleFromPrefs(type, id);
    if (local != null) {
      _titleCache[cacheKey] = local;
      return local;
    }
    // 3. Fetch from TMDB
    final apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
    final endpoint = type == 'show' ? 'tv' : 'movie';
    final url = Uri.parse('https://api.themoviedb.org/3/$endpoint/$id?api_key=$apiKey');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String? title;
        if (type == 'show' && data['name'] != null) title = data['name'];
        if (type != 'show' && data['title'] != null) title = data['title'];
        if (title != null) {
          _titleCache[cacheKey] = title;
          await saveTitleToPrefs(type, id, title);
          return title;
        }
      }
    } catch (_) {}
    _titleCache[cacheKey] = 'Unknown TMDB';
    await saveTitleToPrefs(type, id, 'Unknown TMDB');
    return 'Unknown TMDB';
  }
  static Future<List<dynamic>> searchMovies(String query) async {
      final url = Uri.parse('$_baseUrl/search/multi?api_key=${_apiKey}&query=${Uri.encodeComponent(query)}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['results'] ?? [];
    } else {
      throw Exception('TMDB search failed: ${res.body}');
    }
  }


  static String getPosterUrl(String path) {
    return '$_imageBaseUrl$path';
  }

  static String? getLogoUrl(String? path) {
    if (path == null) return null;
    return '$_imageBaseUrl$path';
  }
}
