import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie.dart';

class ApiService {
  final Dio _dio;
  final String _baseUrl = 'https://api.themoviedb.org/3';

  ApiService([Dio? dio]) : _dio = dio ?? Dio();

  String _apiKey() {
    final apiKey = dotenv.env['TMDB_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY not found. Add it to .env (assets/.env for desktop).');
    }
    return apiKey;
  }

  Future<List<Movie>> fetchPopularMovies({int page = 1}) async {
    final res = await _dio.get('$_baseUrl/movie/popular', queryParameters: {
      'api_key': _apiKey(),
      'language': 'en-US',
      'page': page,
    });
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final res = await _dio.get('$_baseUrl/search/movie', queryParameters: {
      'api_key': _apiKey(),
      'language': 'en-US',
      'query': query,
      'page': page,
      'include_adult': false,
    });
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getMovieDetails(int id) async {
    final res = await _dio.get('$_baseUrl/movie/$id', queryParameters: {
      'api_key': _apiKey(),
      'language': 'en-US',
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<Map<String, dynamic>>> getMovieVideos(int id) async {
    final res = await _dio.get('$_baseUrl/movie/$id/videos', queryParameters: {
      'api_key': _apiKey(),
      'language': 'en-US',
    });
    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}