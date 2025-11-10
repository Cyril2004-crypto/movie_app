import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class MovieProvider extends ChangeNotifier {
  final ApiService apiService;
  List<Movie> movies = [];
  bool loading = false;
  String? error;
  late final Box _favoritesBox;

  MovieProvider({required this.apiService}) {
    _favoritesBox = Hive.box('favorites');
  }

  Future<void> fetchPopularMovies() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      movies = await apiService.fetchPopularMovies();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Set<int> get favoriteIds {
    final raw = _favoritesBox.get('ids', defaultValue: <int>[]);
    return Set<int>.from((raw as List).cast<int>());
  }

  bool isFavorite(int id) => favoriteIds.contains(id);

  void toggleFavorite(int id) {
    final ids = favoriteIds;
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    _favoritesBox.put('ids', ids.toList());
    notifyListeners();
  }
}