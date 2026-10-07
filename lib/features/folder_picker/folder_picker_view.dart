import 'package:flutter/material.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/core/widgets/obx_value.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view_model.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view_model.dart';
import 'package:youtube_saver/features/shared/failure_message.dart';
import 'package:youtube_saver/features/shared/folder_browser_controller.dart';
import 'package:youtube_saver/features/shared/widgets/breadcrumb.dart';
import 'package:youtube_saver/features/shared/widgets/folder_tile.dart';
import 'package:youtube_saver/features/shared/widgets/video_thumbnail.dart';

class FolderPickerView extends StatefulWidget {
  final FolderPickerBundle bundle;
  const FolderPickerView({super.key, required this.bundle});

  /// Resolves to true when the action was confirmed and succeeded.
  static Future<bool?> open(BuildContext context, FolderPickerBundle bundle) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FolderPickerView(bundle: bundle),
      ),
    );
  }

  @override
  State<FolderPickerView> createState() => _FolderPickerViewState();
}

class _FolderPickerViewState extends State<FolderPickerView> {
  late final FolderPickerViewModel ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = FolderPickerViewModel(
      bundle: widget.bundle,
      listFolderContents: AppDependencies.instance.listFolderContents,
      getFolderPath: AppDependencies.instance.getFolderPath,
    );
    ctrl.confirmState.addListener(_onConfirmStateChanged);
  }

  void _onConfirmStateChanged() {
    if (ctrl.confirmState.value is ViewStateLoaded && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    ctrl.confirmState.removeListener(_onConfirmStateChanged);
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _newFolder() async {
    await NewFolderView.open(
      context,
      NewFolderBundle(parentId: ctrl.browser.folderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = widget.bundle;

    return ObxMulti(
      listenables: [ctrl.browser.state, ctrl.confirmState],
      builder: () {
        final busy = ctrl.confirmState.value.isLoading;
        final browser = ctrl.browser.state.value;
        final loaded = browser is ViewStateLoaded<FolderBrowserData>;
        final destination = loaded && browser.data.path.isNotEmpty
            ? browser.data.path.last.name
            : 'Library';

        return PopScope(
          // Back goes up a folder; at the root it closes. Blocked while saving.
          canPop: !busy && ctrl.atRoot,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) ctrl.up();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(bundle.title),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: busy ? null : () => Navigator.pop(context, false),
              ),
            ),
            body: Column(
              children: [
                if (bundle.previewThumbnailUrl != null)
                  _Preview(
                    thumbnailUrl: bundle.previewThumbnailUrl!,
                    text: bundle.previewText,
                  ),
                if (loaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Breadcrumb(
                        path: browser.data.path,
                        onTap: busy ? null : ctrl.open,
                      ),
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: browser.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (failure) =>
                        Center(child: Text(messageFor(failure))),
                    loaded: (data) {
                      final folders = data.contents.folders
                          .where((f) => f.id != bundle.excludeFolderId)
                          .toList();
                      if (folders.isEmpty) {
                        return const Center(
                          child: Text('No folders here yet.'),
                        );
                      }
                      return ListView(
                        children: [
                          for (final folder in folders)
                            FolderTile(
                              folder: folder,
                              onTap: busy ? () {} : () => ctrl.open(folder.id),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                ctrl.confirmState.value.when(
                  idle: () => const SizedBox.shrink(),
                  loading: () => const LinearProgressIndicator(),
                  loaded: (_) => const SizedBox.shrink(),
                  error: (failure) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      messageFor(failure),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: busy || !loaded ? null : _newFolder,
                          icon: const Icon(Icons.create_new_folder_outlined),
                          label: const Text('New folder'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: busy || !loaded ? null : ctrl.confirm,
                            child: Text(
                              '${bundle.confirmVerb} to $destination',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  final String thumbnailUrl;
  final String? text;

  const _Preview({required this.thumbnailUrl, this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          VideoThumbnail(url: thumbnailUrl, width: 96, height: 54),
          const SizedBox(width: 12),
          if (text != null)
            Expanded(
              child: Text(text!, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
