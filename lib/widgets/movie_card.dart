import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final String? heroTag;
  const MovieCard({super.key, required this.movie, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovieProvider>();
    final isFav = prov.isFavorite(movie.id);
    final imageUrl = movie.posterPath != null ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}' : null;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: imageUrl != null
                ? heroTag != null
                    ? Hero(
                        tag: heroTag!,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (c, s) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (c, s, e) => const Center(child: Icon(Icons.broken_image)),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (c, s) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (c, s, e) => const Center(child: Icon(Icons.broken_image)),
                      )
                : const Center(child: Icon(Icons.broken_image)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(movie.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => prov.toggleFavorite(movie.id),
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
              ),
              Expanded(child: Text(movie.releaseDate ?? '', style: const TextStyle(fontSize: 12))),
              Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(movie.voteAverage.toString())),
            ],
          )
        ],
      ),
    );
  }
}