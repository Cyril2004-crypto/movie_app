import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final String? heroTag;
  const MovieCard({super.key, required this.movie, required this.heroTag});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  late final Box _watchBox;
  bool _inWatchlist = false;

  @override
  void initState() {
    super.initState();
    _watchBox = Hive.box('watchlist');
    final ids = (_watchBox.get('ids', defaultValue: <int>[]) as List).cast<int>();
    _inWatchlist = ids.contains(widget.movie.id);
  }

  void _toggleWatchlist() {
    final ids = Set<int>.from((_watchBox.get('ids', defaultValue: <int>[]) as List).cast<int>());
    if (ids.contains(widget.movie.id)) ids.remove(widget.movie.id); else ids.add(widget.movie.id);
    _watchBox.put('ids', ids.toList());
    setState(() { _inWatchlist = ids.contains(widget.movie.id); });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovieProvider>();
    final isFav = prov.isFavorite(widget.movie.id);
    final imageUrl = widget.movie.posterPath != null ? 'https://image.tmdb.org/t/p/w500${widget.movie.posterPath}' : null;

    return Stack(
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: imageUrl != null
                    ? widget.heroTag != null
                        ? Hero(
                            tag: widget.heroTag!,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
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
                            imageUrl: imageUrl,
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
                child: Text(widget.movie.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => prov.toggleFavorite(widget.movie.id),
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                  ),
                  Expanded(child: Text(widget.movie.releaseDate ?? '', style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(widget.movie.voteAverage.toString())),
                ],
              )
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: _toggleWatchlist,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(20)),
              child: Icon(_inWatchlist ? Icons.bookmark : Icons.bookmark_outline, size: 20, color: _inWatchlist ? Colors.deepPurple : Colors.black54),
            ),
          ),
        ),
      ],
    );
  }
}