import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_service.dart';
import 'movie_details_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final ApiService _api = ApiService();
  final Box _box = Hive.box('watchlist');
  List<Map<String, dynamic>> _movies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ids = (_box.get('ids', defaultValue: <int>[]) as List).cast<int>();
    final List<Map<String, dynamic>> out = [];
    for (final id in ids) {
      try {
        final map = await _api.getMovieDetails(id);
        out.add(map);
      } catch (_) {}
    }
    setState(() {
      _movies = out;
      _loading = false;
    });
  }

  void _toggle(int id) {
    final ids = Set<int>.from((_box.get('ids', defaultValue: <int>[]) as List).cast<int>());
    if (ids.contains(id)) ids.remove(id); else ids.add(id);
    _box.put('ids', ids.toList());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _movies.isEmpty
              ? const Center(child: Text('No items in your watchlist'))
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _movies.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final m = _movies[i];
                    final poster = m['poster_path'] != null ? 'https://image.tmdb.org/t/p/w200${m['poster_path']}' : null;
                    return ListTile(
                      leading: poster != null ? CachedNetworkImage(imageUrl: poster, width: 56, fit: BoxFit.cover) : const Icon(Icons.broken_image),
                      title: Text(m['title'] ?? ''),
                      subtitle: Text(m['release_date'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _toggle(m['id'] as int),
                        tooltip: 'Remove from watchlist',
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movieId: m['id'] as int, heroTag: 'poster_${m['id']}'))).then((_) => _load()),
                    );
                  },
                ),
    );
  }
}