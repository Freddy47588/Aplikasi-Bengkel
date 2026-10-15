import 'package:flutter/material.dart';
import '../../../core/widgets/live_dashboard.dart';

class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const LiveDashboard(customer: true);
}
