import 'package:flutter/material.dart';
import 'location_management_screen.dart';
import 'employee_management_screen.dart';
import 'tool_management_screen.dart';
import 'product_inventory_screen.dart';
import 'vehicle_management_screen.dart';
import 'reports_screen.dart';
import 'user_management_screen.dart'; // Changed from user_registration_screen.dart

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 200, // Cards adapt to screen width (approx 200 width per card)
      padding: const EdgeInsets.all(16.0),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.0, 
      children: [
        _AdminCard(
          title: 'Empleados',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeManagementScreen())),
        ),
        _AdminCard(
          title: 'Locaciones',
          icon: Icons.place,
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationManagementScreen())),
        ),
        _AdminCard(
          title: 'Herramientas',
          icon: Icons.build,
          color: Colors.red,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolManagementScreen())),
        ),
        _AdminCard(
          title: 'Inventario',
          icon: Icons.inventory,
          color: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductInventoryScreen())),
        ),
        _AdminCard(
          title: 'Vehículos',
          icon: Icons.directions_car,
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleManagementScreen())),
        ),
        _AdminCard(
          title: 'Reportes',
          icon: Icons.analytics,
          color: Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
        ),
        _AdminCard(
          title: 'Usuarios',
          icon: Icons.manage_accounts,
          color: Colors.deepPurple,
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
