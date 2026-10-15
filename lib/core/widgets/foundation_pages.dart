import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../data/booking_repository.dart';
import '../models/booking.dart';
import '../data/service_order_repository.dart';
import 'empty_state.dart';
import 'mobile_navigation.dart';
import 'logout_button.dart';

String bookingSchedule(DateTime value) {
  final date = value.isUtc ? value.add(const Duration(hours: 7)) : value;
  return '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:00 WIB';
}

class FoundationPage extends ConsumerWidget {
  const FoundationPage({
    super.key,
    required this.title,
    required this.description,
  });
  final String title;
  final String description;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: session.role == null
          ? null
          : MobileNavigation(role: session.role!.name),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            EmptyState(title: title, description: description),
            const SizedBox(height: 16),
            const LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class BookingListPage extends StatelessWidget {
  const BookingListPage({super.key, required this.customer});
  final bool customer;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(customer ? 'Booking Saya' : 'Admin Booking')),
    bottomNavigationBar: MobileNavigation(
      role: customer ? 'customer' : 'admin',
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlinedButton(
            onPressed: () =>
                context.go('/${customer ? 'customer' : 'admin'}/orders'),
            child: const Text('Lihat progres Service Order'),
          ),
          BookingListContent(customer: customer),
        ],
      ),
    ),
  );
}

class BookingListContent extends ConsumerWidget {
  const BookingListContent({super.key, required this.customer});
  final bool customer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return ref
        .watch(bookingsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Column(
            children: [
              const Text('Gagal memuat booking.'),
              TextButton(
                onPressed: () => ref.invalidate(bookingsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
          data: (items) {
            final bookings = items
                .where((b) => !customer || b.customerId == session.userId)
                .toList();
            if (bookings.isEmpty) {
              return const EmptyState(
                title: 'Belum ada booking',
                description:
                    'Booking yang dibuat pelanggan akan muncul di sini.',
              );
            }
            return Column(
              children: [
                const Text('Menampilkan hingga 100 booking terbaru.'),
                ...bookings.map(
                  (b) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${b.id} • ${b.vehicle.name}'),
                      subtitle: Text(
                        '${b.draft.service}\n${bookingSchedule(b.draft.scheduledAt)}\n${b.status.label}',
                      ),
                      onTap: () => context.go(
                        '/${customer ? 'customer' : 'admin'}/bookings/${b.id}',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
  }
}

class BookingDetailPage extends ConsumerStatefulWidget {
  const BookingDetailPage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<BookingDetailPage> createState() => _BookingDetailState();
}

class _BookingDetailState extends ConsumerState<BookingDetailPage> {
  bool busy = false;
  Future<void> change(BookingStatus status) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status.label} booking?'),
        content: const Text('Pastikan perubahan status sudah sesuai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, lanjutkan'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => busy = true);
    try {
      final session = ref.read(authSessionProvider);
      await ref
          .read(bookingRepositoryProvider)
          .updateStatus(
            widget.id,
            status,
            actor: session.role!,
            actorId: session.userId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking ${status.label.toLowerCase()}.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final customer = session.role?.name == 'customer';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: MobileNavigation(
        role: session.role?.name ?? 'customer',
      ),
      body: SafeArea(
        child: ref
            .watch(bookingsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(bookingsProvider),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (items) {
                final matches = items.where(
                  (b) =>
                      b.id == widget.id &&
                      (!customer || b.customerId == session.userId),
                );
                if (matches.isEmpty) {
                  return const EmptyState(
                    title: 'Booking tidak ditemukan',
                    description: 'Booking tidak tersedia untuk sesi ini.',
                  );
                }
                final b = matches.first;
                final orderState = b.status == BookingStatus.confirmed
                    ? ref.watch(serviceOrderProvider(b.id))
                    : null;
                final hasOrder = orderState?.asData?.value != null;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      b.id,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text('${b.vehicle.name} • ${b.vehicle.plate}'),
                    Text('Pelanggan: ${b.customerId}'),
                    Text(b.draft.service),
                    Text(bookingSchedule(b.draft.scheduledAt)),
                    const SizedBox(height: 16),
                    Text('Keluhan: ${b.draft.complaint}'),
                    const SizedBox(height: 16),
                    Chip(label: Text(b.status.label)),
                    if (b.status == BookingStatus.confirmed &&
                        !customer &&
                        !hasOrder)
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                try {
                                  await ref
                                      .read(serviceOrderRepositoryProvider)
                                      .create(b.id);
                                  if (context.mounted) {
                                    context.go('/admin/orders/${b.id}');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Gagal membuat Service Order: $e',
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        child: const Text('Buat Service Order'),
                      ),
                    if (hasOrder)
                      TextButton(
                        onPressed: () => context.go(
                          '/${customer ? 'customer' : 'admin'}/orders/${b.id}',
                        ),
                        child: const Text('Buka Service Order'),
                      ),
                    if (orderState?.hasError == true)
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(serviceOrderProvider(b.id)),
                        child: const Text('Gagal memuat progres. Coba lagi'),
                      ),
                    if (customer && hasOrder)
                      const Text(
                        'Servis sudah diproses. Hubungi admin untuk pembatalan.',
                      ),
                    if (busy) const Center(child: CircularProgressIndicator()),
                    if (customer &&
                        b.status.isActive &&
                        !hasOrder &&
                        orderState?.isLoading != true &&
                        orderState?.hasError != true)
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => change(BookingStatus.cancelled),
                        child: const Text('Batalkan Booking'),
                      ),
                    if (!customer && b.status == BookingStatus.pending) ...[
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => change(BookingStatus.confirmed),
                        child: const Text('Konfirmasi'),
                      ),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => change(BookingStatus.rejected),
                        child: const Text('Tolak'),
                      ),
                    ],
                  ],
                );
              },
            ),
      ),
    );
  }
}
