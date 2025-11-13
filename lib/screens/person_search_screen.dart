import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'person_screen.dart';

class PersonSearchScreen extends StatefulWidget {
  const PersonSearchScreen({super.key});
  @override
  State<PersonSearchScreen> createState() => _PersonSearchScreenState();
}

class _PersonSearchScreenState extends State<PersonSearchScreen> {
  final ApiService _api = ApiService();
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return setState(() => _results = []);
    setState(() { _loading = true; });
    try {
      final res = await _api.searchPeople(q.trim());
      setState(() { _results = res; });
    } catch (_) {
      setState(() { _results = []; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search People')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search actor or person'),
              onSubmitted: _search,
              onChanged: (v) { if (v.length >= 3) _search(v); },
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final p = _results[i];
                        final profile = p['profile_path'] != null ? 'https://image.tmdb.org/t/p/w200${p['profile_path']}' : null;
                        return ListTile(
                          leading: profile != null ? Image.network(profile, width: 56, fit: BoxFit.cover) : const Icon(Icons.person),
                          title: Text(p['name'] ?? ''),
                          subtitle: Text((p['known_for_department'] ?? '').toString()),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonScreen(personId: p['id'] as int))),
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