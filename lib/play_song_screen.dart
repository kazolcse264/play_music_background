import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:play_music_background/playlist_song_screen.dart';

import 'package:play_music_background/services/service_locator.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'page_manager.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PlaySongScreen extends StatefulWidget {
  final Map<String, dynamic> mediaItem;

  const PlaySongScreen({
    super.key,
    required this.mediaItem,
  });

  @override
  State<PlaySongScreen> createState() => _PlaySongScreenState();
}

class _PlaySongScreenState extends State<PlaySongScreen> {
  final _audioHandler = getIt<AudioHandler>();

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
    final queueLength = _audioHandler.queue.value.length;
    for (int i = 1; i <= queueLength; i++) {
      _audioHandler.removeQueueItemAt(queueLength - i);
    }
    getIt<PageManager>().init();
    downloadAndGetNormalFile();
  }

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
          d,
          '${widget.mediaItem['title']}.mp3',
        );
        widget.mediaItem["url"] = filePath;

        final newMediaItem = MediaItem(
          id: widget.mediaItem["id"],
          title: widget.mediaItem["title"],
          album: widget.mediaItem["album"],
          extras: {'url': widget.mediaItem['url']},
          artUri: Uri.parse(widget.mediaItem['artUri']!),
        );
        final pageManager = getIt<PageManager>();
        _audioHandler.removeQueueItemAt(0);
        _audioHandler.addQueueItem(newMediaItem);
        pageManager.play();
      }
    } else {
      if (kDebugMode) {
        print('No Permission Granted');
      }
      requestStoragePermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playing Screen'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            if (kDebugMode) {
              print('Back to previous screen');
            }
          },
        ),
      ),
      body: (_isDownloading)
          ? Center(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(
                  height: 10,
                ),
                Text('Data Downloading ...'),
              ],
            ))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: const [
                  CurrentSongTitle(),
                  Playlist(),
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
        if (kDebugMode) {
          print('Data downloading...');
        }
        var resp = await http.get(Uri.parse(audioUrl));
        var encResult = _encryptData(resp.bodyBytes);
        String p = await _writeData(encResult, '${d.path}/$fileName.aes');
        if (kDebugMode) {
          print('File Encrypted successfully...$p');
        }
      } else {
        if (kDebugMode) {
          print('Can\'t launch url');
        }
      }
    }
  }

  Future<String> _getNormalFile(Directory? d, String fileName) async {
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
      print('Writting data...');
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
                    pageManager.skipToQueueItem(index, playlistTitles[index]);
                  },
                  child: ListTile(
                    //leading: CurrentSongImage(),
                    title: Text(
                      playlistTitles[index],
                    ),
                    //trailing: AddRemoveSongButtons(),
                  ),
                ),
                const SizedBox(
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
          //PreviousSongButton(),
          RewindSongButton(),
          PlayButton(),
          FastForwardSongButton(),
          //NextSongButton(),
          //ShuffleButton(),
          PlayListButton(),
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

class RewindSongButton extends StatelessWidget {
  const RewindSongButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.rewindSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: const Icon(Icons.fast_rewind),
          onPressed: pageManager.rewind,
        );
      },
    );
  }
}


class FastForwardSongButton extends StatelessWidget {
  const FastForwardSongButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.fastForwardSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: const Icon(Icons.fast_forward),
          onPressed: pageManager.fastForward,
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
class PlayListButton extends StatelessWidget {
  const PlayListButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return IconButton(
      icon:  const Icon(Icons.playlist_play),
      onPressed: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PlaylistSongScreen(),
          ),
        );
      },
    );
  }
}
