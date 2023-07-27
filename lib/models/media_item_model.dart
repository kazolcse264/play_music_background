class SongModel {
  late final int? id;
  final String album;
  final String title;
  final String artUri;
  final String url;

  SongModel({
    this.id,
    required this.album,
    required this.title,
    required this.artUri,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'album': album,
      'title': title,
      'artUri': artUri,
      'url': url,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as int?,
      album: map['album'] as String? ?? '',
      title: map['title'] as String? ?? '',
      artUri: map['artUri'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'SongModel{id: $id, album: $album, title: $title, artUri: $artUri, url: $url}';
  }
}


