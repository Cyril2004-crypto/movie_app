import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'movie_details_screen.dart';

class PersonScreen extends StatefulWidget {
  final int personId;
  const PersonScreen({super.key, required this.personId});

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _person;
  List<Map<String, dynamic>> _credits = [];
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
      final p = await _api.getPersonDetails(widget.personId);
      final c = await _api.getPersonMovieCredits(widget.personId);
      setState(() { _person = p; _credits = c; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text('Error: $_error')));

    final profile = _person?['profile_path'] != null ? 'https://image.tmdb.org/t/p/w300${_person!['profile_path']}' : null;
    return Scaffold(
      appBar: AppBar(title: Text(_person?['name'] ?? '')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile != null) Center(child: Image.network(profile, width: 180, height: 240, fit: BoxFit.cover)),
            const SizedBox(height: 12),
            Text(_person?['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if ((_person?['biography'] ?? '').toString().isNotEmpty) Text(_person?['biography'] ?? ''),
            const SizedBox(height: 16),
            const Text('Filmography', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: _credits.length,
                itemBuilder: (ctx, i) {
                  final c = _credits[i];
                  final poster = c['poster_path'] != null ? 'https://image.tmdb.org/t/p/w300${c['poster_path']}' : null;
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movieId: c['id'] as int, heroTag: 'poster_${c['id']}'))),
                    child: SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          poster != null ? Image.network(poster, width: 140, height: 200, fit: BoxFit.cover) : Container(width: 140, height: 200, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(c['title'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}