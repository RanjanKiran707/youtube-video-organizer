import 'package:flutter/material.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/core/widgets/obx_value.dart';
import 'package:youtube_saver/features/folder_picker/folder_picker_view_model.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view_model.dart';
import 'package:youtube_saver/features/shared/failure_message.dart';
import 'package:youtube_saver/features/shared/folder_browser_controller.dart';
import 'package:youtube_saver/features/shared/widgets/app_icon.dart';
import 'package:youtube_saver/features/shared/widgets/app_row.dart';
import 'package:youtube_saver/features/shared/widgets/breadcrumb.dart';
import 'package:youtube_saver/features/shared/widgets/folder_tile.dart';
import 'package:youtube_saver/features/shared/widgets/pill_button.dart';
import 'package:youtube_saver/features/shared/widgets/video_thumbnail.dart';

/// The bottom sheet of the mockup ("Save to…"): shared video, breadcrumb,
/// folder list, "New folder" row and the full-width save button.
class FolderPickerView extends StatefulWidget {
  final FolderPickerBundle bundle;
  const FolderPickerView({super.key, required this.bundle});

  /// The sheet as a route, so it can be pushed from any navigator.
  static Route<bool> route(FolderPickerBundle bundle) {
    return PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x73000000),
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => FolderPickerView(bundle: bundle),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }

  /// Resolves to true when the action was confirmed and succeeded.
  static Future<bool?> open(BuildContext context, FolderPickerBundle bundle) {
    return Navigator.push<bool>(context, route(bundle));
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
    final c = context.colors;
    final height = MediaQuery.sizeOf(context).height;

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
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: height * 0.83,
                width: double.infinity,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          bundle.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                      ),
                    ),
                    if (bundle.previewThumbnailUrl != null)
                      _SharedCard(
                        thumbnailUrl: bundle.previewThumbnailUrl!,
                        text: bundle.previewText,
                      ),
                    if (loaded)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Breadcrumb(
                            path: browser.data.path,
                            onTap: busy ? null : ctrl.open,
                          ),
                        ),
                      ),
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
                          return ListView(
                            children: dividedRows(context, [
                              for (final folder in folders)
                                AppRow(
                                  onTap: busy
                                      ? null
                                      : () => ctrl.open(folder.id),
                                  leading: const IconTile(AppIconData.folder),
                                  title: folder.name,
                                  trailing: const RowGlyph('›'),
                                ),
                              AppRow(
                                link: true,
                                onTap: busy ? null : _newFolder,
                                leading: const IconTile(AppIconData.folderPlus),
                                title: 'New folder',
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                    ctrl.confirmState.value.when(
                      idle: () => const SizedBox.shrink(),
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      loaded: (_) => const SizedBox.shrink(),
                      error: (failure) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Text(
                          messageFor(failure),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: c.accent,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.line)),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        20 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: PillButton(
                        label: '${bundle.confirmVerb} to $destination',
                        primary: true,
                        block: true,
                        onPressed: busy || !loaded ? null : ctrl.confirm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The mockup's `.shared`: the video being saved, on a surface card.
class _SharedCard extends StatelessWidget {
  final String thumbnailUrl;
  final String? text;

  const _SharedCard({required this.thumbnailUrl, this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          VideoThumbnail(url: thumbnailUrl, width: 96, height: 54),
          const SizedBox(width: 12),
          if (text != null)
            Expanded(
              child: Text(
                text!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: c.text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
