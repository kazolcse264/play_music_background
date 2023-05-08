import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../notifiers/play_button_notifier.dart';
import '../page_manager.dart';
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
    super.dispose();audioHandler.stop();
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
/*  void downloadAndGetNormalFile() async {
    if (_isGranted) {
      Directory? d = await getExternalVisibleDir;
      await _downloadAndCreate(widget.song['url'], d, '${widget.song['title']}.mp3', );
      var filePath = await _getNormalFile(d, '${widget.song['title']}.mp3', context);
      widget.song["url"] = filePath;

      final mediaItem = MediaItem(
        id: widget.song["id"],
        title: widget.song["title"],
        album: widget.song["album"],
        extras: {'url': widget.song['url']},
        artUri: Uri.parse(widget.song['artUri']!),
      );

      // Add media item to audio player queue
     // audioPlayer.add(mediaItem);

    } else {
      print('No Permission Granted');
      requestStoragePermission();
    }
  }*/
  void downloadAndGetNormalFile() async {
    if (_isGranted) {
      Directory? d = await getExternalVisibleDir;
      await _downloadAndCreate(
          widget.song['url'], d, '${widget.song['title']}.mp3');
     // This section is not called after _downloadAndCreate method is called
    /* if (_isDownloading == false) {
        var filePath = await _getNormalFile(
            d, '${widget.song['title']}.mp3', context);
        widget.song["url"] = filePath;
        *//*filePathListMap[0] = widget.mediaItem;
        print(filePathListMap);*//*
        final newMediaItem = MediaItem(
          id: widget.song["id"],
          title: widget.song["title"],
          album: widget.song["album"],
          extras: {'url': widget.song['url']},
          artUri: Uri.parse(widget.song['artUri']!),
        );
        // final audioSource = AudioSource.file(newMediaItem.extras!['url'] as String,tag: newMediaItem,);
        *//* final newQueue = List.of(queue.value)..insert(0, newMediaItem);
        queue.add(newQueue);*//*
        //audioPlayer.setAudioSource(audioSource);

      *//*  audioHandler.addQueueItem(newMediaItem);
        final pageManager = getIt<PageManager>();
        pageManager.play();*//*
        //_audioHandler.skipToQueueItem(widget.index);
        //await _audioHandler.stop();
        //audioPlayer.setFilePath(filePath);
        //audioPlayer.play();
      }*/
    } else {
      print('No Permission Granted');
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
    return InkWell(
        /* onTap: () async {
          if (mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaySongScreen(
                      mediaItem: widget.song, index: widget.index),
                ));
          }
          //Get.toNamed('/song', arguments: song);
        },*/
        child: Padding(
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
            //const PlayButton(),
            SizedBox(width: 10,),
            (isFileAlreadyDownloaded)
                ? InkWell(
              onTap: ()async{
                Directory? d = await getExternalVisibleDir;
                var filePath = await _getNormalFile(
                    d, '${widget.song['title']}.mp3', context);
                widget.song["url"] = filePath;
                /*filePathListMap[0] = widget.mediaItem;
        print(filePathListMap);*/
                final newMediaItem = MediaItem(
                  id: widget.song["id"],
                  title: widget.song["title"],
                  album: widget.song["album"],
                  extras: {'url': widget.song['url']},
                  artUri: Uri.parse(widget.song['artUri']!),
                );
                /*final audioPlayer = new AudioPlayer();
            audioPlayer.setFilePath(filePath);
            audioPlayer.play();*/
                audioHandler.addQueueItem(newMediaItem );
                //audioHandler.playFromMediaId(newMediaItem.id);
                print('********* ${audioHandler.queue.value}');

              },
              child: Icon(
                Icons.play_circle,
                color: Colors.deepPurple,
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
    )
        );
  }
 /* _downloadAndCreate(String audioUrl, Directory? d, String fileName) async {
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
        print('Data downloading...');
        try {
          String savePath = '${d.path}/$fileName.aes';
          var response = await Dio().download(audioUrl, savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                double progress = (received / total * 100);
                setState(() {
                  _progressValue = progress; // Update progress value
                });
                print('Download progress: ${progress.toStringAsFixed(0)}%');
              }
            },
          );
          var responseBodyBytes = await response.data.bytes;
          var encResult = _encryptData(responseBodyBytes);
          await _writeData(encResult, '${d.path}/$fileName.aes');
          print('File Encrypted successfully...');
        } catch (e) {
          print('Error downloading file: $e');
        }
      } else {
        print('Can\'t launch url');
      }
    }
  }*/

/*
  _downloadAndCreate(String audioUrl, Directory? d, String fileName) async {
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
        print('Data downloading...');
        var resp = await http.get(Uri.parse(audioUrl),);
        var encResult = _encryptData(resp.bodyBytes);
        String p = await _writeData(encResult, '${d.path}/$fileName.aes');
        print('File Encrypted successfully...$p');
      } else {
        print('Can\'t launch url');
      }
    }
  }*/
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
        print('Data downloading...');
        var request = await HttpClient().getUrl(Uri.parse(audioUrl));
        var response = await request.close();
        var length = response.contentLength;
        var bytes = <int>[];
        var received = 0;

        response.listen(
              (List<int> newBytes) {
            bytes.addAll(newBytes);
            received += newBytes.length;
            if (length != null) {
              double progress = received / length;
              setState(() {
                _progressValue = progress;
              });
              print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
            }
          },
          onDone: () async {
            var encResult = _encryptData(Uint8List.fromList(bytes));
            String p = await _writeData(encResult, '${d.path}/$fileName.aes');
            print('File Encrypted successfully...$p');
            var filePath = await _getNormalFile(
                d, '${widget.song['title']}.mp3', context);
            widget.song["url"] = filePath;
            /*filePathListMap[0] = widget.mediaItem;
        print(filePathListMap);*/
            final newMediaItem = MediaItem(
              id: widget.song["id"],
              title: widget.song["title"],
              album: widget.song["album"],
              extras: {'url': widget.song['url']},
              artUri: Uri.parse(widget.song['artUri']!),
            );
            // final audioSource = AudioSource.file(newMediaItem.extras!['url'] as String,tag: newMediaItem,);
            /* final newQueue = List.of(queue.value)..insert(0, newMediaItem);
        queue.add(newQueue);*/
            //audioPlayer.setAudioSource(audioSource);

           audioHandler.playMediaItem(newMediaItem);

          },
          onError: (e) {
            print('Error downloading file: $e');
          },
          cancelOnError: true,
        );
      } else {
        print('Can\'t launch url');
      }
    }
  }


  Future<String> _getNormalFile(Directory? d, String fileName, BuildContext context) async {
    try {
      Uint8List encData = await _readData('${d!.path}/$fileName.aes');
      var plainData = await _decryptData(encData);
      var tempFile = await _createTempFile(fileName);
      tempFile.writeAsBytesSync(plainData);
      /* final audioPlayer = AudioPlayer();
      audioPlayer.setFilePath(tempFile.path);*/
      //widget.audioPlayer.play();
      print('TempFile : ${tempFile.path}');
      print('File Decrypted Successfully... ');
      return tempFile.path;
    } catch (e) {
      print('Error : ${e.toString()}');
      return '';
    }
  }

  Future<bool> checkIfFileExists(String filePath) async {
    File file = File(filePath);
    return await file.exists();
  }

  _encryptData(Uint8List plainString) {
    print('Encrypting File...');
    final encrypted =
        MyEncrypt.myEncrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);

    return encrypted.bytes;
  }

  _writeData(encResult, String fileNamedWithPath) async {
    print('Writting data...');
    File f = File(fileNamedWithPath);
    await f.writeAsBytes(encResult);
    return f.absolute.toString();
  }

  _readData(String fileNamedWithPath) async {
    print('Reading data...');
    File f = File(fileNamedWithPath);
    return await f.readAsBytes();
  }

  _decryptData(Uint8List encData) {
    print('File decryption in progress...');
    enc.Encrypted en = enc.Encrypted(encData);
    return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv);
  }

  Future<File> _createTempFile(String fileName) async {
    final directory = await getTemporaryDirectory();
    //final tempFileName = fileName;
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