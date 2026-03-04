import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin/employee_management_screen.dart';
import 'admin/location_management_screen.dart';
import 'admin/tool_management_screen.dart';
import 'admin/product_inventory_screen.dart';
import 'admin/admin_dashboard.dart';
import 'supervisor/supervisor_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Navigation State
  String _currentScreen = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    // Get User Role
    final authService = Provider.of<AuthService>(context);
    final profile = authService.userProfile;

    // Redirect for Supervisor
    if (profile == 'SUPERVISOR') {
       return const SupervisorDashboard();
    }
    
    // Default to Admin Dashboard
    Widget activeWidget = const AdminDashboard();

    if (_currentScreen == 'Empleados') activeWidget = const EmployeeManagementScreen();
    if (_currentScreen == 'Locaciones') activeWidget = const LocationManagementScreen();
    if (_currentScreen == 'Productos') activeWidget = const ProductInventoryScreen(); // Used Inventory instead
    if (_currentScreen == 'Herramientas') activeWidget = const ToolManagementScreen();

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel: $profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.emoji_objects, color: Color(0xFFFFD600), size: 36),
                      SizedBox(width: 8),
                      Icon(Icons.emoji_events, color: Color(0xFFFF4081), size: 36),
                      SizedBox(width: 8),
                      Icon(Icons.pets, color: Colors.white, size: 36),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('LuViRex Panel', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(authService.token != null ? 'Sesión Activa - $profile' : 'Offline', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                setState(() => _currentScreen = 'Dashboard');
                Navigator.pop(context);
              },
            ),
            if (profile == 'ADMIN') ...[
              _buildDrawerItem(context, 'Gestión de Empleados', const EmployeeManagementScreen()),
              _buildDrawerItem(context, 'Gestión de Locaciones', const LocationManagementScreen()),
              // _buildDrawerItem(context, 'Gestión de Productos', const ProductManagementScreen()),
              _buildDrawerItem(context, 'Gestión de Herramientas', const ToolManagementScreen()),
              _buildDrawerItem(context, 'Inventario (E/S)', const ProductInventoryScreen()),
            ],
            // TODO: Add Supervisor options
          ],
        ),
      ),
      body: activeWidget,
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, Widget screen) {
    return ListTile(
      title: Text(title),
      leading: const Icon(Icons.arrow_right),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
