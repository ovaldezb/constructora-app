import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
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
    if (_currentScreen == 'Productos') activeWidget = const ProductInventoryScreen();
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
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ── Logo in drawer ──
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo_vcm.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'LuViRex',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    authService.token != null ? 'Sesión Activa - $profile' : 'Offline',
                    style: TextStyle(
                      color: AppColors.accentLight.withOpacity(0.8),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.primary),
              title: const Text('Dashboard'),
              onTap: () {
                setState(() => _currentScreen = 'Dashboard');
                Navigator.pop(context);
              },
            ),
            if (profile == 'ADMIN') ...[
              _buildDrawerItem(context, 'Gestión de Empleados', const EmployeeManagementScreen(), Icons.people),
              _buildDrawerItem(context, 'Gestión de Locaciones', const LocationManagementScreen(), Icons.place),
              _buildDrawerItem(context, 'Gestión de Herramientas', const ToolManagementScreen(), Icons.build),
              _buildDrawerItem(context, 'Inventario (E/S)', const ProductInventoryScreen(), Icons.inventory),
            ],
          ],
        ),
      ),
      body: activeWidget,
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, Widget screen, IconData icon) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon, color: AppColors.accent),
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
