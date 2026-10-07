import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';
import 'package:youtube_saver/features/shared/widgets/pill_button.dart';

/// The mockup's `.dialog`: 20px corners, 1px line border, 16px title, pill buttons.
class AppDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.title,
    this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Dialog(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
            const SizedBox(height: 16),
            if (content != null) ...[content!, const SizedBox(height: 20)],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions[i],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The mockup's `.field`: bare text with a 2px accent underline.
class UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? hint;
  final ValueChanged<String>? onSubmitted;

  const UnderlineField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.hint,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.accent, width: 2)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        autofocus: true,
        cursorColor: c.accent,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        style: TextStyle(fontSize: 14, height: 1.4, color: c.text),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: TextStyle(color: c.muted),
        ),
      ),
    );
  }
}

/// A two-button confirmation in the same style.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AppDialog(
      title: title,
      content: Text(
        body,
        style: TextStyle(fontSize: 14, height: 1.4, color: context.colors.text),
      ),
      actions: [
        PillButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        PillButton(
          label: confirmLabel,
          primary: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return yes ?? false;
}
