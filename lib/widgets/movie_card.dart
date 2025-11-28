import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../providers/auth_provider.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final String? heroTag;
  final int movieId;
  final String title;

  const MovieCard({
    super.key,
    required this.movie,
    required this.heroTag,
    required this.movieId,
    required this.title,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovieProvider>();
    final auth = context.watch<AuthProvider>();

    // show favorite if either global or per-user store has it
    final bool isFav =
        (prov.isFavorite(widget.movieId) == true) || auth.currentFavorites.contains(widget.movieId);

    // watchlist visibility uses per-user list (will update after toggle because AuthProvider.notifyListeners is called)
    final bool inWatch = auth.currentWatchlist.contains(widget.movieId);

    final poster = widget.movie.posterPath != null
        ? 'https://image.tmdb.org/t/p/w500${widget.movie.posterPath}'
        : null;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: poster != null
                ? widget.heroTag != null
                    ? Hero(
                        tag: widget.heroTag!,
                        child: CachedNetworkImage(
                          imageUrl: poster,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (c, s) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (c, s, e) => const Center(child: Icon(Icons.broken_image)),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: poster,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (c, s) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (c, s, e) => const Center(child: Icon(Icons.broken_image)),
                      )
                : const Center(child: Icon(Icons.broken_image)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.movie.title,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  // update both stores so guest/global and signed-in/per-user are kept in sync
                  try {
                    prov.toggleFavorite(widget.movieId);
                  } catch (_) {}
                  try {
                    await context.read<AuthProvider>().toggleFavorite(widget.movieId);
                  } catch (_) {}
                },
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  // update both stores so views using either store reflect the change
                  try {
                    prov.toggleWatchlist(widget.movieId);
                  } catch (_) {}
                  try {
                    await context.read<AuthProvider>().toggleWatchlist(widget.movieId);
                  } catch (_) {}
                },
                icon: Icon(inWatch ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
        ],
      ),
    );
  }
}