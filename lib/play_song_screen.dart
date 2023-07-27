import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/services/service_locator.dart';
import 'package:play_music_background/utils/helper_functions.dart';
import 'package:provider/provider.dart';

import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'page_manager.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';


class PlaySongScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  final bool justPlay;

  const PlaySongScreen({
    super.key,
    required this.song,
    required this.justPlay,
  });

  @override
  State<PlaySongScreen> createState() => _PlaySongScreenState();
}

class _PlaySongScreenState extends State<PlaySongScreen> {
  final audioHandler = getIt<AudioHandler>();
  late MusicProvider musicProvider;
  int? currentPlaybackPosition;
  StreamSubscription<PlaybackState>? playbackStateSubscription;

  // Define the minimum and maximum playback speed limits
  double _timeStretchFactor = 1.0;
  final double _minStretchFactor = 0.5;
  final double _maxStretchFactor = 3.0;
  final double _increment = 0.5;
  bool _increasing = true;
  final pageManager = getIt<PageManager>();
  MediaItem? mediaItem;

  Timer? _songFinishedTimer;
  @override
  void initState() {
    super.initState();
    //deletedQueueItems();

    getIt<PageManager>().init();
    print(audioHandler.queue.value);

    pageManager.removeQueueItemsExceptLast(widget.song['id']);

    mediaItem = audioHandler.queue.value.last;
    print(mediaItem);
    initProvider();
    setupPlaybackPositionListener();
    _startSongFinishedTimer();
    pageManager.play();


    print('Song Screen Last ${audioHandler.queue.value.length}');

  }

  void initProvider() async {

    musicProvider = Provider.of<MusicProvider>(context, listen: false);
    await musicProvider.initialize();
    currentPlaybackPosition =  musicProvider.getPosition(mediaItem!.id);
    if (currentPlaybackPosition != null && currentPlaybackPosition! > 0) {
      audioHandler.seek(Duration(seconds: currentPlaybackPosition!));
    } else {
      currentPlaybackPosition = 0; // Reset the position to 0 if no stored position is available
    }
  }
  void setupPlaybackPositionListener() {
    playbackStateSubscription = audioHandler.playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.ready) {
        final currentPosition = state.position.inSeconds;
        musicProvider.setPosition(mediaItem!.id, currentPosition);
      }
    });
  }
  @override
  void dispose() {
    playbackStateSubscription?.cancel(); // Cancel the subscription
    _songFinishedTimer?.cancel();
    super.dispose();
  }

  double _changeStretchFactor() {
    if (_increasing) {
      _timeStretchFactor += _increment;
      if (_timeStretchFactor >= _maxStretchFactor) {
       setState(() {
         _timeStretchFactor = _maxStretchFactor;
         _increasing = false;
       });
      }

    } else {
      _timeStretchFactor -= _increment;
      if (_timeStretchFactor <= _minStretchFactor) {
       setState(() {
         _timeStretchFactor = _minStretchFactor;
         _increasing = true;
       });
      }
    }
    return _timeStretchFactor;
  }
  void _startSongFinishedTimer() {
    _songFinishedTimer?.cancel();
    _songFinishedTimer = Timer.periodic(Duration(seconds: currentPlaybackPosition ?? 1), (timer) {
      final value = getIt<PageManager>().progressNotifier.value;
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (value.current.inSeconds >= value.total.inSeconds) {
        // Song has finished, set position to 0
        musicProvider.setPosition(mediaItem!.id, 0);
        setState(() {
          currentPlaybackPosition = 0;
        });
      }
    });
  }
  void updateCurrentPlaybackPosition(int  position) {
    setState(() {
      currentPlaybackPosition = position;
    });
  }
/*  deletedQueueItems() {
    final queueLength = audioHandler.queue.value.length;
    for (int i = 1; i < queueLength; i++) {
      audioHandler.removeQueueItemAt(queueLength - (i + 1));
    }
  }*/

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final pageManager = getIt<PageManager>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Playing Screen',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.blue,
          ),
          onPressed: () {
            Navigator.pop(context, widget.justPlay);
            if (kDebugMode) {
              //print('Back to previous screen');
              print('Back to previous screen ${provider.playbackPositions}');
            }
          },
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
         // Image.file(File(widget.song['artUri']),fit: BoxFit.cover,),
          Image.network(
            mediaItem!.artUri.toString(),
            fit: BoxFit.cover,
          ),
          const _BackgroundFilter(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 50.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaItem!.title,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  mediaItem!.album ?? '',
                  maxLines: 2,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 30),
                 AudioProgressBar(id: mediaItem!.id,currentPlaybackPosition: currentPlaybackPosition ?? 0,updateCurrentPlaybackPosition: updateCurrentPlaybackPosition,),
                 AudioControlButtons(id: mediaItem!.id,currentPlaybackPosition: currentPlaybackPosition ?? 0,updateCurrentPlaybackPosition: updateCurrentPlaybackPosition,),
                // Dropdown to select time stretching factor

                InkWell(
                  onTap: (){
                    var result = _changeStretchFactor();
                    provider.setTimeStretchFactor(result);
                    pageManager.setSpeed(result);

                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blueGrey.shade300,
                          Colors.blueAccent,
                          Colors.purpleAccent,
                        ],

                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                       '${_timeStretchFactor}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundFilter extends StatelessWidget {
  const _BackgroundFilter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [
              0.0,
              0.4,
              0.6
            ]).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade200,
              Colors.deepPurple.shade800,
            ],
          ),
        ),
      ),
    );
  }
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
  final String id;
  final int currentPlaybackPosition;
  final Function(int) updateCurrentPlaybackPosition;
   const AudioProgressBar({Key? key,required this.id,required this.currentPlaybackPosition, required this.updateCurrentPlaybackPosition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: pageManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: (Duration duration){
              musicProvider.setPosition(id, duration.inSeconds);
             updateCurrentPlaybackPosition(duration.inSeconds);
            pageManager.seek(duration);
          },
          progressBarColor: Colors.white,
          thumbColor: Colors.white,
          baseBarColor: Colors.grey,
          bufferedBarColor: Colors.white38,
          timeLabelTextStyle: const TextStyle(
            color: Colors.white,
          ),
          timeLabelPadding: 5.0,
        );
      },
    );
  }
}

