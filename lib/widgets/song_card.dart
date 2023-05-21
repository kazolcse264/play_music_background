import 'dart:io';
import 'package:dio/dio.dart';
import 'package:play_music_background/services/playlist_repository.dart';
import 'package:provider/provider.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../notifiers/play_button_notifier.dart';
import '../page_manager.dart';
import '../play_song_screen.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import '../services/service_locator.dart';

class SongCard extends StatefulWidget {
  const SongCard({
    Key? key,
    required this.song,
    required this.index,
    required this.audioList,
  }) : super(key: key);

  final Map<String, dynamic> song;
  final int index;
  final List<dynamic> audioList;

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  final audioHandler = getIt<AudioHandler>();
  bool isDownloadingCompleted = false;
  late  List<CancelToken> cancelTokens;
@override
  void initState() {
  cancelTokens = List.generate(artUriList.length, (_) => CancelToken());
    super.initState();
  }
  @override
  void dispose() {
    audioHandler.customAction('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final isFileLocal = musicProvider.isFileInList(
        '${widget.audioList[widget.index]['title']}.mp3',
        musicProvider.mp3Files);
    print('Song Card');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
          tileColor:
              themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
          leading: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey.shade900
                  : Colors.white,
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
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(
            widget.song['album'],
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color:
                      themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
          ),
          trailing: (isFileLocal)
              ? InkWell(
                  onTap: () async {
                    widget.song["url"] = '/data/user/0/com.example.play_music_background/cache/${widget.song['title']}.mp3';

                    final newMediaItem = MediaItem(
                      id: widget.song["id"],
                      title: widget.song["title"],
                      album: widget.song["album"],
                      extras: {'url': widget.song['url']},
                      artUri: Uri.parse(widget.song['artUri']!),
                    );
                    musicProvider.addDecryptedMediaItems(newMediaItem);
                    print(musicProvider.decryptedMediaItems);
                    audioHandler.addQueueItem(newMediaItem);
                    final pageManager = getIt<PageManager>();
                    pageManager.play();
                    if (mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaySongScreen(song: widget.song),
                          ));
                    }
                  },
                  child: Container(
                          height: 50,
                          width: 50,
                          color: themeProvider.isDarkMode
                              ? Colors.grey.shade900
                              : Colors.white,
                          child: Icon(
                            Icons.play_circle,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.grey.shade900,
                            size: 35,
                          ),
                        ),
                )
              : InkWell(
                  onTap: isDownloadingCompleted
                      ? null
                      : () async {
                          setState(() {
                            isDownloadingCompleted = true;
                          });
                          Directory? d =
                              await musicProvider.getExternalVisibleDir;
                          await musicProvider.downloadAndCreate(
                              widget.song, d, audioHandler, widget.index, cancelTokens);
                        },
                  child: (isDownloadingCompleted == false)
                      ? Icon(
                          Icons.download,
                          size: 35,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.grey.shade900,
                        )
                      : Consumer<MusicProvider>(
                          builder: (context, provider, child) {
                            return SizedBox(
                              height: 50,
                              width: 50,
                              child: (provider.progressValueMap[
                                          '${widget.index}'] ==
                                      null)
                                  ? CircularProgressIndicator(
                                      strokeWidth: 5,
                                      backgroundColor: Colors.grey[300],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.blue),
                                    )
                                  : ('${(provider.progressValueMap['${widget.index}']! * 100).toStringAsFixed(0)}%' ==
                                          '100%')
                                      ? (provider.fileProcessResult ==
                                              'File Decrypted Successfully...')
                                          ? InkWell(
                                              onTap: () {
                                                final pageManager =
                                                    getIt<PageManager>();
                                                pageManager.play();
                                                if (mounted) {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PlaySongScreen(
                                                                song: widget
                                                                    .song),
                                                      ));
                                                }
                                              },
                                              child: Container(
                                                height: 50,
                                                width: 50,
                                                color: themeProvider.isDarkMode
                                                    ? Colors.grey.shade900
                                                    : Colors.white,
                                                child: Icon(
                                                  Icons.play_circle,
                                                  color: themeProvider
                                                          .isDarkMode
                                                      ? Colors.white
                                                      : Colors.grey.shade900,
                                                  size: 35,
                                                ),
                                              ),
                                            )
                                          : Wrap(
                                              children: const [
                                                Text(
                                                  'Encryption-Decryption Running...',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            )
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: provider.progressValueMap[
                                                  '${widget.index}'],
                                              strokeWidth: 5,
                                              backgroundColor: Colors.grey[300],
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(Colors.blue),
                                            ),
                                            /*Text(
                                              '${(provider.progressValueMap['${widget.index}']! * 100).toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),*/
                                            IconButton(
                                                onPressed: () async{
                                                  provider.cancelDownload(widget.index, cancelTokens);

                                                  setState(() {
                                                    isDownloadingCompleted = false;
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                ))
                                          ],
                                        ),
                            );
                          },
                        ),
                )),
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
