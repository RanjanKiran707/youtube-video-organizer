import 'package:flutter/material.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';

/// "2 videos · 1 folder", or "Empty".
String countLabel(int videoCount, int folderCount) {
  final parts = [
    if (videoCount > 0) '$videoCount ${videoCount == 1 ? 'video' : 'videos'}',
    if (folderCount > 0)
      '$folderCount ${folderCount == 1 ? 'folder' : 'folders'}',
  ];
  return parts.isEmpty ? 'Empty' : parts.join(' · ');
}

class FolderTile extends StatelessWidget {
  final FolderItem folder;
  final VoidCallback onTap;
  final Widget? trailing;

  const FolderTile({
    super.key,
    required this.folder,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.folder_outlined, color: scheme.onSurfaceVariant),
      ),
      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(countLabel(folder.videoCount, folder.folderCount)),
      trailing: trailing,
    );
  }
}
