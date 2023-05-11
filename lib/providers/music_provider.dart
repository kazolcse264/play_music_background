import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:url_launcher/url_launcher.dart';

import '../page_manager.dart';
import '../services/service_locator.dart';

class MusicProvider extends ChangeNotifier {
  bool isGranted = true;
  double progressValue = 0.0;
  List<File> mp3Files = [];
  Map<String, double> progressValueMap = {

  };
  List<dynamic> audioList = [];

  readAudio(BuildContext context) async {
    await DefaultAssetBundle.of(context)
        .loadString('json/audio.json')
        .then((value) {
        audioList = json.decode(value);
    });
    notifyListeners();
  }
  Future<Directory?> get getExternalVisibleDir async {
    if (await Directory(
        '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder')
        .exists()) {
      final externalDir = Directory(
          '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder');
      return externalDir;
    } else {
      await Directory(
          '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder')
          .create(recursive: true);
      final externalDir = Directory(
          '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder');
      return externalDir;
    }
  }
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
  Future<void> downloadAndCreate(Map<String, dynamic> song, Directory? d, AudioHandler audioHandler,int index) async {
      if (await canLaunchUrl(Uri.parse(song['url']))) {
        if (kDebugMode) {
          print('Data downloading...');
        }
        var request = await HttpClient().getUrl(Uri.parse(song['url']));
        var response = await request.close();
        var length = response.contentLength;
        var bytes = <int>[];
        var received = 0;

        response.listen(
              (List<int> newBytes) {
            bytes.addAll(newBytes);
            received += newBytes.length;
            double progress = received / length;
              progressValue = progress;
            progressValueMap['$index'] = progressValue;
            notifyListeners();
            if (kDebugMode) {
              print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
            }
          },
          onDone: () async {
            var encResult = _encryptData(Uint8List.fromList(bytes));
            String p = await _writeData(encResult, '${d!.path}/${song['title']}.mp3.aes');
            if (kDebugMode) {
              print('File Encrypted successfully...$p');
            }
            var filePath = await _getNormalFile(
              d, '${song['title']}.mp3');
            song["url"] = filePath;
            final newMediaItem = MediaItem(
              id: song["id"],
              title: song["title"],
              album: song["album"],
              extras: {'url': song['url']},
              artUri: Uri.parse(song['artUri']!),
            );
            final pageManager = getIt<PageManager>();
            audioHandler.addQueueItem(newMediaItem);
            pageManager.play();
            if (kDebugMode) {
              print('********* ${audioHandler.queue.value}');
            }
          },
          onError: (e) {
            if (kDebugMode) {
              print('Error downloading file: $e');
            }
          },
          cancelOnError: true,
        );
        notifyListeners();
      } else {
        if (kDebugMode) {
          print('Can\'t launch url');
        }
      }

  }

  Future<String> _getNormalFile(Directory? d, String fileName,) async {
    try {
      Uint8List encData = await _readData('${d!.path}/$fileName.aes');
      var plainData = await _decryptData(encData);
      var tempFile = await _createTempFile(fileName);
      tempFile.writeAsBytesSync(plainData);

      if (kDebugMode) {
        print('TempFile : ${tempFile.path}');
      }
      if (kDebugMode) {
        print('File Decrypted Successfully... ');
      }
      return tempFile.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error : ${e.toString()}');
      }
      return '';
    }
  }

  Future<bool> checkIfFileExists(String filePath) async {
    File file = File(filePath);
    return await file.exists();
  }

  _encryptData(Uint8List plainString) {
    if (kDebugMode) {
      print('Encrypting File...');
    }
    final encrypted =
    MyEncrypt.myEncrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);

    return encrypted.bytes;
  }

  _writeData(encResult, String fileNamedWithPath) async {
    if (kDebugMode) {
      print('Writing data...');
    }
    File f = File(fileNamedWithPath);
    await f.writeAsBytes(encResult);
    return f.absolute.toString();
  }

  _readData(String fileNamedWithPath) async {
    if (kDebugMode) {
      print('Reading data...');
    }
    File f = File(fileNamedWithPath);
    return await f.readAsBytes();
  }

  _decryptData(Uint8List encData) {
    if (kDebugMode) {
      print('File decryption in progress...');
    }
    enc.Encrypted en = enc.Encrypted(encData);
    return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv);
  }

  Future<File> _createTempFile(String fileName) async {
    final directory = await getTemporaryDirectory();
    final tempFilePath = '${directory.path}/$fileName';
    return File(tempFilePath);
  }
}
class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('AshikujjamanAshikujjamanKazol299');
  static final myIv = enc.IV.fromUtf8('KazolAshikujjama');
  static final myEncrypter = enc.Encrypter(enc.AES(myKey));
}