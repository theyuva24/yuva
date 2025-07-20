class Hub {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int? popularityScore;

  Hub({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.popularityScore,
  });
}
