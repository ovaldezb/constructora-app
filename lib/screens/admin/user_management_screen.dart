import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'user_registration_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener usuarios: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleStatus(String username, bool currentStatus) async {
    final newStatus = !currentStatus;
    
    // Optimistic UI update
    setState(() {
      final index = _users.indexWhere((u) => u['username'] == username);
      if (index != -1) {
        _users[index]['enabled'] = newStatus;
      }
    });

    try {
      await _apiService.toggleUserStatus(username, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newStatus ? 'Usuario habilitado' : 'Usuario deshabilitado')),
      );
    } catch (e) {
      // Revert optimism
      setState(() {
        final index = _users.indexWhere((u) => u['username'] == username);
        if (index != -1) {
          _users[index]['enabled'] = currentStatus;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No hay usuarios registrados.'))
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isEnabled = user['enabled'] == true;
                      final profile = user['profile'] ?? 'SIN PERFIL';
                      final fullName = [
                         user['given_name'] ?? '',
                         user['middle_name'] ?? '',
                         user['family_name'] ?? ''
                      ].where((s) => s.toString().isNotEmpty).join(' ');

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isEnabled ? Colors.deepPurple.shade100 : Colors.grey.shade300,
                            child: Icon(
                              Icons.person,
                              color: isEnabled ? Colors.deepPurple : Colors.grey,
                            ),
                          ),
                          title: Text(fullName.isEmpty ? user['email'] ?? 'Sin Nombre' : fullName,
                                     style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? ''),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: profile == 'ADMIN' ? Colors.red.shade100 : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  profile,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: profile == 'ADMIN' ? Colors.red.shade900 : Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Switch(
                            value: isEnabled,
                            onChanged: (val) => _toggleStatus(user['username'], !val),
                            activeColor: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserRegistrationScreen()),
          );
          _fetchUsers(); // Refresh when coming back
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }
}
