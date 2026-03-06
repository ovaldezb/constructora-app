import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../admin/employee_form_screen.dart';
import 'qr_scanner_screen.dart';

class SupervisorEmployeeScreen extends StatefulWidget {
  const SupervisorEmployeeScreen({super.key});

  @override
  State<SupervisorEmployeeScreen> createState() => _SupervisorEmployeeScreenState();
}

class _SupervisorEmployeeScreenState extends State<SupervisorEmployeeScreen> {
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

  Future<void> _scanQR(TextEditingController controller) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && result is String) {
      if (mounted) {
        // Al modificar el texto, el TextField que escucha al controller se actualizará automáticamente
        controller.text = result;
      }
    }
  }

  Future<void> _showAttendanceModal() async {
    final controller = TextEditingController();
    String type = 'ENTRADA';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tomar Asistencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text('Simular lectura QR escribiendo "employee/ID"'),
               const SizedBox(height: 10),
               TextField(
                 controller: controller,
                 decoration: InputDecoration(
                   labelText: 'QR Code Data',
                   border: const OutlineInputBorder(),
                   hintText: 'employee/65df...',
                   suffixIcon: IconButton(
                     icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                     onPressed: () => _scanQR(controller),
                   ),
                 ),
               ),
               const SizedBox(height: 10),
               DropdownButtonFormField<String>(
                 value: type,
                 items: const [
                   DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
                   DropdownMenuItem(value: 'SALIDA', child: Text('Salida')),
                 ],
                 onChanged: (v) => setState(() => type = v!),
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                 final rawData = controller.text.trim();
                 if (!rawData.startsWith('employee/')) {
                    Navigator.pop(context); // Close input dialog
                    _showErrorDialog('NO es un empleado válido ❌\nPor favor, escanea un código de empleado.');
                    return;
                 }
                 
                 final employeeId = rawData.split('/')[1];
                 if (employeeId.isEmpty) return;

                 Navigator.pop(context); // Close dialog
                 await _registerAttendance(employeeId, type);
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerAttendance(String employeeId, String type) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final payload = {
        'employeeId': employeeId,
        'type': type,
        'supervisorId': 'SUPERVISOR_DEV_USER', // In real app, get from Cognito User Sub
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _apiService.post('/attendance', payload);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asistencia registrada: $type ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        String errorMessage = e.toString();
        // Try to extract the JSON error message from the exception string
        // The ApiService throws "Error 404: { "error": "..." }" or "Network Error: ..."
        if (errorMessage.contains('{') && errorMessage.contains('}')) {
          try {
             final startIndex = errorMessage.indexOf('{');
             final endIndex = errorMessage.lastIndexOf('}');
             final jsonStr = errorMessage.substring(startIndex, endIndex + 1);
             final errorMap = jsonDecode(jsonStr); // Needs dart:convert import, but ApiService uses it, so it might work if imported or we add import
             if (errorMap.containsKey('error')) {
               errorMessage = errorMap['error'];
             }
          } catch (_) {
            // If parsing fails, use the original message
          }
        } else if (errorMessage.startsWith('Exception: ')) {
           errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }

        _showErrorDialog(errorMessage);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      appBar: AppBar(
        title: const Text('Gestión de Empleados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _showAttendanceModal,
            tooltip: 'Tomar Asistencia',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
               builder: (_) => const EmployeeFormScreen(fixedProfile: 'OBRERO'),
            ),
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
                final isSelf = false; // Add logic if needed
                return Card(
                  child: ListTile(
                    title: Text('${emp['nombre']} ${emp['apellidoPaterno']}'),
                    subtitle: Text('${emp['puesto']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                             await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmployeeFormScreen(
                                     employee: emp,
                                     fixedProfile: emp['puesto'] == 'OBRERO' ? 'OBRERO' : null // Optional restriction
                                  )
                                ),
                             );
                             _fetchEmployees();
                          },
                        ),
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
