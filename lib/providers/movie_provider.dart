import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class MovieProvider extends ChangeNotifier {
  final ApiService apiService;
  List<Movie> movies = [];
  bool loading = false;
  String? error;

  // pagination
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  // search
  String _query = '';
  Timer? _debounce;

  final Box _favoritesBox = Hive.box('favorites');

  MovieProvider({required this.apiService});

  Future<void> fetchPopularMovies({bool refresh = false}) async {
    if (loading || _loadingMore) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      movies = [];
    }
    loading = _page == 1;
    _loadingMore = _page > 1;
    error = null;
    notifyListeners();
    try {
      final fetched = await apiService.fetchPopularMovies(page: _page);
      if (refresh) {
        movies = fetched;
      } else {
        movies.addAll(fetched);
      }
      if (fetched.isEmpty) _hasMore = false;
      _page++;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchPopularMovies(refresh: true);

  // infinite scroll trigger
  Future<void> loadMoreIfNeeded() async {
    if (!_hasMore) return;
    await fetchPopularMovies();
  }

  // Search with debounce
  void search(String query) {
    _debounce?.cancel();
    _query = query;
    if (query.trim().isEmpty) {
      // clear search -> show popular (reset)
      _page = 1;
      movies = [];
      fetchPopularMovies(refresh: true);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(query));
  }

  Future<void> _performSearch(String query, {int page = 1}) async {
    loading = true;
    error = null;
    movies = [];
    notifyListeners();
    try {
      final results = await apiService.searchMovies(query, page: page);
      movies = results;
      _hasMore = results.isNotEmpty;
      _page = page + 1;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // favorites
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