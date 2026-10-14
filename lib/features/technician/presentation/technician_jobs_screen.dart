import '../../../app/router/app_router.dart';
import '../../../core/widgets/mobile_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/data/mock_workshop_data.dart';

class TechnicianJobsScreen extends ConsumerWidget {
  const TechnicianJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(authSessionProvider).role?.name == 'admin';
    return Scaffold(
      bottomNavigationBar: MobileNavigation(
        role: admin ? 'admin' : 'technician',
      ),
      appBar: AppBar(
        title: Text(admin ? 'Teknisi (Demo)' : 'Pekerjaan (Demo)'),
        leading: IconButton(
          onPressed: () =>
              context.go(admin ? '/admin/home' : '/technician/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: MockWorkshopData.jobs.length,
          itemBuilder: (context, index) {
            final job = MockWorkshopData.jobs[index];
            final chipColor = switch (job.status) {
              'Menunggu' => AppColors.warning,
              'Sedang Dikerjakan' => AppColors.primary,
              _ => AppColors.success,
            };

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('${job.id} • ${job.vehicleName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(job.plateNumber),
                    Text(job.status, style: TextStyle(color: chipColor)),
                    Text('Mulai: ${job.startTime} • ${job.assignee}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
