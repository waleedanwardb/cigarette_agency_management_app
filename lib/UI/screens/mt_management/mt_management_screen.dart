// lib/UI/screens/mt_management/mt_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cigarette_agency_management_app/services/mt_service.dart';

class MTManagementScreen extends StatefulWidget {
  const MTManagementScreen({super.key});

  @override
  State<MTManagementScreen> createState() => _MTManagementScreenState();
}

class _MTManagementScreenState extends State<MTManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mtNameController = TextEditingController();

  Future<void> _addMT(BuildContext dialogContext) async {
    if (_formKey.currentState!.validate()) {
      final mtService = Provider.of<MTService>(dialogContext, listen: false);
      try {
        await mtService.addMTName(_mtNameController.text);
        if (mounted) {
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('MT scheme added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(content: Text('Failed to add MT scheme: $e')),
          );
        }
      }
    }
  }

  void _confirmDelete(String mtName) {
    final mtService = Provider.of<MTService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete the MT scheme "$mtName"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await mtService.deleteMTName(mtName);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('MT scheme deleted successfully!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddMTDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (dialogContext, setStateInDialog) {
            return AlertDialog(
              title: const Text('Add New MT Scheme'),
              content: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _mtNameController,
                  decoration: const InputDecoration(labelText: 'MT Scheme Name'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a name';
                    }
                    // NEW: Add a check for invalid characters
                    if (value.contains('/')) {
                      return 'MT scheme name cannot contain a "/"';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setStateInDialog(() => isLoading = true);
                    // Only proceed if validation passes
                    if (_formKey.currentState!.validate()) {
                      await _addMT(dialogContext);
                    }
                    setStateInDialog(() => isLoading = false);
                  },
                  child: isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mtService = Provider.of<MTService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MT Management'),
      ),
      body: StreamBuilder<List<String>>(
        stream: mtService.getMTNames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final mtNames = snapshot.data ?? [];
          if (mtNames.isEmpty) {
            return const Center(child: Text('No MT schemes available.'));
          }
          return ListView.builder(
            itemCount: mtNames.length,
            itemBuilder: (context, index) {
              final mtName = mtNames[index];
              return ListTile(
                title: Text(mtName),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(mtName),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMTDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
