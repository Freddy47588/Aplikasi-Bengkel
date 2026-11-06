import 'package:flutter/material.dart';

class CustomerVehicleArt extends StatelessWidget {
  const CustomerVehicleArt({super.key, this.form = false, this.height = 128});
  final bool form;
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      form
          ? 'assets/illustrations/customer-vehicle-form-reference.png'
          : 'assets/illustrations/customer-vehicles-reference.png',
      width: double.infinity,
      height: height,
      fit: BoxFit.contain,
      cacheWidth:
          (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(1, 1024)
              .toInt(),
    ),
  );
}
