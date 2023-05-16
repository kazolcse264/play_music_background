import 'dart:io';
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
    required this.isFileLocal,
    required this.index,
  }) : super(key: key);

  final Map<String, dynamic> song;
  final bool isFileLocal;
  final int index;

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  final audioHandler = getIt<AudioHandler>();
  bool isDownloadingCompleted = false;
  bool isDecrypted = false;

  @override
  void dispose() {
    audioHandler.customAction('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        tileColor:
            themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
        leading: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color:
                themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
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
                color:
                    themeProvider.isDarkMode ? Colors.white : Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          widget.song['album'],
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
        ),
        trailing: Consumer<MusicProvider>(
          builder: (context, musicProvider, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                ),
                (widget.isFileLocal)
                    ? InkWell(
                        onTap: () async {
                          setState(() {
                            isDecrypted = true;
                          });
                          Directory? d =
                              await musicProvider.getExternalVisibleDir;
                          var filePath = await musicProvider.getNormalFile(
                              d, '${widget.song['title']}.mp3');
                          widget.song["url"] = filePath;

                          final newMediaItem = MediaItem(
                            id: widget.song["id"],
                            title: widget.song["title"],
                            album: widget.song["album"],
                            extras: {'url': widget.song['url']},
                            artUri: Uri.parse(widget.song['artUri']!),
                          );
                          musicProvider.addDecryptedMediaItems(newMediaItem);
                          final pageManager = getIt<PageManager>();
                          audioHandler.addQueueItem(newMediaItem);
                          pageManager.play();
                          setState(() {
                            isDecrypted = false;
                          });
                          if (mounted) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlaySongScreen(song: widget.song),
                                ));
                          }
                        },
                        child: (isDecrypted)
                            ? Wrap(
                              children: const [
                                Text(
                                    'Decryption Running...',
                                    style: TextStyle(
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            )
                            : Container(
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
                                    widget.song, d, audioHandler, widget.index);
                              },
                        child: (isDownloadingCompleted == false)
                            ? Icon(
                                Icons.download,
                                size: 35,
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.grey.shade900,
                              )
                            : SizedBox(
                                height: 50,
                                width: 50,
                                child: (musicProvider.progressValueMap[
                                            '${widget.index}'] ==
                                        null)
                                    ? CircularProgressIndicator(
                                        strokeWidth: 5,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.blue),
                                      )
                                    : ('${(musicProvider.progressValueMap['${widget.index}']! * 100).toStringAsFixed(0)}%' ==
                                            '100%')
                                        ? (musicProvider.fileProcessResult ==
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
                                                  color:
                                                      themeProvider.isDarkMode
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
                                                value: musicProvider
                                                        .progressValueMap[
                                                    '${widget.index}'],
                                                strokeWidth: 5,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                        Color>(Colors.blue),
                                              ),
                                              Text(
                                                musicProvider.progressValueMap[
                                                            '${widget.index}'] ==
                                                        null
                                                    ? ''
                                                    : '${(musicProvider.progressValueMap['${widget.index}']! * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                      ),
              ],
            );
          },
        ),
      ),
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
