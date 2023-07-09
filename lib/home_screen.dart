import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:play_music_background/providers/connection_provider.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/providers/theme_provider.dart';
import 'package:play_music_background/widgets/song_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> audioList = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      readAudio();
    });

    if (kDebugMode) {
      print('init state');
    }

    Provider.of<MusicProvider>(context, listen: false)
        .requestStoragePermission();
    Provider.of<MusicProvider>(context, listen: false).loadTempFiles();
    super.initState();
  }

  readAudio() async {
    await DefaultAssetBundle.of(context)
        .loadString('json/audio.json')
        .then((value) {
      audioList = json.decode(value);
      setState(() {});
    });
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
          child: _TrendingMusic(audioList: audioList)
         /* child: Consumer<ConnectivityProvider>(
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
          )*/,
        ),
      ),
    );
  }
}

class _TrendingMusic extends StatelessWidget {
  const _TrendingMusic({
    Key? key,
    required this.audioList,
  }) : super(key: key);
  final List<dynamic> audioList;

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
                  song: audioList[index], audioList: audioList, index: index);
            },
          ),
        ],
      ),
    );
  }
}
