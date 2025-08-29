// lib/UI/screens/salesman/salesman_stock_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';
import 'package:cigarette_agency_management_app/UI/widgets/app_drawer.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/add_salesman_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_stock_detail_screen.dart';



class SalesmanStockListScreen extends StatefulWidget {
  const SalesmanStockListScreen({super.key});

  @override
  State<SalesmanStockListScreen> createState() => _SalesmanStockListScreenState();
}

class _SalesmanStockListScreenState extends State<SalesmanStockListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  File? _pickedImage;
  bool _isLoading = false;

  void _showSalesmanOptions(BuildContext context, Salesman salesman) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalesmanStockDetailScreen(salesman: salesman),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Salesman'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddSalesmanScreen(salesman: salesman),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(salesman.isFrozen ? Icons.lock_open : Icons.lock),
                title: Text(salesman.isFrozen ? 'Unfreeze Salesman' : 'Freeze Salesman'),
                onTap: () async {
                  Navigator.pop(bc);
                  final salesmanService = Provider.of<SalesmanService>(context, listen: false);
                  await salesmanService.updateSalesman(salesman.copyWith(isFrozen: !salesman.isFrozen));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${salesman.name} is now ${salesman.isFrozen ? 'unfrozen' : 'frozen'}!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Salesman'),
                onTap: () {
                  Navigator.pop(bc);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete salesman "${salesman.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final salesmanService = Provider.of<SalesmanService>(context, listen: false);
                            await salesmanService.deleteSalesman(salesman.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${salesman.name} deleted!')),
                            );
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesmanService = Provider.of<SalesmanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salesman List'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<Salesman>>(
        stream: salesmanService.getSalesmen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final salesmen = snapshot.data ?? [];
          if (salesmen.isEmpty) {
            return const Center(child: Text('No salesmen found.'));
          }
          return ListView.builder(
            itemCount: salesmen.length,
            itemBuilder: (context, index) {
              final salesman = salesmen[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: salesman.isFrozen
                      ? const BorderSide(color: Colors.red, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: salesman.imageUrl.isNotEmpty
                        ? NetworkImage(salesman.imageUrl)
                        : null,
                    child: salesman.imageUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(salesman.name),
                  subtitle: Text(salesman.phoneNumber),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showSalesmanOptions(context, salesman),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalesmanStockDetailScreen(salesman: salesman),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSalesmanScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
