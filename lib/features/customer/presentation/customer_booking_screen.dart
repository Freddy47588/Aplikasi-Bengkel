import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/workshop_ui.dart';
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
  bool reviewing = false;
  String? error;
  @override
  void dispose() {
    complaint.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || reviewing) return;
    if (!form.currentState!.validate()) return;
    if (date == null) {
      setState(() => error = 'Pilih tanggal servis.');
      return;
    }
    final vehicles = ref.read(vehiclesProvider);
    final services = ref.read(servicesProvider);
    final selectedVehicle = vehicles.asData?.value
        .where((v) => v.id == vehicle)
        .firstOrNull;
    final selectedService = services.asData?.value
        .where((s) => s.id == service)
        .firstOrNull;
    if (vehicles.isLoading ||
        services.isLoading ||
        vehicles.hasError ||
        services.hasError ||
        selectedVehicle == null ||
        selectedService == null) {
      setState(
        () => error =
            'Katalog berubah atau belum tersedia. Pilih kembali kendaraan dan layanan.',
      );
      return;
    }
    final customerId = ref.read(authSessionProvider).userId;
    final draft = BookingDraft(
      vehicleId: selectedVehicle.id,
      service: selectedService.name,
      serviceId: selectedService.id,
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
    setState(() {
      reviewing = true;
      error = null;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Konfirmasi Booking'),
        content: Text(
          '${selectedVehicle.name}\n${draft.service}\n${bookingSchedule(draft.scheduledAt)}\n${draft.complaint}',
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
    if (!mounted) return;
    setState(() => reviewing = false);
    if (confirmed != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final session = ref.read(authSessionProvider);
      if (!session.isAuthenticated ||
          session.role?.name != 'customer' ||
          session.userId != customerId) {
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
      if (mounted) setState(() => error = friendlyWorkshopError(e));
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
    final catalogReady =
        !vehicles.isLoading &&
        !services.isLoading &&
        !vehicles.hasError &&
        !services.hasError &&
        availableVehicles.isNotEmpty &&
        availableServices.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Servis')),
      bottomNavigationBar: const MobileNavigation(role: 'customer'),
      body: WorkshopBody(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Booking Servis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pilih kendaraan, layanan, dan slot kunjungan (09:00–16:00 WIB • maks. 90 hari).',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
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
                      ContentSection(
                        title: 'Kendaraan & layanan',
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
                            itemHeight: null,
                            menuMaxHeight: 320,
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Kendaraan',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                            items: availableVehicles
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v.id,
                                    child: Text('${v.name} • ${v.plate}'),
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
                            itemHeight: null,
                            menuMaxHeight: 320,
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Jenis layanan',
                              prefixIcon: Icon(Icons.build_outlined),
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
                        ],
                      ),
                      ContentSection(
                        title: 'Jadwal kunjungan',
                        children: [
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
                                          date ??
                                          now.add(const Duration(days: 1)),
                                      firstDate: DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      ),
                                      lastDate: now.add(
                                        const Duration(days: 90),
                                      ),
                                    );
                                    if (selected != null && mounted) {
                                      final wibNow = DateTime.now().toUtc().add(
                                        const Duration(hours: 7),
                                      );
                                      final isToday =
                                          selected.year == wibNow.year &&
                                          selected.month == wibNow.month &&
                                          selected.day == wibNow.day;
                                      setState(() {
                                        date = selected;
                                        if (isToday &&
                                            hour != null &&
                                            hour! <= wibNow.hour) {
                                          hour = null;
                                        }
                                      });
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final wibNow = DateTime.now().toUtc().add(
                                const Duration(hours: 7),
                              );
                              final isToday =
                                  date != null &&
                                  date!.year == wibNow.year &&
                                  date!.month == wibNow.month &&
                                  date!.day == wibNow.day;
                              final slots = isToday
                                  ? serviceHours
                                        .where((h) => h > wibNow.hour)
                                        .toList()
                                  : serviceHours;
                              final activeHour = slots.contains(hour)
                                  ? hour
                                  : null;
                              return DropdownButtonFormField<int>(
                                key: ValueKey('hour:${slots.join(',')}'),
                                isExpanded: true,
                                itemHeight: null,
                                menuMaxHeight: 320,
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                                initialValue: activeHour,
                                decoration: InputDecoration(
                                  labelText: 'Jam servis (WIB)',
                                  helperText: isToday && slots.isEmpty
                                      ? 'Slot hari ini sudah tutup; pilih tanggal besok.'
                                      : 'Jam operasional WIB (istirahat 12:00).',
                                  prefixIcon: const Icon(
                                    Icons.schedule_outlined,
                                  ),
                                ),
                                items: slots
                                    .map(
                                      (h) => DropdownMenuItem(
                                        value: h,
                                        child: Text(
                                          '${h.toString().padLeft(2, '0')}:00',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: busy || slots.isEmpty
                                    ? null
                                    : (value) => setState(() => hour = value),
                                validator: (value) =>
                                    value == null ? 'Pilih jam servis.' : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
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
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: busy || reviewing || !catalogReady
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
