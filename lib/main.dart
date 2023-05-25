import 'package:flutter/material.dart';
import 'package:play_music_background/home_screen.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  final themeProvider = ThemeProvider();
  final observer = MyWidgetsBindingObserver(themeProvider);

  WidgetsBinding.instance.addObserver(observer);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MusicProvider(),
        ),
        ChangeNotifierProvider.value(
          value: themeProvider,
        )
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Play Music Background',
      theme: Provider.of<ThemeProvider>(context).getTheme(),
      home:  const HomeScreen(),
    );
  }
}
