import 'package:flutter/material.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';

/// "Library › Music › Rock". With [onTap], the segments can be tapped to jump
/// to that folder (null = library root).
class Breadcrumb extends StatelessWidget {
  final List<FolderModel> path;
  final ValueChanged<String?>? onTap;

  const Breadcrumb({super.key, required this.path, this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: muted);

    Widget segment(String text, String? folderId) => InkWell(
      onTap: onTap == null ? null : () => onTap!(folderId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text, style: style),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          segment('Library', null),
          for (final folder in path) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('›', style: style),
            ),
            segment(folder.name, folder.id),
          ],
        ],
      ),
    );
  }
}
