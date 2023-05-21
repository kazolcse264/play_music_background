import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:play_music_background/services/service_locator.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'page_manager.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class PlaylistSongScreen extends StatefulWidget {
  const PlaylistSongScreen({
    super.key,
  });

  @override
  State<PlaylistSongScreen> createState() => _PlaylistSongScreenState();
}

class _PlaylistSongScreenState extends State<PlaylistSongScreen> {
  @override
  void initState() {
    super.initState();
   // getIt<PageManager>().init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Song Screen'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            if (kDebugMode) {
              print('Back to previous screen');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: const [
            CurrentSongTitle(),
            Playlist(),
            AddRemoveSongButtons(),
            AudioProgressBar(),
            AudioControlButtons(),
          ],
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

//For showing Image  in the Playlist
/*class Playlist extends StatelessWidget {
  const Playlist({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<List<Uri?>>(
      valueListenable: pageManager.playlistArtUriNotifier,
      builder: (context, playlistArtUri, _) {
        return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: playlistArtUri.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    pageManager.skipToQueueItem(index,'');
                  },
                  child: ListTile(
                      leading: Image.network(playlistArtUri[index].toString())
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
          // RewindSongButton(),
          PlayButton(),
          //FastForwardSongButton(),
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

class AddRemoveSongButtons extends StatelessWidget {
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
