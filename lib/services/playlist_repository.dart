import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class PlaylistRepository {
  Future<List<Map<String, String>>>fetchInitialPlaylist();
  Future<Map<String, String>> fetchAnotherSong();
}
/*class DemoPlaylist extends PlaylistRepository {
  @override
  Future<List<File>> fetchInitialPlaylist() async {
    return getAllTempFiles();
  }
  Future<List<File>> getAllTempFiles() async {
    final Directory tempDir = await getTemporaryDirectory();
    final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
    final List<File> mp3Files = files
        .where((file) =>
    file.path.endsWith('.mp3') &&
        FileSystemEntity.isFileSync(file.path))
        .map((file) => File(file.path))
        .toList();
    return mp3Files;
  }
  @override
  Future<Map<String, String>> fetchAnotherSong() async {
    return _nextSong();
  }

  var _songIndex = 0;
  static const _maxSongNumber = 16;// Number of 15 songs are created

  Map<String, String> _nextSong() {
    _songIndex = (_songIndex % _maxSongNumber) + 1;
    return {
      'id': _songIndex.toString().padLeft(3, '0'),
      'title': 'Song $_songIndex',
      'album': 'SoundHelix',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-$_songIndex.mp3',
      'artUri':artUriList[_songIndex],
    };
  }
}*/
class DemoPlaylist extends PlaylistRepository {
  @override
  Future<List<Map<String, String>>> fetchInitialPlaylist(
      {int length = 0}) async {
    return List.generate(length, (index) => _nextSong());
      [
      {
        "id" : "1",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-1",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/4289/4289408.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        //"url" : "/data/user/0/com.example.play_music_background/cache/SoundHelix-Song-1.mp3"
      },
      {
        "id" : "2",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-2",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/5683/5683980.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"
      },
      {
        "id" : "3",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-3",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/5151/5151458.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"
      },
      {
        "id" : "4",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-4",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/5167/5167332.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"
      },
      {
        "id" : "5",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-5",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/5151/5151497.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3"
      },
      {
        "id" : "6",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-6",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/9254/9254621.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3"
      },
      {
        "id" : "7",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-7",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/7187/7187731.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3"
      },
      {
        "id" : "8",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-8",
        "artUri"     : "https://png.pngtree.com/png-vector/20220926/ourmid/pngtree-music-notes-in-swirl-musical-design-elements-png-image_6217759.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3"
      },
      {
        "id" : "9",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-9",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/3994/3994180.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3"
      },
      {
        "id" : "10",
        "album" : "SoundHelix",
        "title"  : "SoundHelix-Song-10",
        "artUri"     : "https://cdn-icons-png.flaticon.com/512/557/557098.png",
        "url" : "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3"
      }
    ];
  }

  @override
  Future<Map<String, String>> fetchAnotherSong() async {
    return _nextSong();
  }

  var _songIndex = 0;
  static const _maxSongNumber = 16;// Number of 15 songs are created

  Map<String, String> _nextSong() {
    _songIndex = (_songIndex % _maxSongNumber) + 1;
    return {
      'id': _songIndex.toString().padLeft(3, '0'),
      'title': 'Song $_songIndex',
      'album': 'SoundHelix',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-$_songIndex.mp3',
      'artUri':artUriList[_songIndex],
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