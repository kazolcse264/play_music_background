

import 'package:flutter/material.dart';
import 'package:play_music_background/home_screen.dart';

import 'services/service_locator.dart';

void main() async {
  await setupServiceLocator();
  runApp(const HomeScreen());
}