class AudioControlButtons extends StatelessWidget {
  final String id;
  final int currentPlaybackPosition;
  final Function(int) updateCurrentPlaybackPosition;
   const AudioControlButtons( {Key? key,required this.id, required this.currentPlaybackPosition,required this.updateCurrentPlaybackPosition,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const RepeatButton(),
          //PreviousSongButton(),
          const RewindSongButton(),
          PlayButton(id:id,currentPlaybackPosition : currentPlaybackPosition,updateCurrentPlaybackPosition: updateCurrentPlaybackPosition,),
          const FastForwardSongButton(),
          //NextSongButton(),
          //ShuffleButton(),
          const PlayListButton(),
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
            icon = const Icon(Icons.repeat, color: Colors.white);
            break;
          case RepeatState.repeatSong:
            icon = const Icon(Icons.repeat_one, color: Colors.grey);
            break;
          case RepeatState.repeatPlaylist:
            icon = const Icon(Icons.repeat, color: Colors.blueGrey);
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
          icon: const Icon(Icons.skip_previous, color: Colors.white),
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
          icon: const Icon(Icons.fast_rewind, color: Colors.white),
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
          icon: const Icon(Icons.fast_forward, color: Colors.white),
          onPressed: pageManager.fastForward,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  final String id;
  final int currentPlaybackPosition;
  final Function(int) updateCurrentPlaybackPosition;
   const PlayButton({Key? key,required this.id, required this.currentPlaybackPosition,required this.updateCurrentPlaybackPosition,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    final audioHandler = getIt<AudioHandler>();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: const EdgeInsets.all(8.0),
              width: 32.0,
              height: 32.0,
              child: const CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          case ButtonState.paused:
            return IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              iconSize: 32.0,
              onPressed:  () {
                pageManager.play();
                resumePlayback(audioHandler, id, currentPlaybackPosition,musicProvider);
              },
              //onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: const Icon(Icons.pause, color: Colors.white),
              iconSize: 32.0,
              onPressed: () {
                pageManager.pause();
                stopPlayback(audioHandler, id, musicProvider);
              },
              //onPressed: pageManager.pause,
            );
        }
      },
    );
  }


  void resumePlayback(AudioHandler audioHandler, String id, int? currentPlaybackPosition,MusicProvider musicProvider) {
    final currentPosition = currentPlaybackPosition ?? 0;
    audioHandler.seek(Duration(seconds: currentPosition));
    audioHandler.play();
  }
 /* void resumePlayback(AudioHandler audioHandler, String id, int? currentPlaybackPosition, MusicProvider musicProvider) {
    final currentPosition = currentPlaybackPosition ?? 0;
    final timeStretchedPosition = currentPosition ~/ musicProvider.timeStretchFactor;
    audioHandler.seek(Duration(seconds: timeStretchedPosition));
    audioHandler.play();
  }*/


  void stopPlayback(AudioHandler audioHandler, String id, MusicProvider musicProvider) {
    audioHandler.playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.ready) {
        final currentPosition = state.position.inSeconds;
        if (currentPosition > 0) {
          musicProvider.setPosition(id, currentPosition);

        }
      }
    });
    updateCurrentPlaybackPosition(musicProvider.getPosition(id) ?? 0);// Cancel the subscription after the first update
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
          icon: const Icon(Icons.skip_next, color: Colors.white),
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
              ? const Icon(Icons.shuffle, color: Colors.white)
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
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        return IconButton(
          icon: const Icon(Icons.playlist_play, color: Colors.white),
          onPressed: () async {
            /* final audioHandler = getIt<AudioHandler>();
            final pageManager = getIt<PageManager>();
            audioHandler.addQueueItems(musicProvider.decryptedMediaItems);
            pageManager.play();

              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PlaylistSongScreen(),
                  ));*/
            showMsg(context, 'This section is not completed yet');
          },
        );
      },
    );
  }
}
