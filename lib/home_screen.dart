import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:play_music_background/widgets/song_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> audioList = [];

  readAudio() async {
    await DefaultAssetBundle.of(context)
        .loadString('json/audio.json')
        .then((value) {
      setState(() {
        audioList = json.decode(value);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    readAudio();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                _TrendingMusic(audioList: audioList),
              ],
            ),
          ),
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
        left: 20.0,
        top: 20.0,
        bottom: 20.0,
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Text('Trending Music'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.27,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: audioList.length,
              itemBuilder: (context, index) {
                return SongCard(song: audioList[index], index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
