import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider with ChangeNotifier {
  bool _isConnected = true; // Default to true assuming internet is initially available

  bool get isConnected => _isConnected;

  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      _isConnected = true;
    } else {
      _isConnected = false;
    }
    notifyListeners();
  }
  bool _isDarkMode = false;

  ThemeProvider() {
    _initializeTheme();
    _initializePlatformBrightness();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _initializeTheme() async {
    _isDarkMode = await _isPlatformDarkMode();
    notifyListeners();
  }

  Future<void> _initializePlatformBrightness() async {
    var brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      final newBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (newBrightness != brightness) {
        _isDarkMode = newBrightness == Brightness.dark;
        brightness = newBrightness;
        notifyListeners();
      }
    };
  }

  Future<bool> _isPlatformDarkMode() async {
    final platformBrightness = await _getPlatformBrightness();
    return platformBrightness == Brightness.dark;
  }

  Future<Brightness> _getPlatformBrightness() async {
    return await Future.value(
        WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  ThemeData getTheme() {
    return _isDarkMode ? MyThemes.darkTheme : MyThemes.lightTheme;
  }

  void setTheme(bool value) {
    _isDarkMode = value;
    _setPlatformBrightness(_isDarkMode ? Brightness.dark : Brightness.light);
    notifyListeners();
  }

  Future<void> _setPlatformBrightness(Brightness brightness) {
    final style = SystemUiOverlayStyle(
      statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _isDarkMode ? Colors.grey.shade900 : Colors.white ,
      systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      statusBarColor:  _isDarkMode ? Colors.grey.shade900 : Colors.white ,
      //systemNavigationBarDividerColor: _isDarkMode ? Colors.grey.shade800 : Colors.white ,
    );

    return Future.delayed(Duration.zero).then((_) {
      SystemChrome.setSystemUIOverlayStyle(style);
    });
  }
}

class MyThemes {
  static final darkTheme = ThemeData(
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(Colors.white),
      trackColor: MaterialStateProperty.resolveWith((states) =>
      states.contains(MaterialState.selected)
          ? Colors.grey.shade200.withOpacity(0.7)
          : null),
    ),
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.black,
    ),
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.grey.shade900,
    colorScheme: const ColorScheme.dark(),
    iconTheme: const IconThemeData(color: Colors.white),
  );
  static final lightTheme = ThemeData(
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(Colors.black),
      trackColor: MaterialStateProperty.resolveWith((states) =>
      states.contains(MaterialState.selected)
          ? Colors.white.withOpacity(0.7)
          : null),
    ),
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(),
    iconTheme: const IconThemeData(color: Colors.red),
  );
}
class MyWidgetsBindingObserver extends WidgetsBindingObserver {
  final ThemeProvider themeProvider;

  MyWidgetsBindingObserver(this.themeProvider);

  @override
  void didChangePlatformBrightness() {
    final newBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = newBrightness == Brightness.dark;
    themeProvider.setTheme(isDarkMode);
  }
}
