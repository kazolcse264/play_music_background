
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  final BehaviorSubject<MediaItem?> _mediaItemSubject = BehaviorSubject<MediaItem?>.seeded(null);
  @override
  BehaviorSubject<MediaItem?> get mediaItem => _mediaItemSubject;
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);


  MyAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);

    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }
/*  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      final currentIndex = event.currentIndex;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode:
        (_player.shuffleModeEnabled) ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: currentIndex,
      ));
    });
  }*/

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          //MediaControl.skipToPrevious,
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop ,
          MediaControl.fastForward ,
          //MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }
/*  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      mediaItem.add(playlist[index]);

      // Update the playback state when the current song index changes
      playbackState.add(playbackState.value.copyWith(
        queueIndex: index,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
      ));
    });
  }*/

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.addAll(audioSource.toList());

    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final audioSource = _createAudioSource(mediaItem);


    _playlist.add(audioSource);
    // notify system
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }
  AudioSource _createAudioSource(MediaItem mediaItem) {
    final extras = mediaItem.extras;
    if (extras != null) {
      final url = extras['url'];
      final isFile = extras['isFile'];
      if (url != null && isFile == true) {
        return AudioSource.file(url as String, tag: mediaItem);

      }
    }
    return AudioSource.uri(
      Uri.parse(mediaItem.extras?['url'] ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      tag: mediaItem,
    );
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    _playlist.removeAt(index);
    // notify system
    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    if (_player.shuffleModeEnabled) {
      index = _player.shuffleIndices![index];
    }
    _player.seek(Duration.zero, index: index);
  }

/*  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;

    final currentQueue = queue.value;
    final mediaItem = currentQueue[index];

    if (_player.playing && _player.currentIndex == index) {
      // Just seek to the beginning if the same media item is already playing
      await _player.seek(Duration.zero);
      playbackState.add(playbackState.value.copyWith(
        queueIndex: index,
        updatePosition: Duration.zero,
      ));
    } else {
      // Otherwise, skip to the new media item
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      await _player.seek(Duration.zero, index: index);
    }
  }*/


  @override
  Future<void> play() => _player.play();


  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

@override
  Future<void> fastForward() => _player.seek(Duration(seconds: _player.position.inSeconds + 10));
  @override
  Future<void> rewind() =>  _player.seek(Duration(seconds: _player.position.inSeconds - 10));
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }


  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      _player.setShuffleModeEnabled(true);
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.stop();
      await _player.dispose();

      super.stop();
    }
  }
  @override
  Future<void> onNotificationDeleted() async{

    await stop();
    return super.onNotificationDeleted();
  }
  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }


}


