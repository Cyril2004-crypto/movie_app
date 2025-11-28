import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ensure an int is passed
      context.read<MovieProvider>().loadGenreMovies(widget.genreId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovieProvider>();
    final movies = prov.genreMovies;
    final loading = prov.genreLoading;

    return Scaffold(
      appBar: AppBar(title: Text(widget.genreName)),
      body: loading && movies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : movies.isEmpty
              ? const Center(child: Text('No movies found for this genre'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.64,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailsScreen(
                            movieId: movie.id,
                            heroTag: 'poster_${movie.id}',
                          ),
                        ),
                      ),
                      child: MovieCard(
                        movie: movie,
                        heroTag: 'poster_${movie.id}',
                        movieId: movie.id,
                        title: movie.title,
                      ),
                    );
                  },
                ),
    );
  }
}