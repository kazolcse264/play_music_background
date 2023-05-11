import 'package:flutter/material.dart';
import 'package:play_music_background/home_screen.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:provider/provider.dart';

import 'services/service_locator.dart';

void main() async {
  await setupServiceLocator();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MusicProvider()),
    ],
    child: const MyApp(),
  ));
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Play Music Background',
      home: HomeScreen(),
    );
  }
}