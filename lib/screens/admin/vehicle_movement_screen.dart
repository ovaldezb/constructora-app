import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
  
  List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _takePhoto() async {
    if (_imageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máximo 5 fotos permitidas')));
      return;
    }
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFiles.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
      }
    }
  }

  Future<String?> _uploadPhotoToS3(File image) async {
    try {
      final fileName = image.path.split('/').last;
      
      // Get presigned URL and public read URL from our backend
      final response = await _apiService.get('/upload-url?filename=$fileName');
      final uploadUrl = response['uploadUrl'];
      final readUrl = response['readUrl'];

      if (uploadUrl == null || readUrl == null) {
        throw Exception('No urls returned from backend');
      }

      // Upload directly to S3
      final bytes = await image.readAsBytes();
      final putResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: bytes,
      );

      if (putResponse.statusCode == 200) {
        return readUrl;
      } else {
        throw Exception('S3 upload failed with status ${putResponse.statusCode}');
      }
    } catch (e) {
      print('S3 Upload Error: $e');
      return null;
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

    List<String> photoUrls = [];
    if (_imageFiles.isNotEmpty) {
      for (var file in _imageFiles) {
        final url = await _uploadPhotoToS3(file);
        if (url != null) {
          photoUrls.add(url);
        }
      }
      if (photoUrls.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error subiendo las fotos')));
        setState(() => _isSubmitting = false);
        return;
      }
    }

    final payload = {
      'vehicleId': _extractId(vehicleQr),
      'employeeId': _extractId(employeeQr),
      'type': _type,
      'comentario': _comentarioController.text.trim(),
      if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: Text('Tomar Foto (${_imageFiles.length}/5)'),
                            onPressed: _imageFiles.length < 5 ? _takePhoto : null,
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_imageFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_imageFiles[index], width: 120, height: 120, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imageFiles.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      color: Colors.black54,
                                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
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
