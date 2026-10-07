import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';
import 'package:youtube_saver/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';
import 'package:youtube_saver/features/shared/widgets/app_icon.dart';
import 'package:youtube_saver/features/shared/widgets/app_row.dart';

/// "2 videos · 1 folder", or "Empty".
String countLabel(int videoCount, int folderCount) {
  final parts = [
    if (videoCount > 0) '$videoCount ${videoCount == 1 ? 'video' : 'videos'}',
    if (folderCount > 0)
      '$folderCount ${folderCount == 1 ? 'folder' : 'folders'}',
  ];
  return parts.isEmpty ? 'Empty' : parts.join(' · ');
}

/// The mockup's `.ico`: a 40px rounded tile holding a line icon.
class IconTile extends StatelessWidget {
  final AppIconData icon;
  const IconTile(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: AppIcon(icon, color: c.muted)),
    );
  }
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
    return AppRow(
      onTap: onTap,
      leading: const IconTile(AppIconData.folder),
      title: folder.name,
      subtitle: countLabel(folder.videoCount, folder.folderCount),
      trailing: trailing,
    );
  }
}
