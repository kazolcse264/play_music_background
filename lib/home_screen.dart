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
  late MusicProvider musicProvider;

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
          title: Text(
            'Trending Music List',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _TrendingMusic(
                  audioList: musicProvider.audioList,
                  musicProvider: musicProvider),
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
              final isFileLocal = musicProvider.isFileInList(
                  '${audioList[index]['title']}.mp3', musicProvider.mp3Files);
              return SongCard(
                  song: audioList[index],
                  isFileLocal: isFileLocal,
                  index: index);
            },
          ),
        ],
      ),
    );
  }
}
