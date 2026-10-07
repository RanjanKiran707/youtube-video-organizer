import 'package:flutter/material.dart';
import 'package:youtube_saver/features/shared/widgets/app_dialog.dart';
import 'package:youtube_saver/features/shared/widgets/pill_button.dart';

/// Asks for one line of text. Returns the entered text, or null if cancelled.
/// Used for the rename actions; the ViewModel validates the text.
class TextInputDialog extends StatefulWidget {
  final String title;
  final String initialText;
  final String confirmLabel;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.initialText,
    this.confirmLabel = 'Save',
  });

  static Future<String?> open(
    BuildContext context, {
    required String title,
    required String initialText,
    String confirmLabel = 'Save',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: title,
        initialText: initialText,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      content: UnderlineField(
        controller: _controller,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        PillButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        PillButton(
          label: widget.confirmLabel,
          primary: true,
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}
