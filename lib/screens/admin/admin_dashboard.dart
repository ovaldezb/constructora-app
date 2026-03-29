import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'location_management_screen.dart';
import 'employee_management_screen.dart';
import 'tool_management_screen.dart';
import 'product_inventory_screen.dart';
import 'vehicle_management_screen.dart';
import 'reports_screen.dart';
import 'user_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 200,
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.0, 
      children: [
        _AdminCard(
          title: 'Empleados',
          icon: Icons.people,
          color: AppColors.cardEmpleados,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeManagementScreen())),
        ),
        _AdminCard(
          title: 'Locaciones',
          icon: Icons.place,
          color: AppColors.cardLocaciones,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationManagementScreen())),
        ),
        _AdminCard(
          title: 'Herramientas',
          icon: Icons.build,
          color: AppColors.cardHerramientas,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolManagementScreen())),
        ),
        _AdminCard(
          title: 'Inventario',
          icon: Icons.inventory,
          color: AppColors.cardInventario,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductInventoryScreen())),
        ),
        _AdminCard(
          title: 'Vehículos',
          icon: Icons.directions_car,
          color: AppColors.cardVehiculos,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleManagementScreen())),
        ),
        _AdminCard(
          title: 'Reportes',
          icon: Icons.analytics,
          color: AppColors.cardReportes,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
        ),
        _AdminCard(
          title: 'Usuarios',
          icon: Icons.manage_accounts,
          color: AppColors.cardUsuarios,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
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
