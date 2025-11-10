import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie.dart';

class ApiService {
  final Dio _dio;
  final String _baseUrl = 'https://api.themoviedb.org/3';

  ApiService([Dio? dio]) : _dio = dio ?? Dio();

  Future<List<Movie>> fetchPopularMovies({int page = 1}) async {
    final apiKey = dotenv.env['TMDB_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY not found. Add it to .env');
    }

    final res = await _dio.get('$_baseUrl/movie/popular', queryParameters: {
      'api_key': apiKey,
      'language': 'en-US',
      'page': page,
    });

    final results = (res.data['results'] as List<dynamic>? ?? <dynamic>[]);
    return results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
  }
}