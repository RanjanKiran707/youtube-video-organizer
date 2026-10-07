import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';
import 'package:youtube_saver/core/theme/app_theme.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/save_shared_video_argument_model.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/youtube_url_parser.dart';
import 'package:youtube_saver/features/app/share_source.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view_model.dart';
import 'package:youtube_saver/features/library/library_view.dart';

class YoutubeSaverApp extends StatefulWidget {
  final ShareSource shareSource;

  YoutubeSaverApp({super.key, ShareSource? shareSource})
    : shareSource = shareSource ?? ReceiveSharingIntentShareSource();

  @override
  State<YoutubeSaverApp> createState() => _YoutubeSaverAppState();
}

class _YoutubeSaverAppState extends State<YoutubeSaverApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String>? _shareSubscription;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _shareSubscription = widget.shareSource.texts().listen(_onShared);
    // After the first frame, so the navigator exists.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final text = await widget.shareSource.initialText();
      if (text != null) _onShared(text);
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onShared(String text) async {
    final navigator = _navigatorKey.currentState;
    final youtubeId = parseYoutubeVideoId(text);

    if (youtubeId == null) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("That isn't a link to a YouTube video."),
          ),
        );
      return;
    }
    // One picker at a time: a second share while choosing is ignored.
    if (navigator == null || _pickerOpen) return;
    _pickerOpen = true;

    final saved = await navigator.push<bool>(
      FolderPickerView.route(
        FolderPickerBundle(
          title: 'Save to…',
          confirmVerb: 'Save',
          previewThumbnailUrl:
              'https://i.ytimg.com/vi/$youtubeId/hqdefault.jpg',
          previewText: text,
          onConfirm: (folderId) => AppDependencies.instance.saveSharedVideo(
            SaveSharedVideoArgumentModel(
              videoId: const Uuid().v4(),
              sharedText: text,
              folderId: folderId,
            ),
          ),
        ),
      ),
    );
    _pickerOpen = false;

    if (saved == true) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YT Playlist',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: context.colors.bg,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child!,
        );
      },
      home: const LibraryView(),
    );
  }
}
