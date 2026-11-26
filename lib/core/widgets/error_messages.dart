import 'package:firebase_core/firebase_core.dart';

/// Maps raw technical exceptions into user-friendly Indonesian messages.
String friendlyWorkshopError(Object error) {
  if (error is FirebaseException) {
    final code = error.code.toLowerCase();
    return switch (code) {
      'permission-denied' =>
        'Anda tidak memiliki izin untuk melakukan tindakan ini.',
      'unavailable' =>
        'Layanan sedang tidak terjangkau. Periksa koneksi internet dan coba lagi.',
      'not-found' => 'Data yang diminta tidak ditemukan atau sudah berubah.',
      'already-exists' => 'Data atau slot yang dipilih sudah terdaftar.',
      'aborted' =>
        'Terjadi perubahan data bersamaan. Muat ulang lalu coba lagi.',
      'failed-precondition' =>
        'Kondisi data belum memenuhi syarat untuk memproses tindakan ini.',
      'deadline-exceeded' =>
        'Waktu permintaan habis. Periksa koneksi lalu coba kembali.',
      'unauthenticated' => 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      'network-request-failed' =>
        'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.',
      _ =>
        'Terjadi kendala pada layanan bengkel. Coba lagi beberapa saat lagi.',
    };
  }
  if (error is FormatException) {
    return 'Format data yang dimasukkan tidak valid. Periksa kembali isian Anda.';
  }
  if (error is StateError) {
    return _cleanInnerMessage(error.message);
  }
  if (error is ArgumentError) {
    final msg = error.message;
    if (msg is String) return _cleanInnerMessage(msg);
  }
  return 'Terjadi kendala saat memproses permintaan. Periksa koneksi dan coba lagi.';
}

String _cleanInnerMessage(String raw) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty ||
      cleaned.contains('package:') ||
      cleaned.contains('dart:') ||
      cleaned.contains('Exception') ||
      cleaned.contains('StackTrace') ||
      cleaned.length > 140) {
    return 'Terjadi kendala saat memproses permintaan. Periksa koneksi dan coba lagi.';
  }
  return cleaned;
}
