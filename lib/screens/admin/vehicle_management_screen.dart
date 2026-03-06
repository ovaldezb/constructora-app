import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../../services/api_service.dart';
import 'vehicle_form_screen.dart';
import 'vehicle_movement_screen.dart';
import 'vehicle_history_screen.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final _apiService = ApiService();
  List<dynamic> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.get('/vehicles');
      if (mounted) {
        setState(() {
          _vehicles = data as List<dynamic>;
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

  Future<void> _deleteVehicle(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar (dar de baja) este vehículo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/vehicles/$id');
        _fetchVehicles(); // Refresh list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  Future<void> _saveQrImage(GlobalKey key, String name) async {
    try {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/qr_$name.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código QR guardado en la galería ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  void _showQRDialog(Map<String, dynamic> vehicle) {
    final GlobalKey qrKey = GlobalKey();
    final String qrData = vehicle['qrUrl'] ?? 'vehiculo/${vehicle['_id']}';
    final String name = '${vehicle['modelo']} - ${vehicle['placas']}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR: $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      vehicle['vin'] ?? 'S/N',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Guardar en Galería'),
              onPressed: () => _saveQrImage(qrKey, vehicle['_id']),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Vehículos')),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_movement',
            backgroundColor: Colors.orange,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleMovementScreen()),
              );
              _fetchVehicles();
            },
            child: const Icon(Icons.swap_horiz),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_vehicle',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
              );
              _fetchVehicles();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                final isActive = vehicle['isActivo'] ?? true;
                
                return Card(
                  color: isActive ? Colors.white : Colors.grey[200],
                  child: ListTile(
                    title: Text(
                      '${vehicle['modelo']} (${vehicle['modelyear']})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isActive ? null : TextDecoration.lineThrough,
                        color: isActive ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Placas: ${vehicle['placas']}'),
                        Text('VIN: ${vehicle['vin']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: vehicle)),
                            );
                            _fetchVehicles();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: Colors.black),
                          onPressed: () => _showQRDialog(vehicle),
                        ),
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.purple),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VehicleHistoryScreen(vehicle: vehicle),
                              ),
                            );
                          },
                        ),
                        if (isActive)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteVehicle(vehicle['_id']),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
