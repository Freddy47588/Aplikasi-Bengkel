import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final heading = Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (actionLabel != null &&
            (constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              TextButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: heading),
            if (actionLabel != null)
              TextButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        );
      },
    );
  }
}
