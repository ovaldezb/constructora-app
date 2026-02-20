import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? employee;
  final String? fixedProfile; // New optional parameter
  const EmployeeFormScreen({super.key, this.employee, this.fixedProfile});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _paternoController = TextEditingController();
  final _maternoController = TextEditingController();
  
  String _puesto = 'OBRERO';
  String _tipoEmpleado = 'FIJO'; // FIJO | ITINERANTE
  bool _isLoading = false;
  
  bool _assignLocation = false;
  List<dynamic> _locations = [];
  String? _selectedLocationId;
  
  // Edit mode flags
  bool get _isEditing => widget.employee != null;
  bool _isActivo = true;

  @override
  void initState() {
    super.initState();
    if (widget.fixedProfile != null) {
      _puesto = widget.fixedProfile!;
    }

    if (_isEditing) {
      // Pre-fill data
      final emp = widget.employee!;
      _nombreController.text = emp['nombre'];
      _paternoController.text = emp['apellidoPaterno'];
      _maternoController.text = emp['apellidoMaterno'];
      
      if (widget.fixedProfile != null) {
         _puesto = widget.fixedProfile!;
      } else {
        const validPuestos = ['ADMIN', 'SUPERVISOR', 'OBRERO'];
        String incomingPuesto = emp['puesto'] ?? 'OBRERO';
        
        // Normalize or default if value doesn't match
        if (!validPuestos.contains(incomingPuesto)) {
          if (incomingPuesto.toLowerCase().contains('supervisor')) {
            _puesto = 'SUPERVISOR';
          } else if (incomingPuesto.toLowerCase().contains('admin')) {
            _puesto = 'ADMIN';
          } else {
            _puesto = 'OBRERO';
          }
        } else {
          _puesto = incomingPuesto;
        }
      }
      
      _tipoEmpleado = emp['tipoEmpleado'];
      _isActivo = emp['isActivo'] ?? true;
      
      // Handle location assignment if exists
      if (emp['idLocacion'] != null) {
        _assignLocation = true;
        // Check if idLocacion is populated object or string id
        if (emp['idLocacion'] is Map) {
          _selectedLocationId = emp['idLocacion']['_id'];
        } else if (emp['idLocacion'] is String) {
          _selectedLocationId = emp['idLocacion'];
        }
      }
    }
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final data = await _apiService.get('/locations');
      if (mounted) {
        setState(() {
          // Filter only active locations
          _locations = (data as List<dynamic>).where((l) => l['isActivo'] == true).toList();
        });
      }
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_assignLocation && _selectedLocationId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una locación')),
        );
        return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'nombre': _nombreController.text.trim(),
        'apellidoPaterno': _paternoController.text.trim(),
        'apellidoMaterno': _maternoController.text.trim(),
        'puesto': _puesto,
        'tipoEmpleado': _tipoEmpleado,
        'idLocacion': _assignLocation ? _selectedLocationId : null,
        'isActivo': _isActivo,
      };

      if (_isEditing) {
        await _apiService.put('/employees/${widget.employee!['_id']}', payload);
      } else {
        await _apiService.post('/employees', payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Empleado ${_isEditing ? 'actualizado' : 'registrado'} correctamente ✅')),
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
      appBar: AppBar(title: Text(_isEditing ? 'Editar Empleado' : 'Alta de Empleado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _paternoController,
                decoration: const InputDecoration(labelText: 'Apellido Paterno'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _maternoController,
                decoration: const InputDecoration(labelText: 'Apellido Materno'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              if (widget.fixedProfile == null)
                DropdownButtonFormField<String>(
                  value: _puesto,
                  decoration: const InputDecoration(labelText: 'Puesto'),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                    DropdownMenuItem(value: 'SUPERVISOR', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'OBRERO', child: Text('Obrero')),
                  ],
                  onChanged: (v) => setState(() => _puesto = v!),
                )
              else
                TextFormField(
                  initialValue: widget.fixedProfile,
                  decoration: const InputDecoration(labelText: 'Puesto', filled: true, fillColor: Colors.black12),
                  readOnly: true,
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tipoEmpleado,
                decoration: const InputDecoration(labelText: 'Tipo de Empleado'),
                items: const [
                  DropdownMenuItem(value: 'FIJO', child: Text('Fijo')),
                  DropdownMenuItem(value: 'ITINERANTE', child: Text('Itinerante')),
                ],
                onChanged: (v) => setState(() => _tipoEmpleado = v!),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Asignar Locación'),
                value: _assignLocation,
                onChanged: (v) => setState(() {
                  _assignLocation = v;
                  if (!v) _selectedLocationId = null;
                }),
              ),
              if (_assignLocation)
                DropdownButtonFormField<String>(
                  value: _selectedLocationId,
                  decoration: const InputDecoration(labelText: 'Seleccionar Locación'),
                  items: _locations.map<DropdownMenuItem<String>>((loc) {
                    return DropdownMenuItem<String>(
                      value: loc['_id'],
                      child: Text(loc['nombre']),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedLocationId = v),
                  validator: (v) => _assignLocation && v == null ? 'Requerido' : null,
                ),
              if (_isEditing)
                SwitchListTile(
                  title: const Text('Empleado Activo'),
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
                      child: Text(_isEditing ? 'Guardar Cambios' : 'Registrar Empleado'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
