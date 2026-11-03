import 'package:flutter/material.dart';
import '../../../core/widgets/live_dashboard.dart';

class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const LiveDashboard(customer: false, technician: true);
}
