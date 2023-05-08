

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:play_music_background/home_screen.dart';
import 'package:play_music_background/services/audio_handler.dart';

import 'services/service_locator.dart';

void main() async {
 await setupServiceLocator();
  runApp(const HomeScreen());
}


