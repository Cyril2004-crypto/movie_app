import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/person_screen.dart';

class CastTile extends StatelessWidget {
  final Map<String, dynamic> cast;
  const CastTile({super.key, required this.cast});

  String? get _profilePath => cast['profile_path'] as String?;
  String get name => cast['name'] as String? ?? '';
  String get character => cast['character'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    final imageUrl = _profilePath != null ? 'https://image.tmdb.org/t/p/w200$_profilePath' : null;
    return GestureDetector(
      onTap: () {
        final id = cast['id'];
        if (id != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PersonScreen(personId: id as int)));
        }
      },
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                  : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.person)),
            ),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(character, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
