import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _unidadController = TextEditingController();
  final _cantidadController = TextEditingController(); // Stock Inicial

  bool _isLoading = false;
  
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nombreController.text = p['nombre'] ?? '';
      _descripcionController.text = p['descripcion'] ?? '';
      _unidadController.text = p['unidad'] ?? '';
      _cantidadController.text = (p['cantidad'] ?? 0).toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'unidad': _unidadController.text.trim(),
        // Cantidad is sent only on creation or if we decide to allow direct edit.
        // Plan said read-only for edit, but let's send it if creating.
        if (!_isEditing) 'cantidad': int.tryParse(_cantidadController.text) ?? 0,
      };

      if (_isEditing) {
        await _apiService.put('/products/${widget.product!['_id']}', payload);
      } else {
        await _apiService.post('/products', payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto ${_isEditing ? 'actualizado' : 'registrado'} correctamente ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Producto' : 'Alta de Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _unidadController,
                decoration: const InputDecoration(labelText: 'Unidad de Medida (ej. pza, kg, m, lto)'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cantidadController,
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Stock Actual (Gestionar en Inventario)' : 'Stock Inicial',
                  suffixText: _unidadController.text,
                ),
                keyboardType: TextInputType.number,
                enabled: !_isEditing, // Read-only in edit mode
                validator: (v) => !_isEditing && v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_isEditing ? 'Guardar Cambios' : 'Registrar Producto'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
