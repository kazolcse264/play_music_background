import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:play_music_background/models/media_item_model.dart';
import 'package:play_music_background/services/audio_handler.dart';

import 'package:play_music_background/services/service_locator.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'page_manager.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PlaySongScreen extends StatefulWidget {
  final Map<String, dynamic> mediaItem;
  final int index;
  const PlaySongScreen({super.key, required this.mediaItem,required this.index});

  @override
  State<PlaySongScreen> createState() => _PlaySongScreenState();
}

class _PlaySongScreenState extends State<PlaySongScreen> {
  final _audioHandler = getIt<AudioHandler>();
 // final audioPlayer = AudioPlayer();
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
    getIt<PageManager>().init();
    //audioServiceInitialization();
    downloadAndGetNormalFile();
    //getAllTempFiles();

  }
/*  Future<List<File>> getAllTempFiles() async {
    final Directory tempDir = await getTemporaryDirectory();
    final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
    final List<File> mp3Files = files
        .where((file) =>
    file.path.endsWith('.mp3') &&
        FileSystemEntity.isFileSync(file.path))
        .map((file) => File(file.path))
        .toList();
    return mp3Files;
  }*/

  void downloadAndGetNormalFile() async {
    if (_isGranted) {
      Directory? d = await getExternalVisibleDir;
      await _downloadAndCreate(
          widget.mediaItem['url'], d, '${widget.mediaItem['title']}.mp3');
      setState(() {
        _isDownloading = false;
      });
      if (_isDownloading == false) {
        var filePath = await _getNormalFile(
            d, '${widget.mediaItem['title']}.mp3', context);
        widget.mediaItem["url"] = filePath;
        /*filePathListMap[0] = widget.mediaItem;
        print(filePathListMap);*/
        final newMediaItem = MediaItem(
          id: widget.mediaItem["id"],
          title: widget.mediaItem["title"],
          album: widget.mediaItem["album"],
          extras: {'url': widget.mediaItem['url']},
          artUri: Uri.parse(widget.mediaItem['artUri']!),
        );


        _audioHandler.removeQueueItemAt(0);
        _audioHandler.addQueueItem(newMediaItem);
        final pageManager = getIt<PageManager>();
        pageManager.play();

      }
    } else {
      print('No Permission Granted');
      requestStoragePermission();
    }
  }

 /* @override
  void dispose() {
    getIt<PageManager>().dispose();
    getIt<PageManager>().stop();
    super.dispose();
  }*/

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playing Screen'),
        automaticallyImplyLeading: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back),onPressed: (){
          //_audioHandler.stop();
          //_audioHandler.customAction('dispose');
          //print('hgfffffffffffh ${_audioHandler.stop().toString()}');
          //audioPlayer.stop();
          //audioPlayer.dispose();
         // pageManager.dispose();
          //pageManager.stop();
          Navigator.pop(context);
          print('Back to previous screen');
        },),
      ),
      body: (_isDownloading)
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 10,),
                Text('Data Downloading ...'),
              ],
            ))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: const [
                  CurrentSongTitle(),
                  Playlist(),
                  //AddRemoveSongButtons(),
                  AudioProgressBar(),
                  AudioControlButtons(),
                ],
              ),
            ),
    );
  }

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
        var resp = await http.get(Uri.parse(audioUrl));
        var encResult = _encryptData(resp.bodyBytes);
        String p = await _writeData(encResult, '${d.path}/$fileName.aes');
        print('File Encrypted successfully...$p');
      } else {
        print('Can\'t launch url');
      }
    }
  }

  Future<String> _getNormalFile(
      Directory? d, String fileName, BuildContext context) async {
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

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<String>(
      valueListenable: pageManager.currentSongTitleNotifier,
      builder: (_, title, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Text(title, style: const TextStyle(fontSize: 40)),
        );
      },
    );
  }
}

/*class Playlist extends StatelessWidget {
  const Playlist({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return Expanded(
      child: ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: pageManager.fileListNotifier,
        builder: (context, playlistTitles, _) {
          print(playlistTitles.length);
          return ListView.builder(
            itemCount: playlistTitles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text(playlistTitles[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}*/
/*class Playlist extends StatelessWidget {
  const Playlist({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return Expanded(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: pageManager.playlistNotifier,
        builder: (context, playlistTitles, _) {
          return ListView.builder(
            itemCount: playlistTitles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text(playlistTitles[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}*/
class Playlist extends StatelessWidget {
  const Playlist({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<List<String>>(
      valueListenable: pageManager.playlistNotifier,
      builder: (context, playlistTitles, _) {
        return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: playlistTitles.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    /*var current_id = pageManager.getCurrentSongId();
                    var current_playlist = pageManager.getCurrentPlaylist();*/
                    pageManager.skipToQueueItem(index, playlistTitles[index]);
                    // pageManager.updateMyQueueItem(
                    //   current_playlist[int.parse(current_id)],
                    //   int.parse(current_id),
                    // );
                  },
                  child: ListTile(
                    //leading: CurrentSongImage(),
                    title: Text(
                      '${playlistTitles[index]}',
                    ),
                    //trailing: AddRemoveSongButtons(),
                  ),
                ),
                SizedBox(
                  height: 5,
                )
              ],
            );
          },
        );
      },
    );
  }
}
/*class AddRemoveSongButtons extends StatelessWidget {
  const AddRemoveSongButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'Add',
            onPressed: pageManager.add,
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: 'Remove',
            onPressed: pageManager.remove,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}*/

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: pageManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: pageManager.seek,
        );
      },
    );
  }
}

class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          RepeatButton(),
          PreviousSongButton(),
          PlayButton(),
          NextSongButton(),
          ShuffleButton(),
        ],
      ),
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<RepeatState>(
      valueListenable: pageManager.repeatButtonNotifier,
      builder: (context, value, child) {
        Icon icon;
        switch (value) {
          case RepeatState.off:
            icon = const Icon(Icons.repeat, color: Colors.grey);
            break;
          case RepeatState.repeatSong:
            icon = const Icon(Icons.repeat_one);
            break;
          case RepeatState.repeatPlaylist:
            icon = const Icon(Icons.repeat);
            break;
        }
        return IconButton(
          icon: icon,
          onPressed: pageManager.repeat,
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isFirstSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: (isFirst) ? null : pageManager.previous,
        );
      },
    );
  }
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

class NextSongButton extends StatelessWidget {
  const NextSongButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isLastSongNotifier,
      builder: (_, isLast, __) {
        return IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: (isLast) ? null : pageManager.next,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isShuffleModeEnabledNotifier,
      builder: (context, isEnabled, child) {
        return IconButton(
          icon: (isEnabled)
              ? const Icon(Icons.shuffle)
              : const Icon(Icons.shuffle, color: Colors.grey),
          onPressed: pageManager.shuffle,
        );
      },
    );
  }
}
