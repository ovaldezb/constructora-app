import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'qr_scanner_screen.dart';

class SupervisorToolScreen extends StatefulWidget {
  const SupervisorToolScreen({super.key});

  @override
  State<SupervisorToolScreen> createState() => _SupervisorToolScreenState();
}

class _SupervisorToolScreenState extends State<SupervisorToolScreen> {
  final _apiService = ApiService();
  final _employeeIdController = TextEditingController();
  final _toolIdController = TextEditingController();
  final _commentController = TextEditingController();
  String _type = 'SALIDA';
  bool _isLoading = false;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.get('/tool-records');
      if (mounted) {
        setState(() {
          _history = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Silent error or simple log for history fetch
        print('Error fetching history: $e');
      }
    }
  }

  Future<void> _scanQR(TextEditingController controller) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && result is String) {
      controller.text = result;
    }
  }

  Future<void> _registerMovement() async {
    final rawEmployeeId = _employeeIdController.text.trim();
    final rawToolId = _toolIdController.text.trim();
    final comment = _commentController.text.trim();

    if (rawEmployeeId.isEmpty || rawToolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa ID de Empleado y Herramienta')),
      );
      return;
    }

    // Validation for Employee ID
    if (!rawEmployeeId.startsWith('employee/')) {
       _showErrorDialog('ID de Empleado inválido ❌\nDebe comenzar con "employee/"');
       return;
    }

    // Validation for Tool ID
    if (!rawToolId.startsWith('tool/')) {
       _showErrorDialog('ID de Herramienta inválido ❌\nDebe comenzar con "tool/"');
       return;
    }

    // Extract actual IDs
    final employeeId = rawEmployeeId.split('/')[1];
    final toolId = rawToolId.split('/')[1];

    if (employeeId.isEmpty || toolId.isEmpty) {
       _showErrorDialog('IDs vacíos después del prefijo.');
       return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'employeeId': employeeId,
        'toolId': toolId,
        'type': _type,
        'comentario': comment,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _apiService.post('/tool-records', payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Movimiento registrado: $_type ✅')),
        );
        _employeeIdController.clear();
        _toolIdController.clear();
        _commentController.clear();
        _fetchHistory();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Try to extract JSON error
        if (errorMessage.contains('{') && errorMessage.contains('}')) {
          try {
             final startIndex = errorMessage.indexOf('{');
             final endIndex = errorMessage.lastIndexOf('}');
             final jsonStr = errorMessage.substring(startIndex, endIndex + 1);
             final errorMap = jsonDecode(jsonStr);
             if (errorMap.containsKey('error')) {
               errorMessage = errorMap['error'];
             } else if (errorMap.containsKey('message')) {
                errorMessage = errorMap['message'];
             }
          } catch (_) {}
        } else if (errorMessage.startsWith('Exception: ')) {
           errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        _showErrorDialog('Error al registrar movimiento:\n$errorMessage');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Herramientas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Registrar Movimiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _employeeIdController,
                      decoration: InputDecoration(
                        labelText: 'ID Empleado',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                          onPressed: () => _scanQR(_employeeIdController),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _toolIdController,
                      decoration: InputDecoration(
                        labelText: 'ID Herramienta',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.construction),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                          onPressed: () => _scanQR(_toolIdController),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Movimiento',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'SALIDA', child: Text('Salida (Préstamo) 📤')),
                        DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada (Devolución) 📥')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comentarios',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.comment),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerMovement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('REGISTRAR MOVIMIENTO', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Historial Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _isLoading && _history.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay movimientos registrados')))
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _history.length > 10 ? 10 : _history.length, // Show last 10
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final isExit = item['type'] == 'SALIDA';
                          final date = DateTime.tryParse(item['timestamp'])?.toLocal().toString().split('.')[0] ?? item['timestamp'];
                          
                          // Handle populated fields or ID strings
                          String toolName = item['toolId'] is Map ? item['toolId']['descripcion'] : (item['toolId'] ?? 'Desconocida');
                          if (item['toolId'] is Map && item['toolId']['numeroSerie'] != null) {
                            toolName += ' (${item['toolId']['numeroSerie']})';
                          }
                          
                          String empName = item['employeeId'] is Map 
                              ? '${item['employeeId']['nombre']} ${item['employeeId']['apellidoPaterno']}' 
                              : (item['employeeId'] ?? 'Desconocido');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isExit ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                child: Icon(
                                  isExit ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isExit ? Colors.orange : Colors.green,
                                ),
                              ),
                              title: Text('$toolName - $empName'),
                              subtitle: Text('$date\n${item['comentario'] ?? ''}'),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
