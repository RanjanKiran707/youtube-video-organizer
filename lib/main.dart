import 'package:flutter/material.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/features/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.init();
  runApp(YoutubeSaverApp());
}
