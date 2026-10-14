import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/data/mock_workshop_data.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
        leading: IconButton(
          onPressed: () => context.go('/admin/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: MockWorkshopData.bookings.length,
          itemBuilder: (context, index) {
            final booking = MockWorkshopData.bookings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                ),
                title: Text('${booking.id} • ${booking.vehicleName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${booking.customerName} • ${booking.serviceType}'),
                    Text('${booking.date} • ${booking.time}'),
                  ],
                ),
                trailing: Chip(label: Text(booking.status)),
              ),
            );
          },
        ),
      ),
    );
  }
}
