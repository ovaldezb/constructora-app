import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../admin/product_inventory_screen.dart';
import 'supervisor_employee_screen.dart';
import 'supervisor_tool_screen.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Supervisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: GridView.extent(
        maxCrossAxisExtent: 200,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
        children: [
          _SupervisorCard(
            title: 'Gestión de Empleados',
            icon: Icons.people,
            color: AppColors.cardEmpleados,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorEmployeeScreen())),
          ),
          _SupervisorCard(
              title: 'Herramientas',
              icon: Icons.inventory_2,
              color: AppColors.cardHerramientas,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorToolScreen())),
          ),
        ],
      ),
    );
  }
}

class _SupervisorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SupervisorCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