/*
class SingleAudioHandler extends BaseAudioHandler {

  final _player = AudioPlayer();
  final _singleSongPlaylist = ConcatenatingAudioSource(children: []);

  SingleAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_singleSongPlaylist);

    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          //MediaControl.skipToPrevious,
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop ,
          MediaControl.fastForward ,
          //MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _singleSongPlaylist.addAll(audioSource.toList());

    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final audioSource = _createAudioSource(mediaItem);


    _singleSongPlaylist.add(audioSource);
    // notify system
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }
  AudioSource _createAudioSource(MediaItem mediaItem) {
    final extras = mediaItem.extras;
    if (extras != null) {
      final url = extras['url'];
      final isFile = extras['isFile'];
      if (url != null && isFile == true) {
        return AudioSource.file(url as String, tag: mediaItem);

      }
    }
    return AudioSource.uri(
      Uri.parse(mediaItem.extras?['url'] ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      tag: mediaItem,
    );
  }


*/
/* UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return  AudioSource.uri(
      Uri.parse(mediaItem.extras?['url'] ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      tag: mediaItem,
    );
    //AudioSource.file(mediaItem.extras!['url'] as String,tag: mediaItem,);

  }*//*



  @override
  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    _singleSongPlaylist.removeAt(index);
    // notify system
    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    if (_player.shuffleModeEnabled) {
      index = _player.shuffleIndices![index];
    }
    _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> play() => _player.play();


  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> fastForward() => _player.seek(Duration(seconds: _player.position.inSeconds + 10));
  @override
  Future<void> rewind() =>  _player.seek(Duration(seconds: _player.position.inSeconds - 10));
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }


  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      _player.setShuffleModeEnabled(false);
    } else {
      await _player.shuffle();
      _player.setShuffleModeEnabled(true);
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      await _player.stop();
      super.stop();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }


}
class PlaylistAudioHandler extends BaseAudioHandler {

  final _playlistPlayer = AudioPlayer();
  final _multiSongPlaylist = ConcatenatingAudioSource(children: []);
  PlaylistAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _playlistPlayer.setAudioSource(_multiSongPlaylist);

    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _playlistPlayer.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _playlistPlayer.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          //MediaControl.skipToPrevious,
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop ,
          MediaControl.fastForward ,
          //MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_playlistPlayer.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_playlistPlayer.loopMode]!,
        shuffleMode: (_playlistPlayer.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _playlistPlayer.position,
        bufferedPosition: _playlistPlayer.bufferedPosition,
        speed: _playlistPlayer.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _playlistPlayer.durationStream.listen((duration) {
      var index = _playlistPlayer.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_playlistPlayer.shuffleModeEnabled) {
        index = _playlistPlayer.shuffleIndices!.indexOf(index);
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _playlistPlayer.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_playlistPlayer.shuffleModeEnabled) {
        index = _playlistPlayer.shuffleIndices!.indexOf(index);
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _playlistPlayer.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // manage Just Audio
    final audioSource = mediaItems.map(_createAudioSource);
    _multiSongPlaylist.addAll(audioSource.toList());

    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final audioSource = _createAudioSource(mediaItem);


    _multiSongPlaylist.add(audioSource);
    // notify system
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }
  AudioSource _createAudioSource(MediaItem mediaItem) {
    final extras = mediaItem.extras;
    if (extras != null) {
      final url = extras['url'];
      final isFile = extras['isFile'];
      if (url != null && isFile == true) {
        return AudioSource.file(url as String, tag: mediaItem);

      }
    }
    return AudioSource.uri(
      Uri.parse(mediaItem.extras?['url'] ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      tag: mediaItem,
    );
  }


*/
/* UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return  AudioSource.uri(
      Uri.parse(mediaItem.extras?['url'] ?? 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      tag: mediaItem,
    );
    //AudioSource.file(mediaItem.extras!['url'] as String,tag: mediaItem,);

  }*//*



  @override
  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    _multiSongPlaylist.removeAt(index);
    // notify system
    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    if (_playlistPlayer.shuffleModeEnabled) {
      index = _playlistPlayer.shuffleIndices![index];
    }
    _playlistPlayer.seek(Duration.zero, index: index);
  }

  @override
  Future<void> play() => _playlistPlayer.play();


  @override
  Future<void> pause() => _playlistPlayer.pause();

  @override
  Future<void> seek(Duration position) => _playlistPlayer.seek(position);
  @override
  Future<void> setSpeed(double speed) => _playlistPlayer.setSpeed(speed);

  @override
  Future<void> skipToNext() => _playlistPlayer.seekToNext();

  @override
  Future<void> skipToPrevious() => _playlistPlayer.seekToPrevious();

  @override
  Future<void> fastForward() => _playlistPlayer.seek(Duration(seconds: _playlistPlayer.position.inSeconds + 10));
  @override
  Future<void> rewind() =>  _playlistPlayer.seek(Duration(seconds: _playlistPlayer.position.inSeconds - 10));
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _playlistPlayer.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        _playlistPlayer.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
      _playlistPlayer.setLoopMode(LoopMode.all);
        break;
    }
  }


  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      _playlistPlayer.setShuffleModeEnabled(false);
    } else {
      await _playlistPlayer.shuffle();
      _playlistPlayer.setShuffleModeEnabled(true);
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _playlistPlayer.dispose();
      await _playlistPlayer.stop();
      super.stop();
    }
  }

  @override
  Future<void> stop() async {
    await _playlistPlayer.stop();
    return super.stop();
  }


}*/
