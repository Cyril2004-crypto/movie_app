import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/trailer_player.dart';
import '../widgets/cast_tile.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;
  final String heroTag;
  const MovieDetailsScreen({super.key, required this.movieId, required this.heroTag});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _details;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _credits = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final det = await _api.getMovieDetails(widget.movieId);
      final vids = await _api.getMovieVideos(widget.movieId);
      final creds = await _api.getMovieCredits(widget.movieId);
      final recs = await _api.getMovieRecommendations(widget.movieId);
      setState(() {
        _details = det;
        _videos = vids;
        _credits = creds;
        _recommendations = recs;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openTrailer() async {
    final yt = _videos.firstWhere((v) => v['site'] == 'YouTube' && v['type'] == 'Trailer', orElse: () => {});
    final key = yt['key'];
    if (key == null || (key as String).isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.width * 9 / 16 + 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ]),
              Expanded(child: TrailerPlayer(videoKey: key as String)),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetailsAnimated(int movieId) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, anim, sec) => FadeTransition(opacity: anim, child: MovieDetailsScreen(movieId: movieId, heroTag: 'poster_$movieId')),
      transitionsBuilder: (context, anim, sec, child) {
        final tween = Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut));
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim.drive(tween), child: child),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text('Error: $_error')));

    final title = _details?['title'] ?? '';
    final overview = _details?['overview'] ?? '';
    final posterPath = _details?['poster_path'];
    final posterUrl = posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null;
    final release = _details?['release_date'] ?? '';
    final vote = _details?['vote_average']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (posterUrl != null)
              Hero(tag: widget.heroTag, child: Image.network(posterUrl, width: double.infinity, height: 400, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [Text('Release: $release'), const SizedBox(width: 12), Text('Rating: $vote')]),
                  const SizedBox(height: 12),
                  Text(overview),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _videos.isNotEmpty ? _openTrailer : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch Trailer'),
                  ),
                  const SizedBox(height: 18),
                  if (_credits.isNotEmpty) ...[
                    const Text('Cast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _credits.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) => CastTile(cast: _credits[i]),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_recommendations.isNotEmpty) ...[
                    const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _recommendations.length,
                        itemBuilder: (ctx, i) {
                          final rec = _recommendations[i];
                          final poster = rec['poster_path'] != null ? 'https://image.tmdb.org/t/p/w300${rec['poster_path']}' : null;
                          return GestureDetector(
                            onTap: () => _openDetailsAnimated(rec['id'] as int),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(tag: 'poster_${rec['id']}', child: poster != null ? Image.network(poster, width: 140, height: 200, fit: BoxFit.cover) : Container(width: 140, height: 200, color: Colors.grey.shade300)),
                                const SizedBox(height: 8),
                                SizedBox(width: 140, child: Text(rec['title'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}