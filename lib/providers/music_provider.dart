import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:audio_service/audio_service.dart';

import 'package:dio/dio.dart';


import 'package:flutter/foundation.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';


enum DownloadAction { download, resume }

class MusicProvider extends ChangeNotifier {
  double _timeStretchFactor = 1.0;
  double get timeStretchFactor => _timeStretchFactor;

  void setTimeStretchFactor(double factor) {
    _timeStretchFactor = factor;
    notifyListeners();
  }
  //works good

  late SharedPreferences _preferences;
  static const String playbackPositionsKey = 'playbackPositions';
  Map<String, int> playbackPositions = {};

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final playbackPositionsJson = _preferences.getString(playbackPositionsKey);
    if (playbackPositionsJson != null) {
      final Map<String, dynamic> playbackPositionsMap = json.decode(playbackPositionsJson);
      playbackPositions = playbackPositionsMap.map((key, value) => MapEntry(key, value as int));
    }
  }

  int? getPosition(String id) {
    return playbackPositions[id];
  }

  void setPosition(String id, int position) {
    playbackPositions[id] = position;
    _savePlaybackPositions();
    print(playbackPositions);
    notifyListeners();
  }

  void _savePlaybackPositions() {
    final playbackPositionsJson = json.encode(playbackPositions);
    _preferences.setString(playbackPositionsKey, playbackPositionsJson);
  }

  List<File> mp3Files = [];
  List<MediaItem> allStoringMediaItems = [];

  bool _isGranted = true;

  bool get isGranted => _isGranted;

  set isGranted(bool value) {
    _isGranted = value;
    notifyListeners();
  }

  String fileLocalRouteStr = '';
  Dio dio = Dio();
  List<int> sizes = [];

  requestStoragePermission() async {
    if (!await Permission.storage.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (result.isGranted) {
        isGranted = true;
      } else {
        isGranted = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadTempFiles() async {
    final List<File> files = await getAllTempFiles();
    mp3Files = files;
    notifyListeners();
  }

  isFileInList(String fileName, List<File> mp3Files) {
    for (int i = 0; i < mp3Files.length; i++) {
      if (fileName ==
          mp3Files[i].path.substring(mp3Files[i].path.lastIndexOf('/') + 1)) {
        return true;
      }
    }
    return false;
  }
  Future<List<File>> getAllTempFiles() async {
    final Directory tempDir = Directory.systemTemp;
   /* String? basePath = (await getExternalStorageDirectory())?.path;
    String newPath = path.join(basePath!, 'Files');
    Directory directory = Directory(newPath);*/
    final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
    final List<File> mp3Files = files
        .where((file) =>
            file.path.endsWith('.mp3') &&
            FileSystemEntity.isFileSync(file.path))
        .map((file) => File(file.path))
        .toList();
    return mp3Files;
  }

  addForStoringMediaItems(MediaItem mediaItem) {
    allStoringMediaItems.add(mediaItem);
    notifyListeners();
  }

}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('AshikujjamanAshikujjamanKazol299');
  static final myIv = enc.IV.fromUtf8('KazolAshikujjama');
  static final myEncrypter = enc.Encrypter(enc.AES(myKey));
}
