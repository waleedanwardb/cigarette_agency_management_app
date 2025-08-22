// lib/UI/screens/stock/lighter_stock_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cigarette_agency_management_app/models/lighter_stock.dart'; // Import the LighterStock model

class LighterStockScreen extends StatefulWidget {
  const LighterStockScreen({super.key});

  @override
  State<LighterStockScreen> createState() => _LighterStockScreenState();
}

class _LighterStockScreenState extends State<LighterStockScreen> {
  final List<LighterStock> _lighterStock = List.from(LighterStock.dummyLighterStocks);

  void _showAddEditLighterStockDialog({LighterStock? stockToEdit}) {
    final _formKey = GlobalKey<FormState>();
    final isEditing = stockToEdit != null;
    final TextEditingController nameController = TextEditingController(text: stockToEdit?.name);
    final TextEditingController descriptionController = TextEditingController(text: stockToEdit?.description);
    final TextEditingController stockController = TextEditingController(text: stockToEdit?.currentStock.toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Lighter Stock' : 'Add New Lighter Stock'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Current Stock', border: OutlineInputBorder()),
                    validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter valid stock' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newStock = LighterStock(
                    id: isEditing ? stockToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descriptionController.text,
                    currentStock: double.parse(stockController.text),
                    lastReceived: isEditing ? stockToEdit!.lastReceived : DateTime.now(),
                    lastIssued: isEditing ? stockToEdit!.lastIssued : DateTime.now(),
                  );
                  Navigator.of(dialogContext).pop(newStock);
                }
              },
              child: Text(isEditing ? 'Update Stock' : 'Add Stock'),
            ),
          ],
        );
      },
    ).then((result) {
      if (result != null && result is LighterStock) {
        setState(() {
          if (isEditing) {
            final index = _lighterStock.indexWhere((s) => s.id == result.id);
            if (index != -1) _lighterStock[index] = result;
          } else {
            _lighterStock.insert(0, result);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lighter stock ${isEditing ? 'updated' : 'added'}!')));
      }
      nameController.dispose();
      descriptionController.dispose();
      stockController.dispose();
    });
  }

  void _showStockOptions(BuildContext context, LighterStock stock) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.edit), title: const Text('Edit Stock'), onTap: () { Navigator.pop(bc); _showAddEditLighterStockDialog(stockToEdit: stock); }),
              ListTile(leading: const Icon(Icons.delete), title: const Text('Delete Stock'), onTap: () { Navigator.pop(bc); _confirmDeleteStock(stock); }),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteStock(LighterStock stock) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${stock.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() { _lighterStock.removeWhere((s) => s.id == stock.id); });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock for "${stock.name}" deleted!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating lighter stock report... (Placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lighter Stock'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () { Navigator.of(context).pop(); },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () { /* Navigate to profile */ }),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Summary Card
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              color: Colors.blue[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Lighter Stock:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                    Text(
                      '${_lighterStock.fold(0.0, (sum, item) => sum + item.currentStock).toStringAsFixed(0)} units',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _lighterStock.isEmpty
                ? Center(
              child: Text(
                'No lighter stock to display.\nTap "+" to add a new stock item.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: _lighterStock.length,
                itemBuilder: (context, index) {
                  final stock = _lighterStock[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        stock.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description: ${stock.description}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                          Text('Current Stock: ${stock.currentStock.toStringAsFixed(0)} units', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text('Last Received: ${DateFormat('yyyy-MM-dd').format(stock.lastReceived)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showStockOptions(context, stock),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.download),
                label: const Text('Generate Report (Excel/PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditLighterStockDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Lighter Stock'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}