import '../../../core/widgets/workshop_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/data/vehicle_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/data/auth_repository.dart';
import 'customer_vehicle_art.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});
  Future<void> edit(
    BuildContext context,
    WidgetRef ref, [
    Vehicle? vehicle,
  ]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _VehicleForm(vehicle: vehicle),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? 96
          : kToolbarHeight,
      title: const Text(
        'Kendaraan Saya',
        softWrap: true,
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
      leading: IconButton(
        tooltip: 'Kembali ke beranda',
        onPressed: () => context.go('/customer/home'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => edit(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah kendaraan'),
            ),
          ),
        ),
        const MobileNavigation(role: 'customer'),
      ],
    ),
    body: WorkshopBody(
      showWave: true,
      child: ref
          .watch(vehiclesProvider)
          .when(
            loading: () => const LoadingState(),
            error: (_, _) => LoadError(
              onRetry: () => ref.invalidate(vehiclesProvider),
              message: 'Gagal memuat kendaraan. Periksa koneksi dan coba lagi.',
            ),
            data: (vehicles) => ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                  const CustomerVehicleArt(),
                const SizedBox(height: 18),
                Text(
                  'Daftar Kendaraan Anda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kelola data kendaraan untuk booking servis dan riwayat perbaikan. Ketuk kartu untuk mengedit.',
                ),
                const SizedBox(height: 20),
                if (vehicles.isEmpty)
                  const EmptyState(
                    title: 'Belum ada kendaraan',
                    description: 'Tambahkan kendaraan sebelum membuat booking.',
                    icon: Icons.directions_car_outlined,
                  ),
                const Text(
                  'Menampilkan hingga 50 kendaraan aktif.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                for (final v in vehicles)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.blueBorder),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                      leading: const Icon(
                        Icons.directions_car_outlined,
                        color: AppColors.secondary,
                        size: 30,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              v.plate,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 22),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(v.name),
                            const StatusChip(
                              label: 'Aktif',
                              tone: StatusChipTone.success,
                            ),
                          ],
                        ),
                      ),
                      onTap: () => edit(context, ref, v),
                      trailing: IconButton(
                        tooltip: 'Hapus ${v.plate}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              scrollable: true,
                              title: const Text('Hapus kendaraan?'),
                              content: Text(
                                '${v.name} • ${v.plate}. Riwayat booking tetap tersimpan.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Kembali'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true || !context.mounted) return;
                          try {
                            await ref
                                .read(vehicleRepositoryProvider)
                                .delete(
                                  ref.read(authSessionProvider).userId,
                                  v.id,
                                );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gagal menghapus kendaraan. Coba lagi.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
    ),
  );
}

class _VehicleForm extends ConsumerStatefulWidget {
  const _VehicleForm({this.vehicle});
  final Vehicle? vehicle;
  @override
  ConsumerState<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<_VehicleForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.vehicle?.name);
  late final plate = TextEditingController(text: widget.vehicle?.plate);
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    plate.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(vehicleRepositoryProvider)
          .save(
            ref.read(authSessionProvider).userId,
            name.text,
            plate.text,
            id: widget.vehicle?.id,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Kendaraan gagal disimpan. Periksa koneksi dan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: AppColors.blueBorder),
    ),
    scrollable: true,
    title: Text(
      widget.vehicle == null ? 'Tambah kendaraan' : 'Edit kendaraan',
      textAlign: TextAlign.center,
    ),
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
            const CustomerVehicleArt(form: true, height: 104),
          const SizedBox(height: 12),
          TextFormField(
            controller: name,
            enabled: !busy,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nama kendaraan',
              hintText: 'Merek / model kendaraan',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Isi nama kendaraan.' : null,
          ),
          TextFormField(
            controller: plate,
            enabled: !busy,
            maxLength: 13,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Plat nomor',
              hintText: 'B 1234 XYZ',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            validator: (v) {
              try {
                normalizePlate(v ?? '');
                return null;
              } catch (_) {
                return 'Plat harus seperti B 1234 XYZ.';
              }
            },
          ),
          if (error != null) Text(error!),
          if (busy) const CircularProgressIndicator(),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Kembali'),
      ),
      FilledButton.icon(
        onPressed: busy ? null : save,
        icon: const Icon(Icons.check),
        label: const Text('Simpan'),
      ),
    ],
  );
}
