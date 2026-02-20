import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'product_form_screen.dart';

class ProductInventoryScreen extends StatefulWidget {
  const ProductInventoryScreen({super.key});

  @override
  State<ProductInventoryScreen> createState() => _ProductInventoryScreenState();
}

class _ProductInventoryScreenState extends State<ProductInventoryScreen> {
  final _apiService = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final productsData = await _apiService.get('/products');
      final locationsData = await _apiService.get('/locations');
      if (mounted) {
        setState(() {
          _products = productsData as List<dynamic>;
          _locations = locationsData as List<dynamic>;
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

  Future<void> _fetchProducts() async {
     try {
       final data = await _apiService.get('/products');
       if (mounted) setState(() => _products = data as List<dynamic>);
     } catch (e) {
       print(e);
     }
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar este producto y todo su historial?\nEsta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.delete('/products/$id');
        await _fetchProducts();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerMovement(Map<String, dynamic> product) async {
    final quantityController = TextEditingController();
    String type = 'ENTRADA';
    String? locationId = _locations.isNotEmpty ? _locations[0]['_id'] : null;

    if (_locations.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay locaciones registradas. Crea una primero.')));
       return;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Movimiento: ${product['nombre']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock Actual: ${product['cantidad']} ${product['unidad']}'),
              const SizedBox(height: 20),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Movimiento',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada (Agregar) 🟢')),
                  DropdownMenuItem(value: 'SALIDA', child: Text('Salida (Restar) 🔴')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              if (type == 'SALIDA') ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: locationId,
                  decoration: const InputDecoration(
                    labelText: 'Locación de Destino',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations.map<DropdownMenuItem<String>>((loc) {
                    return DropdownMenuItem(
                      value: loc['_id'],
                      child: Text(loc['nombre']),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => locationId = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final qty = int.tryParse(quantityController.text);
      if (qty == null || qty <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cantidad inválida')));
        return;
      }
      
      if (type == 'SALIDA' && locationId == null) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locación de destino requerida para salidas')));
         return;
      }

      setState(() => _isLoading = true);
      try {
        final payload = {
          'productId': product['_id'],
          'quantity': qty,
          'type': type,
          if (type == 'SALIDA') 'locationId': locationId,
        };

        await _apiService.post('/inventory', payload);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Movimiento registrado: $type $qty ${product['unidad']}')),
          );
        }
        _fetchProducts();
        setState(() => _isLoading = false);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _showHistory(Map<String, dynamic> product) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final historyData = await _apiService.get('/inventory/${product['_id']}');
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final history = historyData as List<dynamic>;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Allow full height control
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75, // Take 75% of screen height
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Historial: ${product['nombre']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              // Content
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text('No hay movimientos registrados', style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final isEntry = item['type'] == 'ENTRADA';
                          final date = DateTime.tryParse(item['timestamp'])?.toLocal().toString().split('.')[0] ?? item['timestamp'];
                          final locationName = item['locationId'] is Map ? item['locationId']['nombre'] : (item['locationId'] ?? '---');

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isEntry ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              child: Icon(
                                isEntry ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isEntry ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              '${isEntry ? "Entrada" : "Salida"} de ${item['quantity']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Fecha: $date\nLocación: $locationName'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar historial: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<AuthService>(context, listen: false).userProfile;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de Productos')),
      floatingActionButton: userProfile == 'ADMIN' ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          _fetchProducts();
        },
        child: const Icon(Icons.add),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      child: const Icon(Icons.inventory_2, color: Colors.purple),
                    ),
                    title: Text(product['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Stock: ${product['cantidad']} ${product['unidad']}'),
                    onTap: () => _registerMovement(product),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'history') {
                          _showHistory(product);
                        } else if (value == 'edit') {
                           await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
                            );
                            _fetchProducts();
                        } else if (value == 'delete') {
                          _deleteProduct(product['_id']);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        final List<PopupMenuEntry<String>> options = [
                           const PopupMenuItem<String>(
                            value: 'history',
                            child: Row(children: [Icon(Icons.history, color: Colors.blueGrey), SizedBox(width: 8), Text('Historial')]),
                          ),
                        ];
                        
                        if (userProfile == 'ADMIN') {
                          options.add(const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Editar')]),
                          ));
                          options.add(const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Eliminar')]),
                          ));
                        }
                        return options;
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
