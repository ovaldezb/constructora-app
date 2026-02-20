import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../../services/api_service.dart';
import 'tool_form_screen.dart';

class ToolManagementScreen extends StatefulWidget {
  const ToolManagementScreen({super.key});

  @override
  State<ToolManagementScreen> createState() => _ToolManagementScreenState();
}

class _ToolManagementScreenState extends State<ToolManagementScreen> {
  final _apiService = ApiService();
  List<dynamic> _tools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTools();
  }

  Future<void> _fetchTools() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.get('/tools');
      if (mounted) {
        setState(() {
          _tools = data as List<dynamic>;
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

  Future<void> _deleteTool(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar (dar de baja) esta herramienta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/tools/$id');
        _fetchTools(); // Refresh list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DISPONIBLE': return Colors.green;
      case 'PRESTADO': return Colors.red;
      case 'EN_REPARACION': return Colors.orange;
      case 'BAJA': return Colors.black54;
      default: return Colors.grey;
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
      final path = '${directory.path}/qr_$name.png';
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

  void _showQRDialog(Map<String, dynamic> tool) {
    final GlobalKey qrKey = GlobalKey();
    final String qrData = tool['qrUrl'] ?? 'tool/${tool['_id']}';
    final String name = tool['descripcion'];

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
                      tool['numeroSerie'] ?? 'S/N',
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
              onPressed: () => _saveQrImage(qrKey, tool['_id']),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Herramientas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ToolFormScreen()),
          );
          _fetchTools();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                final tool = _tools[index];
                final isActive = tool['isActivo'] ?? true;
                final status = tool['estado'] ?? 'DISPONIBLE';
                
                return Card(
                  color: isActive ? Colors.white : Colors.grey[200],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      child: Icon(Icons.build, color: _getStatusColor(status)),
                    ),
                    title: Text(
                      tool['descripcion'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isActive ? null : TextDecoration.lineThrough,
                        color: isActive ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo: ${tool['tipo']}'),
                        if (tool['numeroSerie'] != null && tool['numeroSerie'].toString().isNotEmpty)
                          Text('Serie: ${tool['numeroSerie']}'),
                        Text(status, style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ToolFormScreen(tool: tool)),
                            );
                            _fetchTools();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: Colors.black),
                          onPressed: () => _showQRDialog(tool),
                        ),
                        if (isActive)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTool(tool['_id']),
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
