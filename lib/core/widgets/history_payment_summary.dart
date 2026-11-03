import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../data/payment_repository.dart';
import '../models/invoice.dart';
import 'workshop_ui.dart';

// The invoice identity already equals the Service Order identity. Read only;
// no writes or changes to transaction rules, totals or collections.
final historyInvoiceStatusProvider = StreamProvider.autoDispose
    .family<({Invoice? invoice, bool cached}), String>((ref, id) {
      return ref
          .watch(paymentRepositoryProvider)
          .invoices
          .doc(id)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => (
              invoice: snapshot.exists
                  ? Invoice(snapshot.id, snapshot.data()!)
                  : null,
              cached: snapshot.metadata.isFromCache,
            ),
          );
    });

class HistoryPaymentSummary extends ConsumerWidget {
  const HistoryPaymentSummary({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role!.name;
    // Technician access does not include invoices; do not issue this query.
    if (role == 'technician') {
      return const ContentSection(
        title: 'Pembayaran',
        children: [Text('Pembayaran dikelola admin/kasir.')],
      );
    }
    return ContentSection(
      title: 'Pembayaran',
      children: [
        ref
            .watch(historyInvoiceStatusProvider(orderId))
            .when(
              loading: () => const LoadingState(),
              error: (_, _) => LoadError(
                onRetry: () =>
                    ref.invalidate(historyInvoiceStatusProvider(orderId)),
                message:
                    'Status invoice belum dapat dimuat. Periksa koneksi dan akses akun.',
              ),
              data: (result) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (result.cached)
                    const Text(
                      'Offline/cache: status pembayaran mungkin belum terbaru.',
                    ),
                  if (result.invoice == null)
                    Text(
                      result.cached
                          ? 'Invoice belum tersedia dalam cache.'
                          : 'Invoice belum diterbitkan.',
                    )
                  else ...[
                    PaymentBadge(status: result.invoice!.text('status')),
                    TextButton.icon(
                      onPressed: () => context.go('/$role/invoices/$orderId'),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Lihat invoice & rincian pembayaran'),
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}
