class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? releaseDate;
  final double voteAverage;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.releaseDate,
    required this.voteAverage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return Movie(
      id: parseInt(json['id']),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      posterPath: json['poster_path']?.toString(),
      releaseDate: json['release_date']?.toString(),
      voteAverage: parseDouble(json['vote_average'] ?? json['rating']),
    );
  }
}