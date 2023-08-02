import 'dart:io';

import 'package:flutter/foundation.dart';
import '../notifiers/play_button_notifier.dart';
import '../notifiers/progress_notifier.dart';
import '../notifiers/repeat_button_notifier.dart';
import 'package:audio_service/audio_service.dart';
import 'playlist_repository.dart';
import 'service_locator.dart';

class PageManager {
  // Listeners: Updates going to the UI
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final playlistNotifier = ValueNotifier<List<String>>([]);

  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final rewindSongNotifier = ValueNotifier<bool>(true);
  final fastForwardSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = PlayButtonNotifier();
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  final _audioHandler = getIt<AudioHandler>();

  // Events: Calls coming from the UI
  void init() async {
    await _loadPlaylist();
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
  }

  Future<void> _loadPlaylist() async {
    final songRepository = getIt<PlaylistRepository>();
    final playlist = await songRepository.fetchInitialPlaylist();
    final mediaItems = playlist
        .map(
          (song) => MediaItem(
            id: song.id?.toString() ?? '',
            album: song.album,
            title: song.title,
            extras: {'url': song.url,'isFile': true,},
            artUri: Uri.file(File(song.artUri).path),
          ),
        )
        .toList();
    _audioHandler.addQueueItems(mediaItems);
  }
 /* Future<void> _loadPlaylist() async {
    final songRepository = getIt<PlaylistRepository>();
    final playlist = await songRepository.fetchInitialPlaylist();
    final mediaItems = playlist
        .map(
          (song) => MediaItem(
        id: song['id'] ?? '',
        album: song['album'] ?? '',
        title: song['title'] ?? '',
        extras: {'url': song['url'],'isFile': false,},
        artUri: Uri.parse(song['artUri'] ?? ''),
      ),
    )
        .toList();
    _audioHandler.addQueueItems(mediaItems);
  }*/
  void _listenToChangesInPlaylist() {
    _audioHandler.queue.listen((playlist) {
      if (playlist.isEmpty) {
        playlistNotifier.value = [];
        currentSongTitleNotifier.value = '';
      } else {
        final newList = playlist.map((item) => item.title).toSet().toList();
        playlistNotifier.value = newList;
      }
      _updateSkipButtons();
      _updateRewindAndFastForwardButton();

     /* if (kDebugMode) {
        print('listenToChangesInPlaylist  = ${playlistNotifier.value}');
      }*/
    });
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        _audioHandler.seek(Duration.zero);
        _audioHandler.pause();
      }
    });
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenToBufferedPosition() {
    _audioHandler.playbackState.listen((playbackState) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: playbackState.bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _listenToTotalDuration() {
    _audioHandler.mediaItem.listen((mediaItem) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      );
    });
  }

  void _listenToChangesInSong() {
    _audioHandler.mediaItem.listen((mediaItem) {
      currentSongTitleNotifier.value = mediaItem?.title ?? '';
      _updateSkipButtons();
      _updateRewindAndFastForwardButton();
    });
  }

  void _updateRewindAndFastForwardButton() {
    final currentPosition = _audioHandler.playbackState.value.position;
    final duration = _audioHandler.mediaItem.value?.duration;

    if (duration != null) {
      fastForwardSongNotifier.value =
          currentPosition < duration - const Duration(seconds: 5);
      rewindSongNotifier.value = currentPosition > const Duration(seconds: 5);
    } else {
      fastForwardSongNotifier.value = false;
      rewindSongNotifier.value = false;
    }
  }

  void _updateSkipButtons() {
    final mediaItem = _audioHandler.mediaItem.value;
    final playlist = _audioHandler.queue.value;
    if (playlist.length < 2 || mediaItem == null) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = playlist.first == mediaItem;
      isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }

  void skipToQueueItem(int index) {
    _audioHandler.skipToQueueItem(index);
  }

  void play() => _audioHandler.play();

  void pause() => _audioHandler.pause();

  void seek(Duration position) => _audioHandler.seek(position);

  void setSpeed(double speed) => _audioHandler.setSpeed(speed);

  void previous() => _audioHandler.skipToPrevious();

  void next() => _audioHandler.skipToNext();

  void rewind() => _audioHandler.rewind();

  void fastForward() => _audioHandler.fastForward();

  void repeat() {
    repeatButtonNotifier.nextState();
    final repeatMode = repeatButtonNotifier.value;
    switch (repeatMode) {
      case RepeatState.off:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatState.repeatSong:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatState.repeatPlaylist:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }

  void shuffle() {
    final enable = !isShuffleModeEnabledNotifier.value;
    isShuffleModeEnabledNotifier.value = enable;
    if (enable) {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

/*  Future<void> add() async {
    final songRepository = getIt<PlaylistRepository>();
    final song = await songRepository.fetchAnotherSong();
    final mediaItem = MediaItem(
      id: song['id'] ?? '',
      album: song['album'] ?? '',
      title: song['title'] ?? '',
      extras: {
        'url': song['url'],
      },
      artUri: Uri.parse(song['artUri']!),
    );
    _audioHandler.addQueueItem(mediaItem);
  }*/
/*  void removeQueueItemsExceptLast() async {
    // Get the current queue
    List<MediaItem>? queue = _audioHandler.queue.value;
    if (queue.isEmpty) {
      return; // No items in the queue or the queue is null
    }
    // Find the last added item in the queue
    MediaItem lastAddedItem = queue.last;
     _audioHandler.queue.value.clear();
    _audioHandler.addQueueItem(lastAddedItem);

  }*/
  int getIndexInQueue(String itemId) {
    List<MediaItem> queue = _audioHandler.queue.value;
    int index = queue.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      // Item found, and itemIndex contains the index of the item in the queue.
      print('Item found at index: $index');
    } else {
      // Item not found in the queue.
      print('Item not found in the queue.');
    }
    return index;
  }
  Future<void> removeQueueItemsExceptLast(String id) async {
    List<MediaItem>? queue = _audioHandler.queue.value;
    final queueLength = _audioHandler.queue.value.length;
    //print('queueLength = $queueLength');

    if (queue.isEmpty) {
      return ;
    }
    List<MediaItem> itemsToKeep = [];
    for (var i = 0; i < queueLength; i++) {
      if (queue[i].id == id) {
        itemsToKeep.add(queue[i]);
      }
    }
    for (var i = 0; i < queueLength; i++) {
      _audioHandler.removeQueueItemAt(0);
    }
   // print('itemsToKeep = ${itemsToKeep.last}');
    //print('After removing = ${_audioHandler.queue.value}');
     _audioHandler.addQueueItem(itemsToKeep.last);
    // _audioHandler.updateMediaItem(itemsToKeep.last) ;
    //print('page manager mediaItem = ${_audioHandler.mediaItem.value}');

  }

  void remove() {
    final lastIndex = _audioHandler.queue.value.length - 1;
    if (lastIndex < 0) return;
    _audioHandler.removeQueueItemAt(lastIndex);
  }

  void dispose() {
    _audioHandler.customAction('dispose');
    _audioHandler.onTaskRemoved();
  }

  void stop() {
    _audioHandler.stop();
    _audioHandler.onTaskRemoved();
  }
}
/*
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../notifiers/play_button_notifier.dart';
import '../notifiers/progress_notifier.dart';
import '../notifiers/repeat_button_notifier.dart';
import 'package:audio_service/audio_service.dart';
import 'playlist_repository.dart';
import 'service_locator.dart';

class SingleSongPageManager {
  // Listeners: Updates going to the UI
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final singleSongPlayListNotifier = ValueNotifier<List<String>>([]);
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);
  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final rewindSongNotifier = ValueNotifier<bool>(true);
  final fastForwardSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = PlayButtonNotifier();
  final _singleAudioHandler = getIt<AudioHandler>();
  // Events: Calls coming from the UI
  void init() async {
    await _loadPlaylist();
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
  }

  Future<void> _loadPlaylist() async {
    final songRepository = getIt<PlaylistRepository>();
    final playlist = await songRepository.fetchInitialSinglePlaylist();
    final mediaItems = playlist
        .map(
          (song) => MediaItem(
        id: song['id']?.toString() ?? '',
        album: song['album'],
        title: song['title'] ?? '',
        extras: {'url': song['url']},
        artUri: Uri.parse(song['artUri']!)),
      ).toList();
    _singleAudioHandler.addQueueItems(mediaItems);
  }

  void _listenToChangesInPlaylist() {
    _singleAudioHandler.queue.listen((playlist) {
      if (playlist.isEmpty) {
        singleSongPlayListNotifier.value = [];
        currentSongTitleNotifier.value = '';
      } else {
        final newList = playlist.map((item) => item.title).toSet().toList();
        singleSongPlayListNotifier.value = newList;
      }
      _updateSkipButtons();
      _updateRewindAndFastForwardButton();


    });

  }


  void _listenToPlaybackState() {
    _singleAudioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        _singleAudioHandler.seek(Duration.zero);
        _singleAudioHandler.pause();
      }
    });
  }


  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenToBufferedPosition() {
    _singleAudioHandler.playbackState.listen((playbackState) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: playbackState.bufferedPosition,
        total: oldState.total,
      );
    });
  }


  void _listenToTotalDuration() {
    _singleAudioHandler.mediaItem.listen((mediaItem) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      );
    });

  }

  void _listenToChangesInSong() {
    _singleAudioHandler.mediaItem.listen((mediaItem) {
      currentSongTitleNotifier.value = mediaItem?.title ?? '';
      _updateSkipButtons();
      _updateRewindAndFastForwardButton();
    });

  }
  void _updateRewindAndFastForwardButton() {
    final currentPosition = _singleAudioHandler.playbackState.value.position;
    final duration = _singleAudioHandler.mediaItem.value?.duration;

    if (duration != null) {
      fastForwardSongNotifier.value =
          currentPosition < duration - const Duration(seconds: 5);
      rewindSongNotifier.value = currentPosition > const Duration(seconds: 5);
    } else {
      fastForwardSongNotifier.value = false;
      rewindSongNotifier.value = false;
    }
  }
  */
/*void _updateRewindAndFastForwardButton() {
    final singlePosition = _singleAudioHandler.playbackState.value.position;
    final singleDuration = _singleAudioHandler.mediaItem.value?.duration;
    final playlistPosition = _playlistAudioHandler.playbackState.value.position;
    final playlistDuration = _playlistAudioHandler.mediaItem.value?.duration;

    if (singleDuration != null) {
      rewindSongNotifier.value = singlePosition > const Duration(seconds: 5);
    } else {
      rewindSongNotifier.value = playlistPosition > const Duration(seconds: 5);
    }

    if (singleDuration != null) {
      fastForwardSongNotifier.value =
          singlePosition < singleDuration - const Duration(seconds: 5);
    } else {
      fastForwardSongNotifier.value = false;
    }
  }*//*


  void _updateSkipButtons() {
    final mediaItem = _singleAudioHandler.mediaItem.value;
    final playlist = _singleAudioHandler.queue.value;
    if (playlist.length < 2 || mediaItem == null) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = playlist.first == mediaItem;
      isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }
  void skipToQueueItem(int index,) {
    _singleAudioHandler.skipToQueueItem(index);
  }
*/
/*  void skipToQueueItem(int index, String name) {
    // Depending on the "name" parameter, determine which audio handler to use
    if (name == 'single') {
      _singleAudioHandler.skipToQueueItem(index);
    } else if (name == 'playlist') {
      _playlistAudioHandler.skipToQueueItem(index);
    } else {
      // Handle the case when the "name" is neither "single" nor "playlist"
      // You can choose to raise an exception, show an error, or take any other action as needed.
      print('Invalid name: $name');
    }
  }*//*



  void playSingleSong() => _singleAudioHandler.play();

  void pauseSingleSong() => _singleAudioHandler.pause();

  void seekSingleSong(Duration position) => _singleAudioHandler.seek(position);

  void setSpeedSingleSong(double speed) => _singleAudioHandler.setSpeed(speed);

  void previousSingleSong() => _singleAudioHandler.skipToPrevious();

  void nextSingleSong() => _singleAudioHandler.skipToNext();

  void rewindSingleSong() => _singleAudioHandler.rewind();

  void fastForwardSingleSong() => _singleAudioHandler.fastForward();


  void repeatSingleSong() {
    repeatButtonNotifier.nextState();
    final repeatMode = repeatButtonNotifier.value;
    switch (repeatMode) {
      case RepeatState.off:
        _singleAudioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatState.repeatSong:
        _singleAudioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatState.repeatPlaylist:
        _singleAudioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }
  void shuffleSingleSong() {
    final enable = !isShuffleModeEnabledNotifier.value;
    isShuffleModeEnabledNotifier.value = enable;
    if (enable) {
      _singleAudioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _singleAudioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

*/
/*  Future<void> add() async {
    final songRepository = getIt<PlaylistRepository>();
    final song = await songRepository.fetchAnotherSong();
    final mediaItem = MediaItem(
      id: song['id'] ?? '',
      album: song['album'] ?? '',
      title: song['title'] ?? '',
      extras: {
        'url': song['url'],
      },
      artUri: Uri.parse(song['artUri']!),
    );
    _audioHandler.addQueueItem(mediaItem);
  }*//*

*/
/*  void removeQueueItemsExceptLast() async {
    // Get the current queue
    List<MediaItem>? queue = _audioHandler.queue.value;
    if (queue.isEmpty) {
      return; // No items in the queue or the queue is null
    }
    // Find the last added item in the queue
    MediaItem lastAddedItem = queue.last;
     _audioHandler.queue.value.clear();
    _audioHandler.addQueueItem(lastAddedItem);

  }*//*


  Future<void> removeQueueItemsExceptLast(String id) async {
    List<MediaItem>? queue = _singleAudioHandler.queue.value;
    final queueLength = _singleAudioHandler.queue.value.length;
    //print('queueLength = $queueLength');

    if (queue.isEmpty) {
      return ;
    }
    List<MediaItem> itemsToKeep = [];
    for (var i = 0; i < queueLength; i++) {
      if (queue[i].id == id) {
        itemsToKeep.add(queue[i]);
      }
    }
    for (var i = 0; i < queueLength; i++) {
      _singleAudioHandler.removeQueueItemAt(0);
    }
    // print('itemsToKeep = ${itemsToKeep.last}');
    print('After removing = ${_singleAudioHandler.queue.value}');
    _singleAudioHandler.addQueueItem(itemsToKeep.last);
    print('After Adding = ${_singleAudioHandler.queue.value}');
    // Use a StreamSubscription to wait for the queue update before playing
    late StreamSubscription<List<MediaItem>> subscription;

    // Subscribe to the queue stream
    subscription = _singleAudioHandler.queue.skip(1).listen((_) async {
      // Remove the subscription to avoid potential memory leaks
      await subscription.cancel();
      // Play the last item after the queue update
      await _singleAudioHandler.playMediaItem(itemsToKeep.last);
      print('page manager mediaItem = ${_singleAudioHandler.mediaItem.value}');
    });

  }
  void removeSingleSong() {
    final lastIndex = _singleAudioHandler.queue.value.length - 1;
    if (lastIndex < 0) return;
    _singleAudioHandler.removeQueueItemAt(lastIndex);
  }
  int getIndexInQueue(String itemId) {
    List<MediaItem> queue = _singleAudioHandler.queue.value;
    int index = queue.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      // Item found, and itemIndex contains the index of the item in the queue.
      print('Item found at index: $index');
    } else {
      // Item not found in the queue.
      print('Item not found in the queue.');
    }
    return index;
  }

  void dispose() {
    _singleAudioHandler.customAction('dispose');
    _singleAudioHandler.onTaskRemoved();
  }

  void stop() {
    _singleAudioHandler.stop();
    _singleAudioHandler.onTaskRemoved();
  }
}

class PlaylistSongPageManager {
  // Listeners: Updates going to the UI
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final rewindSongNotifier = ValueNotifier<bool>(true);
  final fastForwardSongNotifier = ValueNotifier<bool>(true);
  //final playButtonNotifier = PlayButtonNotifier();
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  final currentPlaylistSongTitleNotifier = ValueNotifier<String>('');
  final multiSongPlaylistNotifier = ValueNotifier<List<String>>([]);

  final playlistProgressNotifier = ProgressNotifier();
  final playlistRepeatButtonNotifier = RepeatButtonNotifier();
  final playlistPlayButtonNotifier = PlayButtonNotifier();
  final _playlistAudioHandler = getIt<AudioHandler>();

  // Events: Calls coming from the UI
  void init() async {
    await _loadPlaylist();
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
  }


  Future<void> _loadPlaylist() async {
    final songRepository = getIt<PlaylistRepository>();
    final playlist = await songRepository.fetchInitialPlaylist();
    final mediaItems = playlist
        .map(
          (song) => MediaItem(
        id: song.id?.toString() ?? '',
        album: song.album,
        title: song.title,
        extras: {'url': song.url},
        artUri: Uri.file(File(song.artUri).path),
      ),
    )
        .toList();
    _playlistAudioHandler.addQueueItems(mediaItems);
    print('playlist = ${_playlistAudioHandler.queue.value}');
  }

  void _listenToChangesInPlaylist() {
    _playlistAudioHandler.queue.listen((playlist) {
      if (playlist.isEmpty) {
        multiSongPlaylistNotifier.value = [];
        currentPlaylistSongTitleNotifier.value = '';
      } else {
        final newList = playlist.map((item) => item.title).toSet().toList();
        multiSongPlaylistNotifier.value = newList;
      }
      _updateSkipButtons();
      _updateRewindAndFastForwardButton();


    });

  }


  void _listenToPlaybackState() {
    _playlistAudioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playlistPlayButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playlistPlayButtonNotifier.value = ButtonState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playlistPlayButtonNotifier.value = ButtonState.playing;
      } else {
        _playlistAudioHandler.seek(Duration.zero);
        _playlistAudioHandler.pause();
      }
    });
  }


  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      final oldState = playlistProgressNotifier.value;
      playlistProgressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenToBufferedPosition() {
    _playlistAudioHandler.playbackState.listen((playbackState) {
      final oldState = playlistProgressNotifier.value;
      playlistProgressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: playbackState.bufferedPosition,
        total: oldState.total,
      );
    });
  }


  void _listenToTotalDuration() {
    _playlistAudioHandler.mediaItem.listen((mediaItem) {
      final oldState = playlistProgressNotifier.value;
      playlistProgressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      );
    });

  }

  void _listenToChangesInSong() {
    _playlistAudioHandler.mediaItem.listen((mediaItem) {
      currentPlaylistSongTitleNotifier.value = mediaItem?.title ?? '';
      _updateSkipButtons();
      _updateRewindAndFastForwardButton();
    });

  }
  void _updateRewindAndFastForwardButton() {
    final currentPosition = _playlistAudioHandler.playbackState.value.position;
    final duration = _playlistAudioHandler.mediaItem.value?.duration;

    if (duration != null) {
      fastForwardSongNotifier.value =
          currentPosition < duration - const Duration(seconds: 5);
      rewindSongNotifier.value = currentPosition > const Duration(seconds: 5);
    } else {
      fastForwardSongNotifier.value = false;
      rewindSongNotifier.value = false;
    }
  }

  void _updateSkipButtons() {
    final mediaItem = _playlistAudioHandler.mediaItem.value;
    final playlist = _playlistAudioHandler.queue.value;
    if (playlist.length < 2 || mediaItem == null) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = playlist.first == mediaItem;
      isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }
  void skipToQueueItem(int index,) {
    _playlistAudioHandler.skipToQueueItem(index);
  }
*/
/*  void skipToQueueItem(int index, String name) {
    // Depending on the "name" parameter, determine which audio handler to use
    if (name == 'single') {
      _singleAudioHandler.skipToQueueItem(index);
    } else if (name == 'playlist') {
      _playlistAudioHandler.skipToQueueItem(index);
    } else {
      // Handle the case when the "name" is neither "single" nor "playlist"
      // You can choose to raise an exception, show an error, or take any other action as needed.
      print('Invalid name: $name');
    }
  }*//*



  void playPlaylistSong() => _playlistAudioHandler.play();

  void pausePlaylistSong() => _playlistAudioHandler.pause();

  void seekPlaylistSong(Duration position) => _playlistAudioHandler.seek(position);

  void setSpeedPlaylistSong(double speed) => _playlistAudioHandler.setSpeed(speed);

  void previousPlaylistSong() => _playlistAudioHandler.skipToPrevious();

  void nextPlaylistSong() => _playlistAudioHandler.skipToNext();

  void rewindPlaylistSong() => _playlistAudioHandler.rewind();

  void fastForwardPlaylistSong() => _playlistAudioHandler.fastForward();


  void repeatPlaylistSong() {
    playlistRepeatButtonNotifier.nextState();
    final repeatMode = playlistRepeatButtonNotifier.value;
    switch (repeatMode) {
      case RepeatState.off:
        _playlistAudioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatState.repeatSong:
        _playlistAudioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatState.repeatPlaylist:
        _playlistAudioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }
  void shufflePlaylistSong() {
    final enable = !isShuffleModeEnabledNotifier.value;
    isShuffleModeEnabledNotifier.value = enable;
    if (enable) {
      _playlistAudioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _playlistAudioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

*/
/*  Future<void> add() async {
    final songRepository = getIt<PlaylistRepository>();
    final song = await songRepository.fetchAnotherSong();
    final mediaItem = MediaItem(
      id: song['id'] ?? '',
      album: song['album'] ?? '',
      title: song['title'] ?? '',
      extras: {
        'url': song['url'],
      },
      artUri: Uri.parse(song['artUri']!),
    );
    _audioHandler.addQueueItem(mediaItem);
  }*//*

*/
/*  void removeQueueItemsExceptLast() async {
    // Get the current queue
    List<MediaItem>? queue = _audioHandler.queue.value;
    if (queue.isEmpty) {
      return; // No items in the queue or the queue is null
    }
    // Find the last added item in the queue
    MediaItem lastAddedItem = queue.last;
     _audioHandler.queue.value.clear();
    _audioHandler.addQueueItem(lastAddedItem);

  }*//*


 Future<void> removeQueueItemsExceptLast(String id) async {
    List<MediaItem>? queue = _playlistAudioHandler.queue.value;
    final queueLength = _playlistAudioHandler.queue.value.length;
    //print('queueLength = $queueLength');

    if (queue.isEmpty) {
      return ;
    }
    List<MediaItem> itemsToKeep = [];
    for (var i = 0; i < queueLength; i++) {
      if (queue[i].id == id) {
        itemsToKeep.add(queue[i]);
      }
    }
    for (var i = 0; i < queueLength; i++) {
      _playlistAudioHandler.removeQueueItemAt(0);
    }
    // print('itemsToKeep = ${itemsToKeep.last}');
    //print('After removing = ${_audioHandler.queue.value}');
    _playlistAudioHandler.addQueueItem(itemsToKeep.last);
    // _audioHandler.updateMediaItem(itemsToKeep.last) ;
    //print('page manager mediaItem = ${_audioHandler.mediaItem.value}');

  }

  void removeSingleSong() {
    final lastIndex = _playlistAudioHandler.queue.value.length - 1;
    if (lastIndex < 0) return;
    _playlistAudioHandler.removeQueueItemAt(lastIndex);
  }

  void dispose() {
    _playlistAudioHandler.customAction('dispose');
    _playlistAudioHandler.onTaskRemoved();
  }

  void stop() {
    _playlistAudioHandler.stop();
    _playlistAudioHandler.onTaskRemoved();
  }
}*/
