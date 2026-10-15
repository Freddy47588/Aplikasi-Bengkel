import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../core/data/firebase_providers.dart';
import '../../../core/data/service_repository.dart';
import '../../../core/data/service_history_repository.dart';
import '../../../core/data/service_order_repository.dart';
import '../../../core/models/service_history.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/service_timeline.dart';
import '../../technician/presentation/service_orders_screen.dart';

// Include archived vehicles: soft deletion must not hide their history.
final historyVehiclesProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider);
  if (!session.isAuthenticated || session.role?.name != 'customer') {
    return Stream.value(<String, String>{});
  }
  return ref
      .watch(firestoreProvider)
      .collection('vehicles')
      .where('ownerId', isEqualTo: session.userId)
      .limit(50)
      .snapshots()
      .map(
        (s) => {for (final d in s.docs) d.id: '${d['name']} • ${d['plate']}'},
      );
});

class ServiceHistoryScreen extends ConsumerStatefulWidget {
  const ServiceHistoryScreen({super.key});
  @override
  ConsumerState<ServiceHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<ServiceHistoryScreen> {
  final vehicle = TextEditingController(), service = TextEditingController();
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  String vehicleId = '', serviceId = '';
  DateTimeRange? period;
  @override
  void dispose() {
    vehicle.dispose();
    service.dispose();
    super.dispose();
  }

  void resetPages() {
    cursors
      ..clear()
      ..add(null);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final role = session.role!.name;
    final filter = HistoryFilter(
      vehicleId: vehicleId,
      serviceId: serviceId,
      from: period == null ? null : wibDay(period!.start),
      until: period == null
          ? null
          : wibDay(period!.end).add(const Duration(days: 1)),
      cursor: cursors.last,
    );
    final provider = historyPageProvider(filter);
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Servis')),
      bottomNavigationBar: MobileNavigation(role: role),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Riwayat dari Service Order selesai. Tanggal menggunakan WIB.',
            ),
            if (role == 'customer')
              ref
                  .watch(historyVehiclesProvider)
                  .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => TextButton(
                      onPressed: () => ref.invalidate(historyVehiclesProvider),
                      child: const Text('Gagal memuat kendaraan. Coba lagi'),
                    ),
                    data: (vehicles) => Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in vehicles.entries)
                          ActionChip(
                            label: Text(entry.value),
                            onPressed: () => setState(() {
                              vehicle.text = entry.key;
                              vehicleId = entry.key;
                              resetPages();
                            }),
                          ),
                      ],
                    ),
                  ),
            TextField(
              controller: vehicle,
              decoration: const InputDecoration(
                labelText: 'ID kendaraan',
                helperText: 'Kosong = semua kendaraan; ID ada di detail.',
              ),
            ),
            ref
                .watch(servicesProvider)
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => TextButton(
                    onPressed: () => ref.invalidate(servicesProvider),
                    child: const Text('Gagal memuat jenis servis. Coba lagi'),
                  ),
                  data: (services) => Wrap(
                    spacing: 8,
                    children: [
                      for (final item in services)
                        ActionChip(
                          label: Text(item.name),
                          onPressed: () => setState(() {
                            service.text = item.id;
                            serviceId = item.id;
                            resetPages();
                          }),
                        ),
                    ],
                  ),
                ),
            TextField(
              controller: service,
              decoration: const InputDecoration(
                labelText: 'ID jenis servis',
                helperText: 'Kosong = semua jenis; ID ada di detail.',
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final today = DateTime.now().toUtc().add(
                      const Duration(hours: 7),
                    );
                    final selected = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(today.year, today.month, today.day),
                      initialDateRange: period,
                    );
                    if (selected != null && mounted) {
                      setState(() {
                        period = selected;
                        resetPages();
                      });
                    }
                  },
                  child: Text(
                    period == null
                        ? 'Pilih periode'
                        : '${period!.start.day}/${period!.start.month}/${period!.start.year} – '
                              '${period!.end.day}/${period!.end.month}/${period!.end.year}',
                  ),
                ),
                FilledButton(
                  onPressed: () => setState(() {
                    vehicleId = vehicle.text.trim();
                    serviceId = service.text.trim();
                    resetPages();
                  }),
                  child: const Text('Terapkan filter'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    vehicle.clear();
                    service.clear();
                    vehicleId = '';
                    serviceId = '';
                    period = null;
                    resetPages();
                  }),
                  child: const Text('Reset filter'),
                ),
              ],
            ),
            ref
                .watch(provider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Column(
                    children: [
                      const Text(
                        'Riwayat gagal dimuat. Periksa koneksi dan akses akun.',
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(provider),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (page.fromCache)
                        const Text(
                          'Offline/cache: data mungkin belum lengkap. Sambungkan internet untuk memperbarui.',
                        ),
                      if (page.items.isEmpty)
                        Text(
                          page.fromCache
                              ? 'Belum ada riwayat dalam cache untuk filter ini.'
                              : 'Belum ada servis selesai untuk filter ini.',
                        ),
                      for (final order in page.items)
                        Card(
                          child: ListTile(
                            title: Text(
                              '${order.text('vehicleName')} • ${order.text('vehiclePlate')}',
                            ),
                            subtitle: Text(
                              '${order.text('serviceName')}\nSelesai: ${historyDate(order.date('completedAt'))}',
                            ),
                            onTap: () =>
                                context.go('/$role/history/${order.id}'),
                          ),
                        ),
                      PageButtons(
                        page: cursors.length,
                        hasMore: page.hasMore && !page.fromCache,
                        previous: () => setState(() => cursors.removeLast()),
                        next: () => setState(() => cursors.add(page.cursor)),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class ServiceHistoryDetailScreen extends ConsumerWidget {
  const ServiceHistoryDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final role = session.role!.name;
    final provider = serviceOrderProvider(id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Riwayat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/$role/history'),
        ),
      ),
      bottomNavigationBar: MobileNavigation(role: role),
      body: SafeArea(
        child: ref
            .watch(provider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  RetryLoad(onRetry: () => ref.invalidate(provider)),
              data: (order) {
                if (order == null ||
                    order.status.name != 'completed' ||
                    (role == 'customer' &&
                        order.text('customerId') != session.userId) ||
                    (role == 'technician' &&
                        order.technicianId != session.userId)) {
                  return const Center(
                    child: Text('Riwayat servis selesai tidak tersedia.'),
                  );
                }
                final labor = order.data['laborPrice'] as int?;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Booking ID: ${order.text('bookingId')}'),
                    Text('SO ID: ${order.id}'),
                    Text(
                      'Kendaraan: ${order.text('vehicleName')} • ${order.text('vehiclePlate')}',
                    ),
                    Text('ID kendaraan: ${order.text('vehicleId')}'),
                    Text('Jasa: ${order.text('serviceName')}'),
                    Text('ID jenis servis: ${order.text('serviceId')}'),
                    Text('Keluhan: ${order.text('complaint')}'),
                    Text('Diagnosis: ${order.text('diagnosis')}'),
                    Text('Tindakan: ${order.text('actions')}'),
                    Text(
                      'Teknisi: ${order.text('technicianName').isEmpty ? order.technicianId ?? 'Tidak tercatat' : order.text('technicianName')}',
                    ),
                    Text('Selesai: ${historyDate(order.date('completedAt'))}'),
                    Text(
                      'Snapshot biaya jasa: ${labor == null ? 'Tidak tercatat pada data lama' : rupiah(labor)}',
                    ),
                    const Text('Status pembayaran: Belum dicatat.'),
                    const SizedBox(height: 16),
                    ServiceTimeline(order: order),
                    const SizedBox(height: 16),
                    ref
                        .watch(historyPartsProvider(id))
                        .when(
                          loading: () => const Column(
                            children: [
                              LinearProgressIndicator(),
                              Text('Memuat seluruh snapshot sparepart…'),
                            ],
                          ),
                          error: (_, _) => TextButton(
                            onPressed: () =>
                                ref.invalidate(historyPartsProvider(id)),
                            child: const Text(
                              'Gagal memuat biaya dan sparepart. Coba lagi',
                            ),
                          ),
                          data: (parts) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (parts.fromCache)
                                const Text(
                                  'Offline/cache: rincian dan biaya mungkin belum lengkap.',
                                ),
                              if (parts.lines.isEmpty)
                                const Text('Tidak ada sparepart tercatat.'),
                              for (final line in parts.lines)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    '${line['name']} (${line['sku']})\n'
                                    '${line['kind'] == 'reversal' ? 'Reversal −' : ''}${line['quantity']} ${line['unit']} × '
                                    '${rupiah(line['sellPrice'] as int)} (snapshot)',
                                  ),
                                ),
                              Text(
                                'Subtotal sparepart${parts.fromCache ? ' dalam cache' : ''}: ${rupiah(parts.subtotal)}',
                              ),
                              if (labor != null && !parts.fromCache)
                                Text(
                                  'Total biaya: ${rupiah(labor + parts.subtotal)}',
                                ),
                              if (labor == null)
                                const Text(
                                  'Total biaya belum dapat dihitung: snapshot jasa lama tidak tersedia.',
                                ),
                            ],
                          ),
                        ),
                  ],
                );
              },
            ),
      ),
    );
  }
}
