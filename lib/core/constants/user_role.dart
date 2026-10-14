enum UserRole {
  customer,
  technician,
  admin;

  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Pelanggan';
      case UserRole.technician:
        return 'Teknisi';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
