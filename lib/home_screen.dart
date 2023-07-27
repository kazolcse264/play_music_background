/*import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/providers/theme_provider.dart';
import 'package:play_music_background/utils/helper_functions.dart';
import 'package:play_music_background/widgets/song_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> audioList = [];
  List<bool> backResult = [];
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      readAudio();
    });
    Provider.of<MusicProvider>(context, listen: false)
        .requestStoragePermission();
    Provider.of<MusicProvider>(context, listen: false).loadTempFiles();
    super.initState();
  }

  readAudio() async {
   try {
     await DefaultAssetBundle.of(context)
         .loadString('json/audio.json')
         .then((value) {
       audioList = json.decode(value);
       setState(() {});
       backResult = List<bool>.generate(audioList.length, (index) => false);
     });
   }catch (e) {
     showMsg(context, e.toString(), second: 3);   }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
              ),
              child: AppBar(
                title: Text(
                  'Trending Music List',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                backgroundColor: themeProvider.isDarkMode
                    ? Colors.grey.shade900
                    : Colors.white,
                elevation: 0,
                actions: [
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setTheme(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: _TrendingMusic(audioList: audioList,backResult: backResult)
         */ /* child: Consumer<ConnectivityProvider>(
            builder: (context, connectivityProvider, child) {
              if (connectivityProvider.isConnected) {
                return _TrendingMusic(audioList: audioList);
              } else {
                return Center(
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.red,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/spinner.gif',
                          height: 100,
                          width: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'No Internet Connection',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
            },
          )*/ /*,
        ),
      ),
    );
  }
}

class _TrendingMusic extends StatelessWidget {
  const _TrendingMusic({
    Key? key,
    required this.audioList,
    required this.backResult,
  }) : super(key: key);
  final List<dynamic> audioList;
  final List<bool> backResult;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: Column(
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: audioList.length,
            itemBuilder: (context, index) {
              return SongCard(
                  song: audioList[index], audioList: audioList, index: index,backResult: backResult);
            },
          ),
        ],
      ),
    );
  }
}*/

import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import 'package:marquee/marquee.dart';

import 'package:play_music_background/page_manager.dart';
import 'package:play_music_background/play_song_screen.dart';
import 'package:play_music_background/playlist_song_home_page.dart';

import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/providers/theme_provider.dart';
import 'package:play_music_background/services/service_locator.dart';
import 'package:play_music_background/utils/helper_functions.dart';
import 'package:play_music_background/widgets/song_card.dart';
import 'package:provider/provider.dart';

import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> audioList = [];
  List<bool> backResult = [];

  bool _bottomNavBarVisible = false;

  Map<String, dynamic>? playingSong;
  final audioHandler = getIt<AudioHandler>();
  late MusicProvider musicProvider;
  int? currentPlaybackPosition;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      readAudio();
    });
    Provider.of<MusicProvider>(context, listen: false)
        .requestStoragePermission();
    initProvider();
    getIt<PageManager>().init();

    Provider.of<MusicProvider>(context, listen: false).loadTempFiles();
    super.initState();
  }

  readAudio() async {
    try {
      await DefaultAssetBundle.of(context)
          .loadString('json/audio.json')
          .then((value) {
        audioList = json.decode(value);
        setState(() {});
        backResult = List<bool>.generate(audioList.length, (index) => false);
      });
    } catch (e) {
      showMsg(context, e.toString(), second: 3);
    }
  }

  void updateCurrentPlaybackPosition(int position) {
    setState(() {
      currentPlaybackPosition = position;
    });
  }

  void initProvider() async {
    musicProvider = Provider.of<MusicProvider>(context, listen: false);
    await musicProvider.initialize();

  }
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Trending Music List',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Provider.of<ThemeProvider>(context).isDarkMode
                          ? Colors.white
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
                  ? Colors.grey.shade900
                  : Colors.white,
              elevation: 0,
              actions: [
                Switch(
                  value: Provider.of<ThemeProvider>(context).isDarkMode,
                  onChanged: (value) {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .setTheme(value);
                  },
                ),
                TextButton(onPressed: () async {
                  if (mounted) {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistSongHomePage(),
                      ),
                    );
                  }
                }, child: const Text('Go to Playlist'))

              ],
             /* bottom: TabBar(
                labelStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Provider.of<ThemeProvider>(context).isDarkMode
                          ? Colors.white
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                tabs: const [
                  Tab(
                    text: 'Music List',
                  ),
                  Tab(text: 'PodCast List'),
                ],
              ),*/
            ),
            bottomNavigationBar: Visibility(
              visible: audioHandler.queue.value.isNotEmpty,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 8,
                            blurRadius: 10,
                            offset: const Offset(
                                5, 5), // changes position of shadow
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.7),
                            spreadRadius: 8,
                            blurRadius: 10,
                            offset: const Offset(
                                -5, -5), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              if (mounted) {
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaySongScreen(
                                        song: playingSong!, justPlay: true),
                                  ),
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              color:
                                  Provider.of<ThemeProvider>(context).isDarkMode
                                      ? Colors.black
                                      : Colors.white,
                              height: 50,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                // Center items vertically
                                children: [
                                  Container(
                                    height: 50,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Provider.of<ThemeProvider>(context)
                                              .isDarkMode
                                          ? Colors.grey.shade900
                                          : Colors.white,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: playingSong?['artUri'] ??
                                          'https://cdn-icons-png.flaticon.com/512/5683/5683980.png',
                                      fit: BoxFit.fitWidth,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(
                                        color: Colors.blue,
                                        strokeWidth: 2,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      width: 200,
                                      height: 50,
                                      child: Marquee(
                                        text:
                                            playingSong?['title'] ?? 'No Title',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              color: Provider.of<ThemeProvider>(
                                                          context)
                                                      .isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),

                                        scrollAxis: Axis.horizontal,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        // Center text vertically
                                        blankSpace: 20.0,
                                        velocity: 100.0,
                                        startPadding: 10.0,
                                        accelerationDuration:
                                            const Duration(seconds: 1),
                                        accelerationCurve: Curves.linear,
                                        decelerationDuration:
                                            const Duration(milliseconds: 500),
                                        decelerationCurve: Curves.easeOut,
                                      ),
                                    ),
                                  ),
                                  PlayButton(
                                      id: playingSong?['id'] ?? 'No id found'),
                                ],
                              ),
                            ),
                          ),
                          AudioProgressBar(
                            id: playingSong?['id'] ?? 'No id found',
                            updateCurrentPlaybackPosition:
                                updateCurrentPlaybackPosition,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),

            body:  SingleChildScrollView(
              child: _TrendingMusic(
                audioList: audioList,
                backResult: backResult,
                onSongCardTrailingTap: (Map<String, dynamic> song) {
                  setState(() {
                    _bottomNavBarVisible = !_bottomNavBarVisible;
                    playingSong = song;
                  });
                },
              ),
            ),
            /*body: TabBarView(
            children: [
              SingleChildScrollView(
                child: _TrendingMusic(
                  audioList: audioList,
                  backResult: backResult,
                  onSongCardTrailingTap: (Map<String, dynamic> song) {
                    setState(() {
                      _bottomNavBarVisible = !_bottomNavBarVisible;
                      playingSong = song;
                    });
                  },
                ),
              ),
              ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('List Item $index'),
                  );
                },
              ),

            ],
          ),*/
            ),
      ),
    );
  }


}

