import 'package:flutter/material.dart';

class CastTile extends StatelessWidget {
  final Map<String, dynamic> cast;
  const CastTile({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    final profilePath = cast['profile_path'] as String?;
    final name = (cast['name'] ?? '') as String;
    final character = (cast['character'] ?? '') as String;
    final imgUrl = profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : null;

    return SizedBox(
      width: 90, // fixed width so text truncation is consistent
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imgUrl != null
                ? Image.network(imgUrl, width: 72, height: 72, fit: BoxFit.cover)
                : Container(width: 72, height: 72, color: Colors.grey[200]),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // prevents overflow by truncating
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            character,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
