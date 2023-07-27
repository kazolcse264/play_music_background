import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:play_music_background/services/playlist_repository.dart';

import '../page_manager.dart';
import '../providers/music_provider.dart';
import 'audio_handler.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // services
  getIt.registerSingleton<AudioHandler>(await initAudioService());
  // Pass the MusicProvider instance when registering DemoPlaylist
  var musicProvider = MusicProvider();
  //await musicProvider.getAllSongs(); // Make sure to fetch the songs before registering
  getIt.registerLazySingleton<PlaylistRepository>(() => DemoPlaylist(musicProvider));

  // page state
  getIt.registerLazySingleton<PageManager>(() => PageManager());
}
