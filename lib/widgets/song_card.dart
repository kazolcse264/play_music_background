
import 'dart:io';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../notifiers/play_button_notifier.dart';
import '../page_manager.dart';
import '../play_song_screen.dart';
import '../services/service_locator.dart';

class SongCard extends StatefulWidget {
  const SongCard({
    Key? key,
    required this.song,
    required this.index,
  }) : super(key: key);

  final Map<String, dynamic> song;
  final int index;

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
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

  bool _isGranted = true;
  bool _isDownloading = true;
  List<File> mp3Files = [];
  double _progressValue = 0.0;
  late bool isFileAlreadyDownloaded ;
  final audioHandler = getIt<AudioHandler>();
  requestStoragePermission() async {
    if (!await Permission.storage.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (result.isGranted) {
        setState(() {
          _isGranted = true;
        });
      } else {
        _isGranted = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
  }
  @override
  void dispose() {
    super.dispose();
    audioHandler.stop();
    audioHandler.customAction('dispose');
  }

  Future<void> _loadTempFiles() async {
    final List<File> files = await getAllTempFiles();
    setState(() {
      mp3Files = files;
    });
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

  void downloadAndGetNormalFile() async {
    if (_isGranted) {
      Directory? d = await getExternalVisibleDir;
      await _downloadAndCreate(
          widget.song['url'], d, '${widget.song['title']}.mp3');
      // This section is not called after _downloadAndCreate method is called

    } else {
      if (kDebugMode) {
        print('No Permission Granted');
      }
      requestStoragePermission();
    }
  }

  bool isFileInList(String fileName, List<File> mp3Files) {
    for (int i = 0; i < mp3Files.length; i++) {
      if (fileName ==
          mp3Files[i].path.substring(mp3Files[i].path.lastIndexOf('/') + 1)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _loadTempFiles();
    isFileAlreadyDownloaded = isFileInList('${widget.song['title']}.mp3', mp3Files);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        tileColor: Colors.white,
        leading: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.0),
            image: DecorationImage(
              image: NetworkImage(
                widget.song['artUri'],
              ),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        title: Text(
          widget.song['title'],
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          widget.song['album'],
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing:
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 10,),
            (isFileAlreadyDownloaded)
                ? InkWell(
              onTap: ()async{
                final newMediaItem = MediaItem(
                  id: widget.song["id"],
                  title: widget.song["title"],
                  album: widget.song["album"],
                  extras: {'url': widget.song['url']},
                  artUri: Uri.parse(widget.song['artUri']!),
                );

                final pageManager = getIt<PageManager>();
                audioHandler.addQueueItem(newMediaItem);
                pageManager.play();
                if (mounted) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  PlaySongScreen(song: widget.song),
                      ));
                }

              },
              child: Container(
                height: 50,
                width: 50,
                color: Colors.white,
                child: const Icon(
                  Icons.play_circle,
                  color: Colors.deepPurple,
                  size: 35,
                ),
              ),
            )
                : InkWell(
              onTap: (){
                setState(() {
                  _isDownloading = false;
                });
                downloadAndGetNormalFile();
              },
              child: (_isDownloading == true ) ? const Icon(
                Icons.download,
                size: 35,
                color: Colors.deepPurple,
              ) :  Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progressValue,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  Text(
                    '${(_progressValue * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
              ,
            ),
          ],
        ),

      ),
    );
  }

  Future<void> _downloadAndCreate(String audioUrl, Directory? d, String fileName) async {
    bool isDownloaded = await checkIfFileExists('${d!.path}/$fileName.aes');
    if (isDownloaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File already downloaded!!!'),
          duration: Duration(
            seconds: 1,
          ),
        ));
      }
    } else {
      if (await canLaunchUrl(Uri.parse(audioUrl))) {
        if (kDebugMode) {
          print('Data downloading...');
        }
        var request = await HttpClient().getUrl(Uri.parse(audioUrl));
        var response = await request.close();
        var length = response.contentLength;
        var bytes = <int>[];
        var received = 0;

        response.listen(
              (List<int> newBytes) {
            bytes.addAll(newBytes);
            received += newBytes.length;
            double progress = received / length;
            setState(() {
              _progressValue = progress;
            });
            if (kDebugMode) {
              print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
            }
          },
          onDone: () async {
            var encResult = _encryptData(Uint8List.fromList(bytes));
            String p = await _writeData(encResult, '${d.path}/$fileName.aes');
            if (kDebugMode) {
              print('File Encrypted successfully...$p');
            }
            var filePath = await _getNormalFile(
                d, '${widget.song['title']}.mp3',);
            widget.song["url"] = filePath;

            final newMediaItem = MediaItem(
              id: widget.song["id"],
              title: widget.song["title"],
              album: widget.song["album"],
              extras: {'url': widget.song['url']},
              artUri: Uri.parse(widget.song['artUri']!),
            );
            final pageManager = getIt<PageManager>();
            audioHandler.addQueueItem(newMediaItem);
            pageManager.play();
            if (kDebugMode) {
              print('********* ${audioHandler.queue.value}');
            }
            if (mounted) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  PlaySongScreen(song: widget.song,),
                  ));
            }
          },
          onError: (e) {
            if (kDebugMode) {
              print('Error downloading file: $e');
            }
          },
          cancelOnError: true,
        );
      } else {
        if (kDebugMode) {
          print('Can\'t launch url');
        }
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
class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: const EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: const CircularProgressIndicator(),
            );
          case ButtonState.paused:
            return IconButton(
              icon: const Icon(Icons.play_arrow),
              iconSize: 32.0,
              onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: const Icon(Icons.pause),
              iconSize: 32.0,
              onPressed: pageManager.pause,
            );
        }
      },
    );
  }
}