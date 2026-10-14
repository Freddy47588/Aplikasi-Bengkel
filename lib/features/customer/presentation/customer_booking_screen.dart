import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/data/mock_workshop_data.dart';

class CustomerBookingScreen extends ConsumerWidget {
  const CustomerBookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Servis'),
        leading: IconButton(
          onPressed: () => context.go('/customer/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Booking',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      const _BookingField(
                        label: 'Kendaraan',
                        value: 'Honda Brio RS',
                      ),
                      const _BookingField(
                        label: 'Plat Nomor',
                        value: 'B 1234 XYZ',
                      ),
                      const _BookingField(
                        label: 'Layanan',
                        value: 'Service Berkala',
                      ),
                      const _BookingField(
                        label: 'Tanggal',
                        value: 'Jumat, 25 Oktober 2026',
                      ),
                      const _BookingField(
                        label: 'Waktu',
                        value: '09:30 - 11:00',
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Konfirmasi Booking'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Booking Berikutnya',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...MockWorkshopData.bookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        '${booking.serviceType} • ${booking.vehicleName}',
                      ),
                      subtitle: Text('${booking.date} • ${booking.time}'),
                      trailing: Chip(label: Text(booking.status)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingField extends StatelessWidget {
  const _BookingField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
