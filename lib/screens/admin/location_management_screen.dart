import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  final _apiService = ApiService();
  List<dynamic> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.get('/locations');
      if (mounted) {
        setState(() {
          _locations = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showLocationDialog({Map<String, dynamic>? location}) async {
    final isEditing = location != null;
    final nombreController = TextEditingController(text: location?['nombre'] ?? '');
    final ubicacionController = TextEditingController(text: location?['ubicacion'] ?? '');
    bool isActivo = location?['isActivo'] ?? true;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Locación' : 'Nueva Locación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: ubicacionController,
                  decoration: const InputDecoration(labelText: 'Ubicación / Dirección'),
                ),
                if (isEditing)
                  SwitchListTile(
                    title: const Text('Activo'),
                    value: isActivo,
                    onChanged: (val) => setState(() => isActivo = val),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  final payload = {
                    'nombre': nombreController.text,
                    'ubicacion': ubicacionController.text,
                    'isActivo': isActivo,
                  };

                  try {
                    if (isEditing) {
                      await _apiService.put('/locations/${location['_id']}', payload);
                    } else {
                      await _apiService.post('/locations', payload);
                    }
                    if (context.mounted) Navigator.pop(context); // Use context.mounted for newer flutter
                    _fetchLocations();
                  } catch (e) {
                    print(e);
                  }
                },
                child: Text(isEditing ? 'Guardar' : 'Crear'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _deleteLocation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar esta locación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/locations/$id');
        _fetchLocations();
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Locaciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final loc = _locations[index];
                return Card(
                  color: (loc['isActivo'] ?? true) ? Colors.white : Colors.grey[200],
                  child: ListTile(
                    title: Text(
                      loc['nombre'], 
                      style: TextStyle(
                        color: (loc['isActivo'] ?? true) ? Colors.black : Colors.grey,
                        decoration: (loc['isActivo'] ?? true) ? null : TextDecoration.lineThrough
                      )
                    ),
                    subtitle: Text(loc['ubicacion']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!(loc['isActivo'] ?? true))
                           const Text('Inactivo', style: TextStyle(color: Colors.red, fontSize: 12)),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showLocationDialog(location: loc)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteLocation(loc['_id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
