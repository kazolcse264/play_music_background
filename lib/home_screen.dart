import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/widgets/song_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
 /* List<dynamic> audioList = [];

  readAudio() async {
    await DefaultAssetBundle.of(context)
        .loadString('json/audio.json')
        .then((value) {
      setState(() {
        audioList = json.decode(value);
      });
    });
  }*/
late MusicProvider musicProvider;
/*  @override
  void initState() {
    super.initState();
    musicProvider = Provider.of<MusicProvider>(context);
    musicProvider.readAudio(context);
    musicProvider.requestStoragePermission();
    musicProvider.loadTempFiles();
  }*/
  @override
  void didChangeDependencies() {
    musicProvider = Provider.of<MusicProvider>(context);
    musicProvider.readAudio(context);
    musicProvider.requestStoragePermission();
    musicProvider.loadTempFiles();
    super.didChangeDependencies();
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
              _TrendingMusic(audioList: musicProvider.audioList, musicProvider: musicProvider),
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
    required this.musicProvider,
  }) : super(key: key);

  final List<dynamic> audioList;
  final MusicProvider musicProvider;

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
            final  isFileLocal = musicProvider.isFileInList(
                  '${audioList[index]['title']}.mp3', musicProvider.mp3Files);
              return SongCard(song: audioList[index], isFileLocal : isFileLocal,index : index);
            },
          ),
        ],
      ),
    );
  }
}
