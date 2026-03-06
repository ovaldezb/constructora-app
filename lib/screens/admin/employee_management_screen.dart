import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'employee_form_screen.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final _apiService = ApiService();
  List<dynamic> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.get('/employees');
      if (mounted) {
        setState(() {
          _employees = data as List<dynamic>;
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

  Future<void> _deleteEmployee(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar este empleado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/employees/$id');
        _fetchEmployees();
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
      final path = '${directory.path}/qr_employee_$name.png';
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

  void _showQRDialog(Map<String, dynamic> employee) {
    final GlobalKey qrKey = GlobalKey();
    final String qrData = employee['qrUrl'] ?? 'employee/${employee['_id']}';
    final String name = '${employee['nombre']} ${employee['apellidoPaterno']}';

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
                      employee['puesto'] ?? '',
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
              onPressed: () => _saveQrImage(qrKey, employee['_id']),
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

  Future<void> _showHistoryDialog(Map<String, dynamic> employee) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String empId = employee['_id'];
      final data = await _apiService.get('/attendance?employeeId=$empId&limit=5');
      final List<dynamic> records = data as List<dynamic>;

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        final String name = '${employee['nombre']} ${employee['apellidoPaterno']}';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Historial: $name', style: const TextStyle(fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              child: records.isEmpty
                  ? const Text('No hay registros de asistencia.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final isEntrada = record['type'] == 'ENTRADA';
                        final timestamp = DateTime.parse(record['timestamp']).toLocal();
                        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);

                        return ListTile(
                          leading: Icon(
                            isEntrada ? Icons.login : Icons.logout,
                            color: isEntrada ? Colors.green : Colors.orange,
                          ),
                          title: Text(record['type']),
                          subtitle: Text(formattedDate),
                        );
                      },
                    ),
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
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Empleados')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
          );
          _fetchEmployees();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return Card(
                  color: (emp['isActivo'] ?? true) ? Colors.white : Colors.grey[200],
                  child: ListTile(
                    title: Text('${emp['nombre']} ${emp['apellidoPaterno']}',
                      style: TextStyle(
                        decoration: (emp['isActivo'] ?? true) ? null : TextDecoration.lineThrough
                      )
                    ),
                    subtitle: Text('${emp['puesto']} - ${emp['tipoEmpleado']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!(emp['isActivo'] ?? true))
                           const Text('Inactivo', style: TextStyle(color: Colors.red, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: emp)),
                            );
                            _fetchEmployees();
                          },
                        ),
                        if (emp['isActivo'] ?? true)
                          IconButton(
                            icon: const Icon(Icons.qr_code, color: Colors.black),
                            onPressed: () => _showQRDialog(emp),
                          ),
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.teal),
                          onPressed: () => _showHistoryDialog(emp),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEmployee(emp['_id']),
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
