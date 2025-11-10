import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovieProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Popular Movies')),
      body: Builder(builder: (ctx) {
        if (prov.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (prov.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: ${prov.error}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: prov.fetchPopularMovies,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (prov.movies.isEmpty) {
          return const Center(child: Text('No movies found.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: prov.movies.length,
          itemBuilder: (context, index) {
            final movie = prov.movies[index];
            return MovieCard(movie: movie);
          },
        );
      }),
    );
  }
}
