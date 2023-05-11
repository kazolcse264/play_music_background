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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title:  Text('Trending Music List', style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),),
          backgroundColor: Colors.transparent,
          elevation: 0,
         /* actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaylistSongScreen(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Text(
                  'Go to playlist',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],*/
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _TrendingMusic(audioList: audioList),
            ],
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
        right: 20.0,
      ),
      child: Column(
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: audioList.length,
            itemBuilder: (context, index) {
              return SongCard(song: audioList[index], index: index,);
            },
          ),
        ],
      ),
    );
  }
}
