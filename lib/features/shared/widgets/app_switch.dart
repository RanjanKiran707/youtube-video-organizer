import 'package:flutter/material.dart';
import 'package:youtube_saver/core/theme/app_colors.dart';

/// The mockup's `.toggle`: 36x20, accent track with a 16px knob.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 20,
          padding: const EdgeInsets.all(2),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? c.accent : c.line,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value ? c.onAccent : c.muted,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
