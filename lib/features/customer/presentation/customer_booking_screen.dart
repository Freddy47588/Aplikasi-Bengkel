import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/data/booking_repository.dart';
import '../../../core/data/vehicle_repository.dart';
import '../../../core/data/service_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/widgets/foundation_pages.dart';
import '../../../core/widgets/mobile_navigation.dart';

class CustomerBookingScreen extends ConsumerStatefulWidget {
  const CustomerBookingScreen({super.key});
  @override
  ConsumerState<CustomerBookingScreen> createState() => _CustomerBookingState();
}

class _CustomerBookingState extends ConsumerState<CustomerBookingScreen> {
  final form = GlobalKey<FormState>();
  final complaint = TextEditingController();
  String? vehicle;
  String? service;
  DateTime? date;
  int? hour;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    complaint.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (date == null) {
      setState(() => error = 'Pilih tanggal servis.');
      return;
    }
    final draft = BookingDraft(
      vehicleId: vehicle!,
      service: ref
          .read(servicesProvider)
          .requireValue
          .firstWhere((s) => s.id == service)
          .name,
      serviceId: service!,
      scheduledAt: DateTime.utc(
        date!.year,
        date!.month,
        date!.day,
        hour!,
      ).subtract(const Duration(hours: 7)),
      complaint: complaint.text.trim(),
    );
    final validation = draft.validate(DateTime.now());
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Booking'),
        scrollable: true,
        content: Text(
          '${ref.read(vehiclesProvider).requireValue.firstWhere((v) => v.id == vehicle).name}\n${draft.service}\n${bookingSchedule(draft.scheduledAt)}\n${draft.complaint}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim Booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final session = ref.read(authSessionProvider);
      if (session.role?.name != 'customer') {
        throw StateError('Sesi pelanggan diperlukan.');
      }
      final result = await ref
          .read(bookingRepositoryProvider)
          .submit(session.userId, draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking berhasil dikirim. Menunggu konfirmasi admin.',
            ),
          ),
        );
        context.go('/customer/bookings/${result.id}');
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Booking gagal: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final services = ref.watch(servicesProvider);
    final availableVehicles = vehicles.asData?.value ?? <Vehicle>[];
    final availableServices = services.asData?.value ?? <WorkshopService>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Servis')),
      bottomNavigationBar: const MobileNavigation(role: 'customer'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const Text(
                  'Kendaraan demo • jadwal 09:00–16:00 • maksimal 90 hari',
                ),
                const SizedBox(height: 16),
                if (vehicles.isLoading || services.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (vehicles.hasError || services.hasError)
                  TextButton(
                    onPressed: () {
                      ref.invalidate(vehiclesProvider);
                      ref.invalidate(servicesProvider);
                    },
                    child: const Text('Gagal memuat katalog. Coba lagi'),
                  ),
                if (vehicles.hasValue && availableVehicles.isEmpty)
                  TextButton(
                    onPressed: () => context.go('/customer/vehicles'),
                    child: const Text('Tambahkan kendaraan terlebih dahulu'),
                  ),
                if (services.hasValue && availableServices.isEmpty)
                  const Text(
                    'Belum ada layanan aktif. Hubungi pengelola bengkel.',
                  ),
                Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'vehicles:${availableVehicles.map((v) => v.id).join(',')}',
                        ),
                        initialValue:
                            availableVehicles.any((v) => v.id == vehicle)
                            ? vehicle
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kendaraan',
                        ),
                        items: availableVehicles
                            .map(
                              (v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(
                                  '${v.name} • ${v.plate}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) => setState(() => vehicle = value),
                        validator: (value) =>
                            value == null ? 'Pilih kendaraan.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          'services:${availableServices.map((s) => s.id).join(',')}',
                        ),
                        initialValue:
                            availableServices.any((s) => s.id == service)
                            ? service
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jenis layanan',
                        ),
                        items: availableServices
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) => setState(() => service = value),
                        validator: (value) =>
                            value == null ? 'Pilih layanan.' : null,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          date == null
                              ? 'Pilih tanggal servis'
                              : '${date!.day}/${date!.month}/${date!.year}',
                        ),
                        onPressed: busy
                            ? null
                            : () async {
                                final now = DateTime.now();
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      date ?? now.add(const Duration(days: 1)),
                                  firstDate: DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  ),
                                  lastDate: now.add(const Duration(days: 90)),
                                );
                                if (selected != null && mounted) {
                                  setState(() => date = selected);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: hour,
                        decoration: const InputDecoration(
                          labelText: 'Jam servis',
                        ),
                        items: serviceHours
                            .map(
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Text(
                                  '${h.toString().padLeft(2, '0')}:00',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) => setState(() => hour = value),
                        validator: (value) =>
                            value == null ? 'Pilih jam servis.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: complaint,
                        enabled: !busy,
                        maxLength: 500,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Keluhan kendaraan',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value?.trim().length ?? 0) < 5
                            ? 'Tulis keluhan minimal 5 karakter.'
                            : null,
                      ),
                      if (error != null)
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (busy)
                        const Center(child: CircularProgressIndicator()),
                      FilledButton(
                        onPressed:
                            busy || !vehicles.hasValue || !services.hasValue
                            ? null
                            : submit,
                        child: const Text('Konfirmasi Booking'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Booking Saya',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const BookingListContent(customer: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
