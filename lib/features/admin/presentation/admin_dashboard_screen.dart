import 'package:flutter/material.dart';
import '../../../core/widgets/live_dashboard.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const LiveDashboard(customer: false);
}
