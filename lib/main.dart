import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/features/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch framework errors and print readable Dart messages & stack traces.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return false;
  };

  // Portrait only. The player allows landscape while it is full screen.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await AppDependencies.init();
  runApp(YoutubeSaverApp());
}
