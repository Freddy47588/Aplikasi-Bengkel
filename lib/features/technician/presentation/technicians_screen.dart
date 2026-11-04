import '../../../core/widgets/workshop_ui.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/router/app_router.dart';
import '../../../core/data/service_order_repository.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/status_chip.dart';
import 'service_orders_screen.dart';

typedef TechnicianFilter = ({
  DocumentSnapshot<Map<String, dynamic>>? cursor,
  String search,
  bool? active,
  String specialization,
});
final techniciansPageProvider = StreamProvider.autoDispose
    .family<RecordPage<Technician>, TechnicianFilter>((ref, filter) {
      if (!ref.watch(authSessionProvider).isAuthenticated) {
        return Stream.value(const RecordPage([], null, false));
      }
      return ref
          .watch(serviceOrderRepositoryProvider)
          .watchTechnicians(
            after: filter.cursor,
            search: filter.search,
            active: filter.active,
            specialization: filter.specialization,
          );
    });

class TechniciansScreen extends ConsumerStatefulWidget {
  const TechniciansScreen({super.key, this.select = false});
  final bool select;
  @override
  ConsumerState<TechniciansScreen> createState() => _TechniciansState();
}

class _TechniciansState extends ConsumerState<TechniciansScreen> {
  final search = TextEditingController(),
      specialization = TextEditingController();
  String appliedSearch = '', appliedSpecialization = '';
  bool? active;
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  @override
  void initState() {
    super.initState();
    if (widget.select) active = true;
  }

  @override
  void dispose() {
    search.dispose();
    specialization.dispose();
    super.dispose();
  }

  void resetPage() {
    cursors.clear();
    cursors.add(null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = techniciansPageProvider((
      cursor: cursors.last,
      search: appliedSearch,
      active: active,
      specialization: appliedSpecialization,
    ));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.select ? 'Pilih teknisi tersedia' : 'Kelola teknisi',
        ),
        actions: [
          if (!widget.select)
            IconButton(
              tooltip: 'Tambah teknisi',
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechnicianEditor()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: widget.select
          ? null
          : const MobileNavigation(role: 'admin'),
      body: WorkshopBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          children: [
            if (!widget.select) ...[
              const WorkshopIllustration(WorkshopArt.technician),
              const SizedBox(height: 16),
              const WorkspaceLinks(role: 'admin'),
              const SizedBox(height: 24),
              Text(
                'Tim teknisi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: search,
              decoration: const InputDecoration(
                labelText: 'Cari nama teknisi',
                prefixIcon: Icon(Icons.search),
                helperText: 'Ketik awal nama sesuai penulisan terdaftar.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: specialization,
              decoration: const InputDecoration(
                labelText: 'Spesialisasi',
                helperText: 'Kosongkan untuk semua spesialisasi.',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<bool?>(
              isExpanded: true,
              itemHeight: null,
              initialValue: active,
              decoration: const InputDecoration(labelText: 'Status teknisi'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: true, child: Text('Aktif')),
                DropdownMenuItem(value: false, child: Text('Nonaktif')),
              ],
              onChanged: (v) => setState(() {
                active = v;
                resetPage();
              }),
            ),
            TextButton(
              onPressed: () => setState(() {
                appliedSearch = search.text.trim();
                appliedSpecialization = specialization.text.trim();
                resetPage();
              }),
              child: const Text('Cari / terapkan filter'),
            ),
            ref
                .watch(provider)
                .when(
                  loading: () => const LoadingState(),
                  error: (_, _) =>
                      RetryLoad(onRetry: () => ref.invalidate(provider)),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (page.items.isEmpty)
                        const EmptyState(
                          title: 'Teknisi belum ditemukan',
                          description: 'Tidak ada teknisi sesuai filter.',
                          icon: Icons.engineering_outlined,
                        ),
                      for (final t in page.items)
                        WorkshopRecordCard(
                          icon: Icons.engineering_outlined,
                          title: t.name,
                          description:
                              '${t.specialization}\n${t.assignable ? 'Tersedia' : 'Tidak tersedia'}',
                          status: StatusChip(
                            label: t.active ? 'Aktif' : 'Nonaktif',
                            tone: t.active
                                ? StatusChipTone.success
                                : StatusChipTone.neutral,
                          ),
                          enabled: !widget.select || t.assignable,
                          onTap: () {
                            if (widget.select) {
                              Navigator.pop(context, t.id);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TechnicianEditor(technician: t),
                                ),
                              );
                            }
                          },
                        ),
                      PageButtons(
                        page: cursors.length,
                        hasMore: page.hasMore,
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

class TechnicianEditor extends ConsumerStatefulWidget {
  const TechnicianEditor({super.key, this.technician});
  final Technician? technician;
  @override
  ConsumerState<TechnicianEditor> createState() => _TechnicianEditorState();
}

class _TechnicianEditorState extends ConsumerState<TechnicianEditor> {
  late final uid = TextEditingController(text: widget.technician?.id);
  late final name = TextEditingController(text: widget.technician?.name);
  late final specialization = TextEditingController(
    text: widget.technician?.specialization,
  );
  late bool active = widget.technician?.active ?? true;
  late bool available = widget.technician?.available ?? true;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    uid.dispose();
    name.dispose();
    specialization.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil operasional teknisi')),
    body: WorkshopBody(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Akun dengan role technician harus disiapkan operator tepercaya terlebih dahulu.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: uid,
            enabled: !busy && widget.technician == null,
            decoration: const InputDecoration(labelText: 'UID akun teknisi'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            enabled: !busy,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          TextField(
            controller: specialization,
            enabled: !busy,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Spesialisasi'),
          ),
          SwitchListTile(
            title: const Text('Aktif'),
            value: active,
            onChanged: busy ? null : (v) => setState(() => active = v),
          ),
          SwitchListTile(
            title: const Text('Menerima tugas baru'),
            value: available,
            onChanged: busy ? null : (v) => setState(() => available = v),
          ),
          if (error != null) Text(error!),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await ref
                          .read(serviceOrderRepositoryProvider)
                          .saveTechnician(
                            uid.text.trim(),
                            name.text,
                            specialization.text,
                            active,
                            available,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          busy = false;
                          error = 'Gagal menyimpan: $e';
                        });
                      }
                    }
                  },
            child: Text(busy ? 'Menyimpan…' : 'Simpan'),
          ),
        ],
      ),
    ),
  );
}
