import 'package:flutter/material.dart';
import 'movie_genre_movies_screen.dart'; // helper screen (included below or create separately)

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const List<Map<String, dynamic>> _genres = [
    {'id': 28, 'name': 'Action'},
    {'id': 12, 'name': 'Adventure'},
    {'id': 16, 'name': 'Animation'},
    {'id': 35, 'name': 'Comedy'},
    {'id': 18, 'name': 'Drama'},
    {'id': 27, 'name': 'Horror'},
    {'id': 10749, 'name': 'Romance'},
    {'id': 878, 'name': 'Science Fiction'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore / Genres')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _genres.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (c, i) {
          final g = _genres[i];
          return ListTile(
            title: Text(g['name']),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MovieGenreMoviesScreen(genreId: g['id'] as int, genreName: g['name'] as String)),
            ),
          );
        },
      ),
    );
  }
}