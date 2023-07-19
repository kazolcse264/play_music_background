class SongModelWithPlaybackPosition {
  final String id;
  late final int lastPlaybackPosition;

  SongModelWithPlaybackPosition({required this.id, required this.lastPlaybackPosition});

  factory SongModelWithPlaybackPosition.fromJson(Map<String, dynamic> json) {
    return SongModelWithPlaybackPosition(
      id: json['title'],
      lastPlaybackPosition: json['lastPlaybackPosition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': id,
      'lastPlaybackPosition': lastPlaybackPosition,
    };
  }
}
