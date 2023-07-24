import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:play_music_background/home_screen.dart';
import 'package:play_music_background/providers/connection_provider.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  notificationInitialized();

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
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProvider.value(
          value: themeProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

notificationInitialized() async{
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings(
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );
  const LinuxInitializationSettings initializationSettingsLinux =
  LinuxInitializationSettings(defaultActionName: 'Open notification');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);


}

void onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) {
  // Handle the received local notification
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
