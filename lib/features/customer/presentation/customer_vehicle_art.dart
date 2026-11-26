import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/core/widgets/crisp_components.dart';
import 'package:flutter/material.dart';

class CustomerVehicleArt extends StatelessWidget {
  const CustomerVehicleArt({
    super.key,
    this.form = false,
    this.height = 104,
    this.kind,
  });

  final bool form;
  final double height;
  final VehicleKind? kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          UniversalVehicleThumb(
            kind: (kind ?? VehicleKind.motorcycle).name,
            size: height > 90 ? 60 : 48,
            darkSurface: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form ? 'Data Kendaraan' : 'Garasi Kendaraan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  form
                      ? 'Lengkapi jenis, merek-model, dan nomor polisi.'
                      : 'Kelola motor & mobil Anda untuk booking servis lebih cepat.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
