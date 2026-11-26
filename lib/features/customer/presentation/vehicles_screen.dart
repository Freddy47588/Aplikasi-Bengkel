import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/data/vehicle_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/workshop_ui.dart';
import '../../auth/data/auth_repository.dart';
import 'customer_vehicle_art.dart';

IconData vehicleIcon(VehicleKind? kind) => switch (kind) {
  VehicleKind.motorcycle => Icons.two_wheeler,
  VehicleKind.car => Icons.directions_car_outlined,
  null => Icons.commute_outlined,
};

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});
  Future<void> edit(BuildContext context, [Vehicle? vehicle]) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: vehicle)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? 96
          : kToolbarHeight,
      title: const Text('Kendaraan Saya'),
      leading: IconButton(
        tooltip: 'Kembali ke beranda',
        onPressed: () => context.go('/customer/home'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    bottomNavigationBar: const MobileNavigation(role: 'customer'),
    body: WorkshopBody(
      showWave: true,
      child: Column(
        children: [
          Expanded(
            child: ref
                .watch(allVehiclesProvider)
                .when(
                  loading: () => const LoadingState(),
                  error: (_, _) => LoadError(
                    onRetry: () => ref.invalidate(allVehiclesProvider),
                    message:
                        'Gagal memuat kendaraan. Periksa koneksi dan coba lagi.',
                  ),
                  data: (vehicles) => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                        const CustomerVehicleArt(height: 112),
                      const SizedBox(height: 12),
                      Text(
                        'Daftar Kendaraan Anda',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kelola data kendaraan untuk booking servis dan riwayat perbaikan.',
                      ),
                      const SizedBox(height: 16),
                      if (vehicles.isEmpty)
                        const EmptyState(
                          title: 'Belum ada kendaraan',
                          description:
                              'Tambahkan kendaraan sebelum membuat booking.',
                          icon: Icons.commute_outlined,
                        ),
                      for (final vehicle in vehicles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: AppColors.blueBorder,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => edit(context, vehicle),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDBEAFE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        vehicleIcon(vehicle.kind),
                                        color: AppColors.secondary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vehicle.plate,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(vehicle.name),
                                          if (MediaQuery.textScalerOf(
                                                context,
                                              ).scale(1) >
                                              1.3) ...[
                                            const SizedBox(height: 6),
                                            _VehicleStatus(vehicle: vehicle),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (MediaQuery.textScalerOf(
                                          context,
                                        ).scale(1) <=
                                        1.3) ...[
                                      const SizedBox(width: 8),
                                      _VehicleStatus(vehicle: vehicle),
                                    ],
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Text(
                        'Menampilkan hingga 50 kendaraan.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => edit(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah kendaraan'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VehicleStatus extends StatelessWidget {
  const _VehicleStatus({required this.vehicle});
  final Vehicle vehicle;
  @override
  Widget build(BuildContext context) => StatusChip(
    label: vehicle.active ? 'Aktif' : 'Nonaktif',
    tone: vehicle.active ? StatusChipTone.success : StatusChipTone.neutral,
  );
}

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});
  final Vehicle? vehicle;
  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<VehicleFormScreen> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.vehicle?.name);
  late final plate = TextEditingController(text: widget.vehicle?.plate);
  late final notes = TextEditingController(text: widget.vehicle?.notes);
  late VehicleKind? kind = widget.vehicle == null
      ? VehicleKind.motorcycle
      : widget.vehicle?.kind;
  bool busy = false;
  String? error;
  bool get archived => widget.vehicle?.active == false;
  @override
  void dispose() {
    name.dispose();
    plate.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || archived || !form.currentState!.validate()) return;
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
            kind: kind,
            notes: notes.text,
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

  Future<void> archive() async {
    final approved = await confirmWorkshopAction(
      context,
      'Kendaraan menjadi nonaktif dan tidak bisa dipilih untuk booking baru. Riwayat booking tetap tersimpan.',
      title: 'Hapus kendaraan?',
      confirmLabel: 'Hapus',
    );
    if (!approved || !mounted) return;
    setState(() => busy = true);
    try {
      await ref
          .read(vehicleRepositoryProvider)
          .delete(ref.read(authSessionProvider).userId, widget.vehicle!.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Gagal menghapus kendaraan. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (!busy) Navigator.maybePop(context);
      },
    },
    child: Focus(
      autofocus: true,
      child: PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 96
                : kToolbarHeight,
            title: Text(
              archived
                  ? 'Detail Kendaraan'
                  : widget.vehicle == null
                  ? 'Tambah Kendaraan'
                  : 'Edit Kendaraan',
            ),
            leading: IconButton(
              tooltip: 'Kembali',
              onPressed: busy ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (widget.vehicle != null && !archived)
                IconButton(
                  tooltip: 'Hapus kendaraan',
                  onPressed: busy ? null : archive,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          bottomNavigationBar: archived
              ? null
              : Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy ? null : save,
                              icon: busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                busy ? 'Menyimpan…' : 'Simpan Kendaraan',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          body: WorkshopBody(
            child: Form(
              key: form,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                      CustomerVehicleArt(form: true, height: 100, kind: kind),
                    const SizedBox(height: 16),
                    const Text(
                      'Jenis Kendaraan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormField<VehicleKind>(
                      initialValue: kind,
                      validator: (value) => !archived && value == null
                          ? 'Pilih jenis kendaraan.'
                          : null,
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<VehicleKind>(
                            emptySelectionAllowed: kind == null,
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: VehicleKind.motorcycle,
                                icon: Icon(Icons.two_wheeler),
                                label: Text('Motor'),
                              ),
                              ButtonSegment(
                                value: VehicleKind.car,
                                icon: Icon(Icons.directions_car_outlined),
                                label: Text('Mobil'),
                              ),
                            ],
                            selected: {?kind},
                            onSelectionChanged: busy || archived
                                ? null
                                : (value) {
                                    setState(() => kind = value.firstOrNull);
                                    field.didChange(kind);
                                  },
                            style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              minimumSize: const WidgetStatePropertyAll(
                                Size(48, 48),
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? AppColors.secondary
                                    : Colors.white,
                              ),
                              side: const WidgetStatePropertyAll(
                                BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _field(
                      'Nama Kendaraan / Merk - Model',
                      name,
                      'Contoh: Honda Vario 160',
                      vehicleIcon(kind),
                      key: const Key('vehicle-name'),
                      max: 80,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Isi nama kendaraan.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Nomor Polisi',
                      plate,
                      'Contoh: B 4123 KZU',
                      Icons.pin_outlined,
                      key: const Key('vehicle-plate'),
                      max: 13,
                      validator: (value) {
                        try {
                          normalizePlate(value ?? '');
                          return null;
                        } catch (_) {
                          return 'Plat harus seperti B 1234 XYZ.';
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Catatan (Opsional)',
                      notes,
                      'Contoh: Warna hitam, tahun 2023',
                      Icons.notes_outlined,
                      key: const Key('vehicle-notes'),
                      max: 500,
                      lines: 3,
                    ),
                    if (archived)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Kendaraan ini telah diarsipkan. Riwayatnya tetap tersedia.',
                        ),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    required Key key,
    required int max,
    int lines = 1,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        child: TextFormField(
          key: key,
          controller: controller,
          enabled: !busy && !archived,
          maxLength: max,
          minLines: lines,
          maxLines: lines == 1 ? 1 : 5,
          textCapitalization: controller == plate
              ? TextCapitalization.characters
              : TextCapitalization.sentences,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    ],
  );
}
