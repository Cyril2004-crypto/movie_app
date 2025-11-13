import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie.dart';
import 'cache_service.dart';

class ApiService {
  final Dio _dio;
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final CacheService _cache = CacheService();

  ApiService([Dio? dio]) : _dio = dio ?? Dio();

  String _apiKey() {
    final apiKey = dotenv.env['TMDB_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY not found. Add it to .env (assets/.env for desktop).');
    }
    return apiKey;
  }

  String _cacheKey(String path, Map<String, dynamic> qp) {
    final params = qp.entries.map((e) => '${e.key}=${e.value}').toList()..sort();
    return 'api:$path?${params.join('&')}';
  }

  Future<List<Movie>> fetchPopularMovies({int page = 1, bool forceRefresh = false}) async {
    final path = '/movie/popular';
    final qp = {'api_key': _apiKey(), 'language': 'en-US', 'page': page};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) {
        final results = (cached as List).cast<Map>().map((e) => Movie.fromJson(Map<String, dynamic>.from(e))).toList();
        return results;
      }
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    await _cache.setCache(key, results, ttlSeconds: 3600); // 1 hour
    return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1, bool forceRefresh = false}) async {
    final path = '/search/movie';
    final qp = {'api_key': _apiKey(), 'language': 'en-US', 'query': query, 'page': page, 'include_adult': false};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) {
        final results = (cached as List).cast<Map>().map((e) => Movie.fromJson(Map<String, dynamic>.from(e))).toList();
        return results;
      }
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    await _cache.setCache(key, results, ttlSeconds: 600); // short cache for search
    return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getMovieDetails(int id, {bool forceRefresh = false}) async {
    final path = '/movie/$id';
    final qp = {'api_key': _apiKey(), 'language': 'en-US'};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) return Map<String, dynamic>.from(cached as Map);
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    await _cache.setCache(key, Map<String, dynamic>.from(res.data as Map), ttlSeconds: 86400); // 24h
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<Map<String, dynamic>>> getMovieVideos(int id, {bool forceRefresh = false}) async {
    final path = '/movie/$id/videos';
    final qp = {'api_key': _apiKey(), 'language': 'en-US'};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) return (cached as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    await _cache.setCache(key, results, ttlSeconds: 86400);
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getMovieCredits(int id, {bool forceRefresh = false}) async {
    final path = '/movie/$id/credits';
    final qp = {'api_key': _apiKey(), 'language': 'en-US'};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) return (cached as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    final results = (res.data['cast'] as List<dynamic>? ?? <dynamic>[]);
    await _cache.setCache(key, results, ttlSeconds: 86400);
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getMovieRecommendations(int id, {int page = 1, bool forceRefresh = false}) async {
    final path = '/movie/$id/recommendations';
    final qp = {'api_key': _apiKey(), 'language': 'en-US', 'page': page};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) return (cached as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    await _cache.setCache(key, results, ttlSeconds: 3600);
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // person details
  Future<Map<String, dynamic>> getPersonDetails(int id, {bool forceRefresh = false}) async {
    final path = '/person/$id';
    final qp = {'api_key': _apiKey(), 'language': 'en-US'};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) return Map<String, dynamic>.from(cached as Map);
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    await _cache.setCache(key, Map<String, dynamic>.from(res.data as Map), ttlSeconds: 86400);
    return Map<String, dynamic>.from(res.data as Map);
  }

  // person movie credits
  Future<List<Map<String, dynamic>>> getPersonMovieCredits(int id, {bool forceRefresh = false}) async {
    final path = '/person/$id/movie_credits';
    final qp = {'api_key': _apiKey(), 'language': 'en-US'};
    final key = _cacheKey(path, qp);

    if (!forceRefresh) {
      final cached = _cache.getCache(key);
      if (cached != null) return (cached as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    final results = (res.data['cast'] as List<dynamic>? ?? <dynamic>[]);
    await _cache.setCache(key, results, ttlSeconds: 86400);
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // search people
  Future<List<Map<String, dynamic>>> searchPeople(String query, {int page = 1}) async {
    final path = '/search/person';
    final qp = {'api_key': _apiKey(), 'language': 'en-US', 'query': query, 'page': page, 'include_adult': 'false'};
    final res = await _dio.get('$_baseUrl$path', queryParameters: qp);
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}