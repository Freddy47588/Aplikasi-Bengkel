import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/vehicle_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../auth/data/auth_repository.dart';

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
    appBar: AppBar(title: const Text('Kendaraan Saya')),
    bottomNavigationBar: const MobileNavigation(role: 'customer'),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => edit(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('Tambah kendaraan'),
    ),
    body: SafeArea(
      child: ref
          .watch(vehiclesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(vehiclesProvider),
                child: const Text('Gagal memuat kendaraan. Coba lagi'),
              ),
            ),
            data: (vehicles) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                if (vehicles.isEmpty)
                  const Text(
                    'Belum ada kendaraan. Tambahkan sebelum membuat booking.',
                  ),
                const Text('Menampilkan hingga 50 kendaraan aktif.'),
                for (final v in vehicles)
                  Card(
                    child: ListTile(
                      title: Text(v.name),
                      subtitle: Text(v.plate),
                      onTap: () => edit(context, ref, v),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
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
    if (!form.currentState!.validate()) return;
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
    title: Text(widget.vehicle == null ? 'Tambah kendaraan' : 'Edit kendaraan'),
    scrollable: true,
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: name,
            enabled: !busy,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Nama kendaraan'),
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
      FilledButton(onPressed: busy ? null : save, child: const Text('Simpan')),
    ],
  );
}
