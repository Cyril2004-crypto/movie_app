import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_card.dart';
import 'movie_details_screen.dart';

class MovieGenreMoviesScreen extends StatefulWidget {
  final int genreId;
  final String genreName;
  const MovieGenreMoviesScreen({super.key, required this.genreId, required this.genreName});

  @override
  State<MovieGenreMoviesScreen> createState() => _MovieGenreMoviesScreenState();
}

class _MovieGenreMoviesScreenState extends State<MovieGenreMoviesScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scroll = ScrollController();
  List<Movie> _movies = [];                // <-- changed to Movie
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 && !_loadingMore && _hasMore) {
        _loadPage(_page + 1);
      }
    });
  }

  Future<void> _loadPage(int page, {bool refresh = false}) async {
    setState(() {
      _error = null;
      if (page == 1) _loading = true; else _loadingMore = true;
    });
    try {
      final results = await _api.discoverByGenre(widget.genreId, page: page);

      // Ensure we have a List<Movie> (API may return List<dynamic>/Map)
      final List<Movie> list;
      if (results is List<Movie>) {
        list = results;
      } else if (results is List) {
        list = results.map((e) {
          if (e is Movie) return e;
          return Movie.fromJson(Map<String, dynamic>.from(e as Map));
        }).toList();
      } else {
        list = <Movie>[];
      }

      setState(() {
        if (page == 1) _movies = list; else _movies.addAll(list);
        _page = page;
        _hasMore = list.isNotEmpty;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _refresh() async => await _loadPage(1);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.genreName)),
      body: Column(
        children: [
          if (_loading && _movies.isEmpty) const Expanded(child: Center(child: CircularProgressIndicator())) else
          if (_error != null && _movies.isEmpty)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => _loadPage(1), child: const Text('Retry')),
                ]),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: GridView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _movies.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (c, i) {
                    if (i >= _movies.length) return const Center(child: CircularProgressIndicator());
                    final movie = _movies[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movieId: movie.id, heroTag: 'poster_${movie.id}'))),
                      child: MovieCard(movie: movie, heroTag: 'poster_${movie.id}'),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}