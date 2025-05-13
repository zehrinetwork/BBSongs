class Song {
  final String name;
  final String description;
  final String url;
  final String image;

  Song({required this.name, required this.description, required this.url, required this.image});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      name: json['name'],
      description: json['description'],
      url: json['url'],
      image: json['image'],
    );
  }
}