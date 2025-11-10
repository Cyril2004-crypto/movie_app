import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/movie_provider.dart';
import '../models/movie.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().fetchFavoriteMovies();
    });
  }

  Future<void> _editNoteRating(BuildContext ctx, Movie movie) async {
    final prov = ctx.read<MovieProvider>();
    final noteController = TextEditingController(text: prov.getNote(movie.id) ?? '');
    double rating = prov.getRating(movie.id) ?? 0.0;

    await showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Edit for "${movie.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: noteController, maxLines: 3, decoration: const InputDecoration(labelText: 'Note')),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Rating:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(value: rating, onChanged: (v) => setState(() => rating = v), min: 0, max: 10, divisions: 20),
                ),
                Text(rating.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await prov.setNote(movie.id, noteController.text.trim().isEmpty ? null : noteController.text.trim());
              await prov.setRating(movie.id, rating > 0 ? rating : null);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovieProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: prov.loadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : prov.favoriteMovies.isEmpty
              ? const Center(child: Text('No favorites yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: prov.favoriteMovies.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final m = prov.favoriteMovies[i];
                    final note = prov.getNote(m.id);
                    final rating = prov.getRating(m.id);
                    final poster = m.posterPath != null ? 'https://image.tmdb.org/t/p/w200${m.posterPath}' : null;
                    return ListTile(
                      leading: poster != null
                          ? CachedNetworkImage(imageUrl: poster, width: 56, fit: BoxFit.cover)
                          : const SizedBox(width: 56, child: Icon(Icons.broken_image)),
                      title: Text(m.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (note != null) Text('Note: $note', maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (rating != null) Text('Rating: ${rating.toStringAsFixed(1)}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await _editNoteRating(ctx, m);
                          } else if (v == 'remove') {
                            prov.toggleFavorite(m.id);
                            await prov.fetchFavoriteMovies();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit note/rating')),
                          PopupMenuItem(value: 'remove', child: Text('Remove favorite')),
                        ],
                      ),
                      onTap: () {
                        // navigate to details if you have details screen route
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movieId: m.id, heroTag: 'poster_${m.id}')));
                      },
                    );
                  },
                ),
    );
  }
}