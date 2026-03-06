import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class VehicleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _placasController = TextEditingController();
  final _vinController = TextEditingController();
  final _modeloController = TextEditingController();
  final _modelyearController = TextEditingController();
  bool _isActivo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _placasController.text = widget.vehicle!['placas'] ?? '';
      _vinController.text = widget.vehicle!['vin'] ?? '';
      _modeloController.text = widget.vehicle!['modelo'] ?? '';
      _modelyearController.text = widget.vehicle!['modelyear']?.toString() ?? '';
      _isActivo = widget.vehicle!['isActivo'] ?? true;
    }
  }

  @override
  void dispose() {
    _placasController.dispose();
    _vinController.dispose();
    _modeloController.dispose();
    _modelyearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'placas': _placasController.text.trim(),
      'vin': _vinController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'modelyear': int.tryParse(_modelyearController.text.trim()) ?? 0,
      'isActivo': _isActivo,
    };

    try {
      if (widget.vehicle == null) {
        await _apiService.post('/vehicles', payload);
      } else {
        await _apiService.put('/vehicles/${widget.vehicle!['_id']}', payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo guardado exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Vehículo' : 'Nuevo Vehículo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _placasController,
                      decoration: const InputDecoration(labelText: 'Placas', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vinController,
                      decoration: const InputDecoration(labelText: 'VIN', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modeloController,
                      decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelyearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Año Modelo', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    if (isEditing)
                      SwitchListTile(
                        title: const Text('Activo'),
                        value: _isActivo,
                        onChanged: (val) => setState(() => _isActivo = val),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        child: const Text('Guardar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
