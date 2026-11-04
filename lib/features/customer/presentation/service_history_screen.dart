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
import '../../../core/models/service_order.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/service_timeline.dart';
import '../../../core/widgets/workshop_ui.dart';
import '../../../core/widgets/history_payment_summary.dart';
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
  String vehicleLabel = '', serviceLabel = '';
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  String vehicleId = '', serviceId = '';
  DateTimeRange? period;
  void resetPages() {
    cursors
      ..clear()
      ..add(null);
  }

  Widget vehiclePicker(
    Map<String, String> vehicles, {
    bool currentPage = false,
  }) {
    final choices = {'': 'Semua kendaraan', ...vehicles};
    if (vehicleId.isNotEmpty && !choices.containsKey(vehicleId)) {
      choices[vehicleId] = vehicleLabel;
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('vehicle-$vehicleId'),
      initialValue: vehicleId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Kendaraan',
        helperText: currentPage
            ? 'Pilihan dari kendaraan pada halaman ini.'
            : 'Termasuk kendaraan yang sudah diarsipkan.',
      ),
      items: [
        for (final entry in choices.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (value) => setState(() {
        vehicleId = value ?? '';
        vehicleLabel = choices[vehicleId] ?? '';
        resetPages();
      }),
    );
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
      body: WorkshopBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          children: [
            WorkspaceLinks(role: role),
            const SizedBox(height: 16),
            const Text(
              'Riwayat dari Service Order selesai. Tanggal menggunakan WIB.',
            ),
            const SizedBox(height: 16),
            if (role == 'customer')
              ref
                  .watch(historyVehiclesProvider)
                  .when(
                    loading: () => const LoadingState(),
                    error: (_, _) => LoadError(
                      onRetry: () => ref.invalidate(historyVehiclesProvider),
                    ),
                    data: (vehicles) => vehiclePicker(vehicles),
                  )
            else
              vehiclePicker({
                for (final o
                    in ref.watch(provider).asData?.value.items ??
                        <ServiceOrder>[])
                  o.text('vehicleId'):
                      '${o.text('vehicleName')} / ${o.text('vehiclePlate')}',
              }, currentPage: true),
            const SizedBox(height: 12),
            ref
                .watch(servicesProvider)
                .when(
                  loading: () => const LoadingState(),
                  error: (_, _) => LoadError(
                    onRetry: () => ref.invalidate(servicesProvider),
                  ),
                  data: (services) {
                    final choices = <String, String>{
                      '': 'Semua jenis servis',
                      for (final order
                          in ref.watch(provider).asData?.value.items ??
                              <ServiceOrder>[])
                        if (order.text('serviceId').isNotEmpty)
                          order.text('serviceId'): order.text('serviceName'),
                      for (final service in services) service.id: service.name,
                    };
                    if (serviceId.isNotEmpty &&
                        !choices.containsKey(serviceId)) {
                      choices[serviceId] = serviceLabel;
                    }
                    return DropdownButtonFormField<String>(
                      key: ValueKey('service-$serviceId'),
                      initialValue: serviceId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Jenis servis',
                        helperText:
                            'Katalog aktif dan jenis servis pada halaman riwayat ini.',
                      ),
                      items: [
                        for (final choice in choices.entries)
                          DropdownMenuItem(
                            value: choice.key,
                            child: Text(choice.value),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        serviceId = value ?? '';
                        serviceLabel = choices[serviceId] ?? '';
                        resetPages();
                      }),
                    );
                  },
                ),
            const SizedBox(height: 12),
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
                    resetPages();
                  }),
                  child: const Text('Terapkan filter'),
                ),
                TextButton(
                  onPressed: () => setState(() {
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
                  loading: () => const LoadingState(),
                  error: (_, _) => LoadError(
                    onRetry: () => ref.invalidate(provider),
                    message:
                        'Riwayat gagal dimuat. Periksa koneksi dan akses akun.',
                  ),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (page.fromCache)
                        const Text(
                          'Offline/cache: data mungkin belum lengkap. Sambungkan internet untuk memperbarui.',
                        ),
                      if (page.items.isEmpty)
                        EmptyState(
                          title: 'Belum ada riwayat servis',
                          description: page.fromCache
                              ? 'Belum ada riwayat dalam cache untuk filter ini.'
                              : 'Belum ada servis selesai untuk filter ini.',
                          icon: Icons.history,
                        ),
                      for (final order in page.items)
                        WorkshopRecordCard(
                          icon: Icons.history,
                          title:
                              '${order.text('vehicleName')} • ${order.text('vehiclePlate')}',
                          description:
                              '${order.text('serviceName')}\nSelesai: ${historyDate(order.date('completedAt'))}',
                          onTap: () => context.go('/$role/history/${order.id}'),
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
      body: WorkshopBody(
        child: ref
            .watch(provider)
            .when(
              loading: () => const LoadingState(),
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const WorkshopIllustration(WorkshopArt.completion),
                    const SizedBox(height: 16),
                    ContentSection(
                      title: 'Kendaraan & layanan',
                      children: [
                        Text(
                          '${order.text('vehicleName')} / ${order.text('vehiclePlate')}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(order.text('serviceName')),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Referensi dokumen'),
                      children: [
                        SelectableText(
                          'Booking ID: ${order.text('bookingId')}',
                        ),
                        SelectableText('SO ID: ${order.id}'),
                        SelectableText(
                          'ID kendaraan: ${order.text('vehicleId')}',
                        ),
                        SelectableText(
                          'ID jenis servis: ${order.text('serviceId')}',
                        ),
                      ],
                    ),
                    ContentSection(
                      title: 'Hasil pemeriksaan & tindakan',
                      children: [
                        Text('Keluhan: ${order.text('complaint')}'),
                        const SizedBox(height: 12),
                        Text('Diagnosis: ${order.text('diagnosis')}'),
                        const SizedBox(height: 12),
                        Text('Tindakan: ${order.text('actions')}'),
                      ],
                    ),
                    Text(
                      'Teknisi: ${order.text('technicianName').isEmpty ? order.technicianId ?? 'Tidak tercatat' : order.text('technicianName')}',
                    ),
                    Text('Selesai: ${historyDate(order.date('completedAt'))}'),
                    Text(
                      'Snapshot biaya jasa: ${labor == null ? 'Tidak tercatat pada data lama' : rupiah(labor)}',
                    ),
                    HistoryPaymentSummary(orderId: order.id),
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