class AudioProgressBar extends StatelessWidget {
  final String id;
  final Function(int) updateCurrentPlaybackPosition;

  const AudioProgressBar(
      {Key? key, required this.id, required this.updateCurrentPlaybackPosition})
      : super(key: key);

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
          onSeek: (Duration duration) {
            musicProvider.setPosition(id, duration.inSeconds);
            updateCurrentPlaybackPosition(duration.inSeconds);
            pageManager.seek(duration);
          },
          progressBarColor: Colors.blue,
          thumbColor: Colors.blue,
          baseBarColor: Colors.grey.withOpacity(0.5),
          bufferedBarColor: Colors.blueAccent.withOpacity(0.3),
          timeLabelTextStyle: const TextStyle(
            color: Colors.black,
          ),
          timeLabelLocation: TimeLabelLocation.none,
          barHeight: 3,
          thumbCanPaintOutsideBar: false,
          thumbRadius: 4,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  final String id;

  const PlayButton({
    Key? key,
    required this.id,
  }) : super(key: key);

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
                color: Colors.blue,
              ),
            );
          case ButtonState.paused:
            return IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: Provider.of<ThemeProvider>(context).isDarkMode
                    ? Colors.white
                    : Colors.black,
              ),
              iconSize: 32.0,
              onPressed: () {
                /*  final currentPosition = musicProvider.getPosition(id);
                print(currentPosition);*/
                pageManager.play();
                resumePlayback(audioHandler, id, musicProvider);
              },
              //onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: Icon(
                Icons.pause,
                color: Provider.of<ThemeProvider>(context).isDarkMode
                    ? Colors.white
                    : Colors.black,
              ),
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

  void resumePlayback(
      AudioHandler audioHandler, String id, MusicProvider musicProvider) {
    final currentPosition = musicProvider.getPosition(id);
    audioHandler.seek(Duration(seconds: currentPosition ?? 0));
    audioHandler.play();
  }

  void stopPlayback(
      AudioHandler audioHandler, String id, MusicProvider musicProvider) {
    audioHandler.playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.ready) {
        final currentPosition = state.position.inSeconds;
        if (currentPosition > 0) {
          musicProvider.setPosition(id, currentPosition);
        }
      }
    }).cancel(); // Cancel the subscription after the first update
  }
}

class _TrendingMusic extends StatelessWidget {
  const _TrendingMusic({
    Key? key,
    required this.audioList,
    required this.backResult,
    required this.onSongCardTrailingTap,
  }) : super(key: key);
  final List<dynamic> audioList;
  final List<bool> backResult;

  final Function(Map<String, dynamic>) onSongCardTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: Column(
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: audioList.length,
            itemBuilder: (context, index) {
              return SongCard(
                song: audioList[index],
                audioList: audioList,
                index: index,
                backResult: backResult,
                onTrailingTap: (Map<String, dynamic> song) {
                  onSongCardTrailingTap(song);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
