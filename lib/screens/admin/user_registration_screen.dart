import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({Key? key}) : super(key: key);

  @override
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  String _givenName = '';
  String _familyName = '';
  String _middleName = '';
  String _email = '';
  String _profile = 'SUPERVISOR'; // Default

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final confirmList = [
      'Nombre: $_givenName',
      'Apellido: $_familyName',
      if (_middleName.isNotEmpty) 'Materno: $_middleName',
      'Correo: $_email',
      'Perfil: $_profile'
    ];

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmar Alta de Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro de crear un usuario con los siguientes datos?'),
              const SizedBox(height: 12),
              ...confirmList.map((str) => Text('• $str', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Confirmar y Crear'),
            ),
          ],
        );
      },
    );

    if (shouldCreate != true) return; // User cancelled

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'given_name': _givenName,
        'family_name': _familyName,
        'middle_name': _middleName.isNotEmpty ? _middleName : null,
        'email': _email.trim(),
        'profile': _profile,
      };

      await _apiService.createUser(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado exitosamente. Recibirá un correo con su acceso temporal.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar usuario: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Usuario'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      onSaved: (value) => _givenName = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Apellido Paterno'),
                      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      onSaved: (value) => _familyName = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Apellido Materno (Opcional)'),
                      onSaved: (value) => _middleName = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                         if (value == null || value.trim().isEmpty) return 'Requerido';
                         final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+");
                         if (!emailRegex.hasMatch(value.trim())) return 'Ingresa un correo válido (ej. usuario@dominio.com)';
                         return null;
                      },
                      onSaved: (value) => _email = value!.trim(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _profile,
                      decoration: const InputDecoration(labelText: 'Perfil de Acceso'),
                      items: const [
                        DropdownMenuItem(value: 'SUPERVISOR', child: Text('Supervisor')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _profile = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Crear Usuario'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
