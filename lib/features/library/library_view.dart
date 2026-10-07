import 'package:flutter/material.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/core/widgets/obx_value.dart';
import 'package:youtube_saver/data/video/video_model.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view_model.dart';
import 'package:youtube_saver/features/library/library_view_model.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view_model.dart';
import 'package:youtube_saver/features/player/player_view.dart';
import 'package:youtube_saver/features/player/player_view_model.dart';
import 'package:youtube_saver/features/shared/failure_message.dart';
import 'package:youtube_saver/features/shared/folder_browser_controller.dart';
import 'package:youtube_saver/features/shared/widgets/breadcrumb.dart';
import 'package:youtube_saver/features/shared/widgets/folder_tile.dart';
import 'package:youtube_saver/features/shared/widgets/text_input_dialog.dart';
import 'package:youtube_saver/features/shared/widgets/video_tile.dart';

enum _ItemAction { rename, move, delete }

class LibraryView extends StatefulWidget {
  final LibraryBundle bundle;
  const LibraryView({super.key, this.bundle = const LibraryBundle()});

  static Future<void> open(BuildContext context, LibraryBundle bundle) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryView(bundle: bundle)),
    );
  }

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel ctrl;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = LibraryViewModel(
      bundle: widget.bundle,
      listFolderContents: deps.listFolderContents,
      getFolderPath: deps.getFolderPath,
      renameFolder: deps.renameFolder,
      renameVideo: deps.renameVideo,
      deleteFolder: deps.deleteFolder,
      deleteVideo: deps.deleteVideo,
      moveFolder: deps.moveFolder,
      moveVideo: deps.moveVideo,
    );
    ctrl.actionState.addListener(_onActionStateChanged);
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (state is ViewStateError && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(messageFor(state.failure))));
    }
  }

  @override
  void dispose() {
    ctrl.actionState.removeListener(_onActionStateChanged);
    ctrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(String title, String body) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  Future<void> _onFolderAction(FolderItem folder, _ItemAction action) async {
    switch (action) {
      case _ItemAction.rename:
        final name = await TextInputDialog.open(
          context,
          title: 'Rename folder',
          initialText: folder.name,
        );
        if (name != null) await ctrl.renameFolder(folder.id, name);
      case _ItemAction.move:
        await FolderPickerView.open(
          context,
          FolderPickerBundle(
            title: 'Move "${folder.name}"',
            confirmVerb: 'Move',
            excludeFolderId: folder.id,
            onConfirm: (destination) => ctrl.moveFolder(folder.id, destination),
          ),
        );
      case _ItemAction.delete:
        final yes = await _confirmDelete(
          'Delete "${folder.name}"?',
          'The folder, its subfolders and all their videos are removed from the app. The videos stay on YouTube.',
        );
        if (yes) await ctrl.deleteFolder(folder.id);
    }
  }

  Future<void> _onVideoAction(VideoModel video, _ItemAction action) async {
    switch (action) {
      case _ItemAction.rename:
        final title = await TextInputDialog.open(
          context,
          title: 'Rename video',
          initialText: video.title,
        );
        if (title != null) await ctrl.renameVideo(video.id, title);
      case _ItemAction.move:
        await FolderPickerView.open(
          context,
          FolderPickerBundle(
            title: 'Move video',
            confirmVerb: 'Move',
            onConfirm: (destination) => ctrl.moveVideo(video.id, destination),
          ),
        );
      case _ItemAction.delete:
        final yes = await _confirmDelete(
          'Delete this video?',
          'It is removed from this folder. It stays on YouTube.',
        );
        if (yes) await ctrl.deleteVideo(video.id);
    }
  }

  void _play(String? startVideoId) {
    PlayerView.open(
      context,
      PlayerBundle(
        folderId: widget.bundle.folderId,
        startVideoId: startVideoId,
      ),
    );
  }

  Widget _menu(void Function(_ItemAction) onSelected) {
    return PopupMenuButton<_ItemAction>(
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(value: _ItemAction.rename, child: Text('Rename')),
        PopupMenuItem(value: _ItemAction.move, child: Text('Move')),
        PopupMenuItem(value: _ItemAction.delete, child: Text('Delete')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ObxMulti(
      listenables: [ctrl.browser.state, ctrl.actionState],
      builder: () {
        final busy = ctrl.actionState.value.isLoading;
        final browser = ctrl.browser.state.value;
        final title =
            browser is ViewStateLoaded<FolderBrowserData> &&
                browser.data.path.isNotEmpty
            ? browser.data.path.last.name
            : 'Library';

        return PopScope(
          canPop: !busy,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              bottom: busy
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(2),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : null,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: busy
                  ? null
                  : () => NewFolderView.open(
                      context,
                      NewFolderBundle(parentId: widget.bundle.folderId),
                    ),
              tooltip: 'New folder',
              child: const Icon(Icons.add),
            ),
            body: AbsorbPointer(
              absorbing: busy,
              child: browser.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (failure) => Center(child: Text(messageFor(failure))),
                loaded: _body,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(FolderBrowserData data) {
    final contents = data.contents;

    if (contents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nothing here yet.\nShare a video from YouTube to save it, or tap + to add a folder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        if (data.path.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Breadcrumb(path: data.path),
          ),
        if (contents.videos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _play(null),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play all'),
              ),
            ),
          ),
        for (final folder in contents.folders)
          FolderTile(
            folder: folder,
            onTap: () =>
                LibraryView.open(context, LibraryBundle(folderId: folder.id)),
            trailing: _menu((a) => _onFolderAction(folder, a)),
          ),
        for (final video in contents.videos)
          VideoTile(
            video: video,
            onTap: () => _play(video.id),
            trailing: _menu((a) => _onVideoAction(video, a)),
          ),
      ],
    );
  }
}
