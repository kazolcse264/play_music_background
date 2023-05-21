abstract class PlaylistRepository {
  Future<List<Map<String, String>>> fetchInitialPlaylist();

  Future<Map<String, String>> fetchAnotherSong();
}

class DemoPlaylist extends PlaylistRepository {
  @override
  Future<List<Map<String, String>>> fetchInitialPlaylist(
      {int length = 0}) async {
    return List.generate(length, (index) => _nextSong());
  }

  @override
  Future<Map<String, String>> fetchAnotherSong() async {
    return _nextSong();
  }

  var _songIndex = 0;
  static const _maxSongNumber = 16; // Number of 15 songs are created

  Map<String, String> _nextSong() {
    _songIndex = (_songIndex % _maxSongNumber) + 1;
    return {
      'id': _songIndex.toString().padLeft(3, '0'),
      'title': 'Song $_songIndex',
      'album': 'SoundHelix',
      'url':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-$_songIndex.mp3',
      'artUri': artUriList[_songIndex],
    //--------------/data/user/0/com.example.play_music_background/cache/SoundHelix-Song-2.mp3
    };
  }
}

//artUriList length must be equal to _maxSongNumber length
List<String> artUriList = [
  'https://cdn-icons-png.flaticon.com/512/4289/4289408.png',
  'https://cdn-icons-png.flaticon.com/512/5683/5683980.png',
  'https://cdn-icons-png.flaticon.com/512/5151/5151458.png',
  'https://cdn-icons-png.flaticon.com/512/5167/5167332.png',
  'https://cdn-icons-png.flaticon.com/512/5151/5151497.png',
  'https://cdn-icons-png.flaticon.com/512/9254/9254621.png',
  'https://cdn-icons-png.flaticon.com/512/7187/7187731.png',
  'https://png.pngtree.com/png-vector/20220926/ourmid/pngtree-music-notes-in-swirl-musical-design-elements-png-image_6217759.png',
  'https://cdn-icons-png.flaticon.com/512/3994/3994180.png',
  'https://cdn-icons-png.flaticon.com/512/557/557098.png',
  'https://cdn-icons-png.flaticon.com/512/4289/4289408.png',
  'https://cdn-icons-png.flaticon.com/512/5683/5683980.png',
  'https://cdn-icons-png.flaticon.com/512/5151/5151458.png',
  'https://cdn-icons-png.flaticon.com/512/5167/5167332.png',
  'https://cdn-icons-png.flaticon.com/512/5151/5151497.png',
  'https://cdn-icons-png.flaticon.com/512/9254/9254621.png',
];
