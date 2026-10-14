import 'package:flutter/material.dart';
import '../../../core/widgets/foundation_pages.dart';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const BookingListPage(customer: false);
}
