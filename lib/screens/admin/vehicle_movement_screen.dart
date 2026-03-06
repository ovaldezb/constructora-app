import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../supervisor/qr_scanner_screen.dart';

class VehicleMovementScreen extends StatefulWidget {
  const VehicleMovementScreen({super.key});

  @override
  State<VehicleMovementScreen> createState() => _VehicleMovementScreenState();
}

class _VehicleMovementScreenState extends State<VehicleMovementScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _vehicleQrController = TextEditingController();
  final _employeeQrController = TextEditingController();
  String _type = 'ENTRADA'; // ENTRADA | SALIDA
  final _comentarioController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _vehicleQrController.dispose();
    _employeeQrController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  String _extractId(String qrData) {
    if (qrData.contains('/')) {
      return qrData.split('/').last.trim();
    }
    return qrData.trim();
  }

  Future<void> _scanQR(TextEditingController controller) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && result is String) {
      if (mounted) {
        controller.text = result;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final vehicleQr = _vehicleQrController.text.trim();
    final employeeQr = _employeeQrController.text.trim();

    if (vehicleQr.isEmpty || employeeQr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese vehículo y empleado')));
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'vehicleId': _extractId(vehicleQr),
      'employeeId': _extractId(employeeQr),
      'type': _type,
      'comentario': _comentarioController.text.trim(),
    };

    try {
      await _apiService.post('/vehicle-records', payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movimiento registrado exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Tipo de Movimiento', border: OutlineInputBorder()),
                      value: _type,
                      items: const [
                        DropdownMenuItem(value: 'ENTRADA', child: Text('ENTRADA')),
                        DropdownMenuItem(value: 'SALIDA', child: Text('SALIDA')),
                      ],
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleQrController,
                      decoration: InputDecoration(
                        labelText: 'Ingresar QR del Vehículo',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.directions_car),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                          onPressed: () => _scanQR(_vehicleQrController),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        if (!value.startsWith('vehiculo/')) return 'Debe ser un QR de vehículo válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _employeeQrController,
                      decoration: InputDecoration(
                        labelText: 'Ingresar QR del Empleado',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                          onPressed: () => _scanQR(_employeeQrController),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        if (!value.startsWith('employee/')) return 'Debe ser un QR de empleado válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _comentarioController,
                      decoration: const InputDecoration(labelText: 'Comentario (Opcional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                            child: const Text('Guardar Movimiento', style: TextStyle(fontSize: 16)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
