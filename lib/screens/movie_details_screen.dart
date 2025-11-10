import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final det = await _api.getMovieDetails(widget.movieId);
      final vids = await _api.getMovieVideos(widget.movieId);
      setState(() { _details = det; _videos = vids; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _openTrailer() async {
    // find first youtube trailer
    final yt = _videos.firstWhere((v) => v['site'] == 'YouTube' && v['type'] == 'Trailer', orElse: () => {});
    final key = yt['key'];
    if (key == null) return;
    final url = Uri.parse('https://www.youtube.com/watch?v=$key');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open trailer')));
    }
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}