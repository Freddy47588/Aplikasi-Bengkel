import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../data/booking_repository.dart';
import '../models/booking.dart';
import 'empty_state.dart';
import 'mobile_navigation.dart';

String bookingSchedule(DateTime date) =>
    '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:00';

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
            FilledButton(
              onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
              child: const Text('Keluar'),
            ),
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
        children: [BookingListContent(customer: customer)],
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
                .toList()
                .reversed
                .toList();
            if (bookings.isEmpty) {
              return const EmptyState(
                title: 'Belum ada booking',
                description:
                    'Booking yang dibuat pelanggan akan muncul di sini.',
              );
            }
            return Column(
              children: bookings
                  .map(
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
                  )
                  .toList(),
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
          onPressed: () =>
              context.go(customer ? '/customer/history' : '/admin/bookings'),
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
                    if (busy) const Center(child: CircularProgressIndicator()),
                    if (customer && b.status.isActive)
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
