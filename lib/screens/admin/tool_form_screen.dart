import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ToolFormScreen extends StatefulWidget {
  final Map<String, dynamic>? tool;
  const ToolFormScreen({super.key, this.tool});

  @override
  State<ToolFormScreen> createState() => _ToolFormScreenState();
}

class _ToolFormScreenState extends State<ToolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Field controllers
  final _descripcionController = TextEditingController(); // Acts as Name/Description
  final _serieController = TextEditingController();
  final _tipoController = TextEditingController();
  final _comentarioController = TextEditingController();
  
  String _estado = 'DISPONIBLE'; 
  bool _isLoading = false;
  bool _isActivo = true;

  // Edit mode flags
  bool get _isEditing => widget.tool != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.tool!;
      _descripcionController.text = t['descripcion'] ?? '';
      _serieController.text = t['numeroSerie'] ?? '';
      _tipoController.text = t['tipo'] ?? '';
      _comentarioController.text = t['comentario'] ?? '';
      _estado = t['estado'] ?? 'DISPONIBLE';
      _isActivo = t['isActivo'] ?? true;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'descripcion': _descripcionController.text.trim(),
        'numeroSerie': _serieController.text.trim(),
        'tipo': _tipoController.text.trim(),
        'comentario': _comentarioController.text.trim(),
        'estado': _estado,
        'isActivo': _isActivo,
      };

      if (_isEditing) {
        await _apiService.put('/tools/${widget.tool!['_id']}', payload);
      } else {
        await _apiService.post('/tools', payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Herramienta ${_isEditing ? 'actualizada' : 'registrada'} correctamente ✅')),
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
      appBar: AppBar(title: Text(_isEditing ? 'Editar Herramienta' : 'Alta de Herramienta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descripcionController, // Used as Name
                decoration: const InputDecoration(labelText: 'Descripción / Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tipoController,
                decoration: const InputDecoration(labelText: 'Tipo (ej. Eléctrica, Manual)'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _serieController,
                decoration: const InputDecoration(labelText: 'Número de Serie (Opcional)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'DISPONIBLE', child: Text('Disponible 🟢')),
                  DropdownMenuItem(value: 'PRESTADO', child: Text('Prestado 🔴')),
                  DropdownMenuItem(value: 'EN_REPARACION', child: Text('En Reparación 🟠')),
                  DropdownMenuItem(value: 'BAJA', child: Text('Baja ⚫')),
                ],
                onChanged: (v) => setState(() => _estado = v!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _comentarioController,
                decoration: const InputDecoration(labelText: 'Comentarios / Notas'),
                maxLines: 2,
              ),
              if (_isEditing)
                SwitchListTile(
                  title: const Text('Activo en Sistema'),
                  subtitle: const Text('Desactivar para ocultar de listas generales'),
                  value: _isActivo,
                  onChanged: (v) => setState(() => _isActivo = v),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isEditing ? 'Guardar Cambios' : 'Registrar Herramienta'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
