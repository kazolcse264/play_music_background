import 'dart:io';

import 'package:flutter/foundation.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'package:audio_service/audio_service.dart';
import 'services/playlist_repository.dart';
import 'services/service_locator.dart';

class PageManager {
  // Listeners: Updates going to the UI
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final playlistNotifier = ValueNotifier<List<String>>([]);

  final fileListNotifier = ValueNotifier<List<Map<String, dynamic>> >([{}]);

  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = PlayButtonNotifier();
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  final _audioHandler = getIt<AudioHandler>();

  // Events: Calls coming from the UI
  void init() async {
   // await _loadPlaylist();
    //_listenToChangesInPlaylist();
    _listenToPlaybackState();
   // _listenToCurrentPosition();
    //_listenToBufferedPosition();
    //_listenToTotalDuration();
    //_listenToChangesInSong();
  }

 Future<void> _loadPlaylist() async {
    final songRepository = getIt<PlaylistRepository>();
    final playlist = await songRepository.fetchInitialPlaylist();
    final mediaItems = playlist
        .map(
          (song) => MediaItem(
            id: song['id'] ?? '',
            album: song['album'] ?? '',
            title: song['title'] ?? '',
            extras: {'url': song['url']},
            artUri: Uri.parse(song['artUri']!),
          ),
        )
        .toList();
    _audioHandler.addQueueItems(mediaItems);
  }

/*  Future<void> _loadPlaylist() async {
    final songRepository = getIt<PlaylistRepository>();
    final playlist = await songRepository.fetchInitialPlaylist();
    //final mediaItems = getMediaItemsFromFiles(playlist);
    final mediaItems = convertFilesToMediaItems(playlist);
    _audioHandler.addQueueItems(mediaItems);
  }*/
/*  List<MediaItem> convertFilesToMediaItems(List<File> files) {
    return files.map((file) => MediaItem(
      id: file.path,
      album: "",
      title: file.path.split('/').last,
      artist: "",
      duration: null,
      artUri: null,
      extras: {"file": file},
    )).toList();
  }*/
/*  Future<List<MediaItem>> getMediaItemsFromFiles(List<File> files) async {
    final FlutterAudioQuery audioQuery = FlutterAudioQuery();

    // Create a list of MediaItems from the list of Files
    List<MediaItem> mediaItems = [];
    for (File file in files) {
      // Get the metadata for the file using FlutterAudioQuery
      final List<SongInfo> songInfoList = await audioQuery.getSongs(
        // paths: [file.path],
        // Set the song title as the filename if the title is null
        sortType: SongSortType.DEFAULT,
      );
      if (songInfoList.isNotEmpty) {
        final SongInfo songInfo = songInfoList[0];
        // Create a MediaItem from the metadata and file
        final MediaItem mediaItem = MediaItem(
          id: songInfo.id,
          album: songInfo.album,
          title: songInfo.title ?? file.path.split('/').last,
          artist: songInfo.artist,
          //duration: Duration(milliseconds: songInfo.duration),
          artUri: songInfo.albumArtwork != null
              ? Uri.file(songInfo.albumArtwork)
              : null,
          extras: {"file": file},
        );
        mediaItems.add(mediaItem);
      }
    }
    return mediaItems;
  }*/

  void _listenToChangesInPlaylist() {
    _audioHandler.queue.listen((playlist) {
      if (playlist.isEmpty) {
        playlistNotifier.value = [];
        currentSongTitleNotifier.value = '';
      } else {
        final newList = playlist.map((item) => item.title).toList();
        playlistNotifier.value = newList;
      }
      _updateSkipButtons();
    });
  }
  /*void _listenToChangesInPlaylist() {
    _audioHandler.queue.listen((playlist) {
      if (playlist.isEmpty) {
        fileListNotifier.value = [{}];
        currentSongTitleNotifier.value = '';
      } else {
        final newList = playlist.map((item) => item).toList();
        fileListNotifier.value = newList.cast<Map<String, dynamic>>();
      }
      _updateSkipButtons();
    });
  }*/
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
    });
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
  void skipToQueueItem(int index, String name) {
    _audioHandler.skipToQueueItem(index);
  }
  void play() => _audioHandler.play();

  void pause() => _audioHandler.pause();

  void seek(Duration position) => _audioHandler.seek(position);

  void previous() => _audioHandler.skipToPrevious();

  void next() => _audioHandler.skipToNext();

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

  Future<void> add() async {
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
  }

/*  void remove() {
    final lastIndex = _audioHandler.queue.value.length - 1;
    if (lastIndex < 0) return;
    _audioHandler.removeQueueItemAt(lastIndex);
  }*/

  void dispose() {
    _audioHandler.customAction('dispose');
    _audioHandler.onTaskRemoved();
  }

  void stop() {
    _audioHandler.stop();
    _audioHandler.onTaskRemoved();
  }
}