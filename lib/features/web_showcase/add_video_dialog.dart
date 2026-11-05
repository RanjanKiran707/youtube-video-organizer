import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_saver/core/di/app_dependencies.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/save_shared_video_argument_model.dart';
import 'package:youtube_saver/domain/use_cases/business/save_shared_video/youtube_url_parser.dart';
import 'package:youtube_saver/features/shared/failure_message.dart';
import 'package:youtube_saver/features/shared/widgets/app_dialog.dart';
import 'package:youtube_saver/features/shared/widgets/pill_button.dart';

class AddVideoDialog extends StatefulWidget {
  final String? folderId;

  const AddVideoDialog({super.key, this.folderId});

  static Future<bool?> open(BuildContext context, {String? folderId}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AddVideoDialog(folderId: folderId),
    );
  }

  @override
  State<AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<AddVideoDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      setState(() {
        _controller.text = data!.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a YouTube link or ID.');
      return;
    }

    final youtubeId = parseYoutubeVideoId(text);
    if (youtubeId == null) {
      setState(() => _errorMessage = 'Invalid YouTube URL or ID.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AppDependencies.instance.saveSharedVideo(
      SaveSharedVideoArgumentModel(
        videoId: const Uuid().v4(),
        sharedText: text,
        folderId: widget.folderId,
      ),
    );

    if (!mounted) return;

    if (result is Err) {
      setState(() {
        _loading = false;
        _errorMessage = messageFor(result.failure);
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppDialog(
      title: 'Add YouTube video',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste a YouTube link or ID to save it to this folder.',
            style: TextStyle(fontSize: 13, color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _errorMessage != null ? c.accent : c.line,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !_loading,
                    style: TextStyle(fontSize: 14, color: c.text),
                    decoration: InputDecoration(
                      hintText: 'https://youtube.com/watch?v=...',
                      hintStyle: TextStyle(fontSize: 13, color: c.muted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Paste from clipboard',
                  icon: Icon(Icons.paste_rounded, size: 18, color: c.muted),
                  onPressed: _loading ? null : _pasteFromClipboard,
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 12, color: c.accent),
            ),
          ],
          if (_loading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Fetching video metadata...',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        PillButton(
          label: 'Cancel',
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
        PillButton(
          label: 'Save',
          primary: true,
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }
}
