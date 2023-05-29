import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  StreamSubscription<ConnectivityResult>? _subscription;
  final StreamController<bool> _connectivityStreamController =
  StreamController<bool>.broadcast();

  bool get isConnected => _isConnected;

  Stream<bool> get connectivityStream => _connectivityStreamController.stream;

  ConnectivityProvider() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      bool connected = result != ConnectivityResult.none;
      if (connected != _isConnected) {
        _isConnected = connected;
        _connectivityStreamController.add(connected);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connectivityStreamController.close();
    super.dispose();
  }
}
