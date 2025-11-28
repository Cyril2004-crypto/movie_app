import 'dart:async';
import 'dart:convert';
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

  // favorites details & local notes/ratings
  List<Movie> favoriteMovies = [];
  bool loadingFavorites = false;

  // --- new: genre-specific state ---
  List<Movie> _genreMovies = [];
  bool _genreLoading = false;

  List<Movie> get genreMovies => _genreMovies;
  bool get genreLoading => _genreLoading;

  MovieProvider({required this.apiService});

  // --- helper: normalize various API shapes into List<Movie> ---
  List<Movie> _toMovieList(dynamic raw) {
    if (raw == null) return <Movie>[];

    // If it's already a List<Movie>
    if (raw is List<Movie>) return raw;

    // If it's a Map that contains a list under common keys, unwrap it
    if (raw is Map) {
      for (final key in ['results', 'data', 'movies', 'items']) {
        final v = raw[key];
        if (v is List) {
          raw = v;
          break;
        }
      }
      // If still a Map here, and represents a single movie object, convert to list
      if (raw is Map) {
        // try treat map as a single movie object
        try {
          return [Movie.fromJson(Map<String, dynamic>.from(raw))];
        } catch (_) {
          return <Movie>[];
        }
      }
    }

    // At this point raw might be a List (of Map/Movie/other), a JSON string, or something else.
    if (raw is String) {
      try {
        final parsed = jsonDecode(raw);
        return _toMovieList(parsed);
      } catch (_) {
        return <Movie>[];
      }
    }

    if (raw is List) {
      final out = <Movie>[];
      for (final e in raw) {
        if (e is Movie) {
          out.add(e);
        } else if (e is Map) {
          try {
            out.add(Movie.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {
            // skip invalid entry
          }
        } else if (e is String) {
          // sometimes items are JSON strings
          try {
            final parsed = jsonDecode(e);
            if (parsed is Map) out.add(Movie.fromJson(Map<String, dynamic>.from(parsed)));
          } catch (_) {}
        }
      }
      return out;
    }

    return <Movie>[];
  }

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
      final fetchedRaw = await apiService.fetchPopularMovies(page: _page);
      final fetched = _toMovieList(fetchedRaw);
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
      final resultsRaw = await apiService.searchMovies(query, page: page);
      final results = _toMovieList(resultsRaw);
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

  /// Fetch full movie objects for saved favorite ids
  Future<void> fetchFavoriteMovies() async {
    loadingFavorites = true;
    notifyListeners();
    try {
      final ids = favoriteIds.toList();
      final List<Movie> fetched = [];
      for (final id in ids) {
        try {
          final res = await apiService.getMovieDetails(id);
          final list = _toMovieList(res);
          if (list.isNotEmpty) fetched.add(list.first);
        } catch (_) {
          // ignore single failures
        }
      }
      favoriteMovies = fetched;
    } catch (e) {
      favoriteMovies = [];
    } finally {
      loadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> fetchFavoriteMoviesForIds(List<int> ids) async {
    final List<Movie> out = [];
    for (final id in ids) {
      try {
        final res = await apiService.getMovieDetails(id);
        final list = _toMovieList(res);
        if (list.isNotEmpty) out.add(list.first);
      } catch (_) {}
    }
    favoriteMovies = out;
    notifyListeners();
  }

  Set<int> get favoriteIds {
    final raw = _favoritesBox.get('ids', defaultValue: <int>[]);
    return Set<int>.from((raw as List).cast<int>());
  }

  // Local guest favorites/watchlist (keeps UI functional when no user signed in)
  final Set<int> _localFavorites = <int>{};
  final Set<int> _localWatchlist = <int>{};

  bool isFavorite(int movieId) => _localFavorites.contains(movieId);
  bool isInWatchlist(int movieId) => _localWatchlist.contains(movieId);

  void toggleFavorite(int movieId) {
    if (_localFavorites.contains(movieId)) {
      _localFavorites.remove(movieId);
    } else {
      _localFavorites.add(movieId);
    }
    notifyListeners();
  }

  void toggleWatchlist(int movieId) {
    if (_localWatchlist.contains(movieId)) {
      _localWatchlist.remove(movieId);
    } else {
      _localWatchlist.add(movieId);
    }
    notifyListeners();
  }

  // Notes & rating storage:
  // Stored under key 'notes' as Map<String, Map<String, dynamic>>
  Map<String, Map<String, dynamic>> get _notesMap {
    final raw = _favoritesBox.get('notes', defaultValue: <String, Map<String, dynamic>>{});
    final casted = Map<String, dynamic>.from(raw as Map);
    // ensure nested maps are Map<String, dynamic>
    return casted.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  }

  String? getNote(int movieId) {
    final notes = _notesMap;
    return notes['$movieId']?['note'] as String?;
  }

  double? getRating(int movieId) {
    final notes = _notesMap;
    final r = notes['$movieId']?['rating'];
    if (r == null) return null;
    if (r is num) return r.toDouble();
    return double.tryParse(r.toString());
  }

  Future<void> setNote(int movieId, String? note) async {
    final notes = _notesMap;
    final key = '$movieId';
    final entry = notes[key] ?? <String, dynamic>{};
    if (note == null || note.trim().isEmpty) {
      entry.remove('note');
    } else {
      entry['note'] = note.trim();
    }
    if (entry.isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = entry;
    }
    await _favoritesBox.put('notes', notes);
    notifyListeners();
  }

  Future<void> setRating(int movieId, double? rating) async {
    final notes = _notesMap;
    final key = '$movieId';
    final entry = notes[key] ?? <String, dynamic>{};
    if (rating == null) {
      entry.remove('rating');
    } else {
      entry['rating'] = rating;
    }
    if (entry.isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = entry;
    }
    await _favoritesBox.put('notes', notes);
    notifyListeners();
  }

  /// Load movies for a given genre id (accepts int or String).
  Future<void> loadGenreMovies(dynamic genreIdParam) async {
    final int genreId = genreIdParam is int
        ? genreIdParam
        : (genreIdParam is String ? int.tryParse(genreIdParam) ?? 0 : 0);

    if (genreId == 0) {
      debugPrint('loadGenreMovies: invalid genreIdParam="$genreIdParam" -> genreId=0');
      _genreMovies = [];
      _genreLoading = false;
      notifyListeners();
      return;
    }

    _genreLoading = true;
    notifyListeners();

    try {
      final result = await apiService.discoverByGenre(genreId);
      debugPrint('loadGenreMovies: raw result type=${result.runtimeType} value=$result');

      // Delegate all normalization to _toMovieList (it is defensive)
      final normalized = _toMovieList(result);
      _genreMovies = normalized;
      debugPrint('loadGenreMovies: normalized.count=${_genreMovies.length}');
    } catch (e, st) {
      debugPrint('loadGenreMovies error: $e\n$st');
      _genreMovies = [];
    } finally {
      _genreLoading = false;
      notifyListeners();
    }
  }

  Movie? getMovieById(int id) {
    try { return favoriteMovies.firstWhere((m) => m.id == id); } catch (_) {}
    try { return movies.firstWhere((m) => m.id == id); } catch (_) {}
    try { return _genreMovies.firstWhere((m) => m.id == id); } catch (_) {}
    return null;
  }

  /// Fetch detailed Movie objects for arbitrary ids and return them.
  Future<List<Movie>> fetchMoviesForIds(List<int> ids) async {
    final List<Movie> out = [];
    for (final id in ids) {
      try {
        final res = await apiService.getMovieDetails(id);
        final list = _toMovieList(res);
        if (list.isNotEmpty) out.add(list.first);
      } catch (_) {
        // ignore individual failures
      }
    }
    return out;
  }
}