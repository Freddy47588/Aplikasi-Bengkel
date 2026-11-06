import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/workshop_ui.dart';

class TechnicianFormIntro extends StatelessWidget {
  const TechnicianFormIntro({
    super.key,
    required this.art,
    required this.description,
    this.height = 128,
  });
  final WorkshopArt art;
  final String description;
  final double height;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
        WorkshopIllustration(art, height: height),
        const SizedBox(height: 12),
      ],
      Text(
        description,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.primary),
      ),
      const SizedBox(height: 18),
    ],
  );
}

class TaskVehicleCard extends StatelessWidget {
  const TaskVehicleCard({super.key, required this.order, this.onTap});
  final ServiceOrder order;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.blueBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.directions_car_outlined,
              color: AppColors.secondary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.text('vehiclePlate'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(order.text('vehicleName')),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class TaskSummaryCard extends StatelessWidget {
  const TaskSummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.blueBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...children,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String inspectionDescription(String key) => switch (key) {
  'vehicleChecked' => 'Periksa kondisi kendaraan sesuai keluhan servis.',
  'safetyChecked' => 'Pastikan pemeriksaan keselamatan sudah dilakukan.',
  _ => 'Periksa kembali hasil pekerjaan sebelum pengajuan.',
};
