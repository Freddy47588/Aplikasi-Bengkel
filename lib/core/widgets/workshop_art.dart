import 'package:flutter/material.dart';

enum WorkshopArt {
  technician,
  booking,
  checklist,
  spareparts,
  oil,
  report,
  completion,
  ledger;

  String get asset => 'assets/illustrations/$name.png';
}

class WorkshopIllustration extends StatelessWidget {
  const WorkshopIllustration(this.art, {super.key, this.height = 128});
  final WorkshopArt art;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      art.asset,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      cacheHeight: (height * MediaQuery.devicePixelRatioOf(context)).ceil(),
      filterQuality: FilterQuality.medium,
    ),
  );
}

class WorkshopWave extends StatelessWidget {
  const WorkshopWave({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
