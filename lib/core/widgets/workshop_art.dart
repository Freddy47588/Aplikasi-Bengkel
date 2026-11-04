import 'package:flutter/material.dart';

enum WorkshopArt {
  vehicles,
  garage,
  technician,
  booking,
  checklist,
  spareparts,
  oil,
  verification,
  password,
  report,
  completion,
  ledger,
  lock;

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
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/illustrations/wave.png',
      height: 32,
      width: double.infinity,
      fit: BoxFit.fill,
      cacheHeight: (32 * MediaQuery.devicePixelRatioOf(context)).ceil(),
    ),
  );
}
