import 'package:flutter/material.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/utils/view_state.dart';
import 'package:youtube_saver/core/widgets/obx_value.dart';
import 'package:youtube_saver/features/new_folder/new_folder_view_model.dart';
import 'package:youtube_saver/features/shared/failure_message.dart';

/// The "New folder" dialog. Resolves to true when a folder was created.
class NewFolderView extends StatefulWidget {
  final NewFolderBundle bundle;
  const NewFolderView({super.key, required this.bundle});

  static Future<bool?> open(BuildContext context, NewFolderBundle bundle) {
    return showDialog<bool>(
      context: context,
      builder: (_) => NewFolderView(bundle: bundle),
    );
  }

  @override
  State<NewFolderView> createState() => _NewFolderViewState();
}

class _NewFolderViewState extends State<NewFolderView> {
  late final NewFolderViewModel ctrl;
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ctrl = NewFolderViewModel(
      bundle: widget.bundle,
      createFolder: AppDependencies.instance.createFolder,
    );
    ctrl.createState.addListener(_onCreateStateChanged);
  }

  void _onCreateStateChanged() {
    if (ctrl.createState.value is ViewStateLoaded && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    ctrl.createState.removeListener(_onCreateStateChanged);
    nameController.dispose();
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue<ViewState<void>>(
      listenable: ctrl.createState,
      builder: (state) {
        final busy = state.isLoading;

        return PopScope(
          canPop: !busy, // blocks back button and tapping outside while saving
          child: AlertDialog(
            title: const Text('New folder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !busy,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => ctrl.onCreate(nameController.text),
                  decoration: const InputDecoration(hintText: 'Folder name'),
                ),
                state.when(
                  idle: () => const SizedBox.shrink(),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                  loaded: (_) => const SizedBox.shrink(),
                  error: (failure) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      messageFor(failure),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => ctrl.onCreate(nameController.text),
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }
}
