import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );

    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ?? initialDateRange,
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }

  Future<void> _downloadReport() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un rango de fechas')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String startDateStr = formatter.format(_selectedDateRange!.start);
      final String endDateStr = formatter.format(_selectedDateRange!.end);

      final endpoint = '/attendance/report?startDate=$startDateStr&endDate=$endDateStr';
      final responseBytes = await _apiService.getRaw(endpoint);

      final xFile = XFile.fromData(
        responseBytes as Uint8List,
        name: 'reporte_asistencia_${startDateStr}_${endDateStr}.csv',
        mimeType: 'text/csv',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Reporte de Asistencia del $startDateStr al $endDateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar el reporte: $e')),
        );
      }
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
        title: const Text('Reportes de Asistencia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_month, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Selecciona el Rango de Fechas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.date_range),
                      label: Text(_selectedDateRange == null
                          ? 'Elegir Fechas'
                          : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _downloadReport,
                icon: const Icon(Icons.download),
                label: const Text('Descargar Reporte CSV'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
