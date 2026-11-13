import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/report_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report rejects any interval exceeding 31 days', () async {
    final repo = ReportRepository(FakeFirebaseFirestore(), UserRole.admin);
    final from = DateTime.utc(2026, 1, 1);
    await expectLater(
      repo.load(from, from.add(const Duration(days: 31, seconds: 1))),
      throwsArgumentError,
    );
    final report = await repo.load(from, from.add(const Duration(days: 31)));
    expect(report.bookings, 0);
    await expectLater(repo.load(from, from), throwsArgumentError);
  });
}
