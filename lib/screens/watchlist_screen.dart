import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
import '../models/movie.dart';
import 'movie_details_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _loading = false;
  List<Movie> _movies = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final auth = context.read<AuthProvider>();
    final movieProv = context.read<MovieProvider>();
    final ids = auth.currentWatchlist;
    if (ids.isEmpty) {
      setState(() {
        _movies = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    // try resolve from provider caches first
    final resolved = ids.map((id) => movieProv.getMovieById(id)).whereType<Movie>().toList();

    // if some ids are missing, fetch details
    final missingIds = ids.where((id) => resolved.every((m) => m.id != id)).toList();
    if (missingIds.isNotEmpty) {
      final fetched = await movieProv.fetchMoviesForIds(missingIds);
      resolved.addAll(fetched);
    }

    setState(() {
      _movies = resolved;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ids = auth.currentWatchlist;

    // Always show AppBar so user can navigate back (even when empty)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // prefer simple pop, but fall back to popping until first route (home)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // ensure we return to the app root (home) regardless of stack shape
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (ids.isEmpty && _movies.isEmpty)
              ? const Center(child: Text('No movies in your watchlist'))
              : ListView.separated(
                  itemCount: _movies.isNotEmpty ? _movies.length : ids.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final movie = _movies.isNotEmpty ? _movies[index] : null;
                    if (movie == null) {
                      final id = ids[index];
                      return ListTile(title: Text('Movie #$id'));
                    }
                    return ListTile(
                      leading: movie.posterPath != null
                          ? Image.network('https://image.tmdb.org/t/p/w92${movie.posterPath}',
                              width: 48, fit: BoxFit.cover)
                          : const SizedBox(width: 48),
                      title: Text(movie.title),
                      subtitle: Text(movie.releaseDate ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () async {
                          await context.read<AuthProvider>().toggleWatchlist(movie.id);
                          await _loadMovies();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovieDetailsScreen(movieId: movie.id, heroTag: 'poster_${movie.id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}