import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = false;
  List<Movie> _movies = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final auth = context.read<AuthProvider>();
    final movieProv = context.read<MovieProvider>();
    final ids = auth.currentFavorites;
    if (ids.isEmpty) {
      setState(() { _movies = []; _loading = false; });
      return;
    }

    setState(() => _loading = true);

    // try resolve from provider caches first
    final resolved = ids.map((id) => movieProv.getMovieById(id)).whereType<Movie>().toList();
    final missing = ids.where((id) => resolved.every((m) => m.id != id)).toList();
    if (missing.isNotEmpty) {
      final fetched = await movieProv.fetchMoviesForIds(missing);
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
    final ids = auth.currentFavorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
            else Navigator.popUntil(context, (r) => r.isFirst);
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ids.isEmpty && _movies.isEmpty
              ? const Center(child: Text('No favorites'))
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
                          ? Image.network('https://image.tmdb.org/t/p/w92${movie.posterPath}', width: 48, fit: BoxFit.cover)
                          : const SizedBox(width: 48),
                      title: Text(movie.title),
                      subtitle: Text(movie.releaseDate ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          await context.read<AuthProvider>().toggleFavorite(movie.id);
                          await _loadFavorites();
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