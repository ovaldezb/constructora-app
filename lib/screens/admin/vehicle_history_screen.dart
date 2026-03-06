import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class VehicleHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleHistoryScreen({super.key, required this.vehicle});

  @override
  State<VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<VehicleHistoryScreen> {
  final _apiService = ApiService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.get('/vehicle-records/${widget.vehicle['_id']}');
      
      if (mounted) {
        setState(() {
          // Take only the top 5 records (assuming the backend sorts them by timestamp DESC)
          final List<dynamic> records = data as List<dynamic>;
          _history = records.take(5).toList();
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

  @override
  Widget build(BuildContext context) {
    final title = '${widget.vehicle['modelo']} - ${widget.vehicle['placas']}';

    return Scaffold(
      appBar: AppBar(title: Text('Historial: $title')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No hay movimientos registrados para este vehículo.', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final record = _history[index];
                    final isEntrada = record['type'] == 'ENTRADA';
                    
                    final employee = record['employeeId'];
                    final employeeName = employee != null ? '${employee['nombre']} ${employee['apellidoPaterno']}' : 'Desconocido';
                    
                    final dateRaw = record['timestamp'] != null ? DateTime.parse(record['timestamp']) : null;
                    final dateStr = dateRaw != null ? DateFormat('dd/MM/yyyy HH:mm').format(dateRaw.toLocal()) : 'Fecha Desconocida';
                    
                    List<String> photos = [];
                    if (record['photoUrls'] != null) {
                      photos = List<String>.from(record['photoUrls']);
                    } else if (record['photoUrl'] != null) {
                      photos = [record['photoUrl']];
                    }
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEntrada ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          child: Icon(
                            isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isEntrada ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          isEntrada ? 'ENTRADA' : 'SALIDA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isEntrada ? Colors.green : Colors.orange,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 4),
                            Text('Conductor: $employeeName'),
                            Text('Fecha: $dateStr'),
                            if (record['comentario'] != null && record['comentario'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Comentario: ${record['comentario']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                              ),
                            if (photos.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: photos.length,
                                    itemBuilder: (context, idx) {
                                      final url = photos[idx];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                child: Image.network(url, fit: BoxFit.contain),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url, width: 80, height: 80, fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
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
