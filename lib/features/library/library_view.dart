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
import 'package:youtube_saver/features/shared/widgets/app_dialog.dart';
import 'package:youtube_saver/features/shared/widgets/app_row.dart';
import 'package:youtube_saver/features/shared/widgets/breadcrumb.dart';
import 'package:youtube_saver/features/shared/widgets/folder_tile.dart';
import 'package:youtube_saver/features/shared/widgets/pill_button.dart';
import 'package:youtube_saver/features/shared/widgets/screen_parts.dart';
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
            title: 'Move to…',
            confirmVerb: 'Move',
            excludeFolderId: folder.id,
            onConfirm: (destination) => ctrl.moveFolder(folder.id, destination),
          ),
        );
      case _ItemAction.delete:
        final yes = await confirmDialog(
          context,
          title: 'Delete "${folder.name}"?',
          body:
              'The folder, its subfolders and all their videos are removed from the app. The videos stay on YouTube.',
          confirmLabel: 'Delete',
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
            title: 'Move to…',
            confirmVerb: 'Move',
            onConfirm: (destination) => ctrl.moveVideo(video.id, destination),
          ),
        );
      case _ItemAction.delete:
        final yes = await confirmDialog(
          context,
          title: 'Delete this video?',
          body: 'It is removed from this folder. It stays on YouTube.',
          confirmLabel: 'Delete',
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
      padding: EdgeInsets.zero,
      tooltip: 'More',
      itemBuilder: (_) => const [
        PopupMenuItem(value: _ItemAction.rename, child: Text('Rename')),
        PopupMenuItem(value: _ItemAction.move, child: Text('Move')),
        PopupMenuItem(value: _ItemAction.delete, child: Text('Delete')),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: MoreDots(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ObxMulti(
      listenables: [ctrl.browser.state, ctrl.actionState],
      builder: () {
        final busy = ctrl.actionState.value.isLoading;
        final browser = ctrl.browser.state.value;

        return PopScope(
          canPop: !busy,
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  AbsorbPointer(
                    absorbing: busy,
                    child: browser.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (failure) =>
                          Center(child: Text(messageFor(failure))),
                      loaded: _content,
                    ),
                  ),
                  if (busy)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  Positioned(
                    right: 20,
                    bottom: 24,
                    child: AppFab(
                      onPressed: busy
                          ? null
                          : () => NewFolderView.open(
                              context,
                              NewFolderBundle(parentId: widget.bundle.folderId),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(FolderBrowserData data) {
    final contents = data.contents;
    final inFolder = data.path.isNotEmpty;

    final header = ScreenHeader(
      title: inFolder ? data.path.last.name : 'Library',
      crumb: inFolder
          ? Breadcrumb(path: data.path.sublist(0, data.path.length - 1))
          : null,
      actions: contents.videos.isEmpty
          ? null
          : Row(
              children: [
                PillButton(
                  label: 'Play all',
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  onPressed: () => _play(null),
                ),
              ],
            ),
    );

    if (contents.isEmpty) {
      return Column(
        children: [
          header,
          const Expanded(
            child: EmptyState(
              heading: 'Nothing here yet',
              text:
                  'Share a video from YouTube and pick this folder to save it.',
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        header,
        ...dividedRows(context, [
          for (final folder in contents.folders)
            FolderTile(
              folder: folder,
              onTap: () =>
                  LibraryView.open(context, LibraryBundle(folderId: folder.id)),
              trailing: _menu((a) => _onFolderAction(folder, a)),
            ),
        ]),
        if (contents.videos.isNotEmpty) ...[
          SectionLabel(
            inFolder ? 'Videos · ${contents.videos.length}' : 'Videos',
          ),
          ...dividedRows(context, [
            for (final video in contents.videos)
              VideoTile(
                video: video,
                onTap: () => _play(video.id),
                trailing: _menu((a) => _onVideoAction(video, a)),
              ),
          ]),
        ],
      ],
    );
  }
}
