// lib/UI/screens/arrears/arrears_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cigarette_agency_management_app/models/arrear.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';

class ArrearsScreen extends StatefulWidget {
  const ArrearsScreen({super.key});

  @override
  State<ArrearsScreen> createState() => _ArrearsScreenState();
}

class _ArrearsScreenState extends State<ArrearsScreen> {
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  Salesman? _selectedSalesmanFilter;
  String? _filterStatus;

  Future<void> _showAddEditArrearDialog({Arrear? arrearToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final isEditing = arrearToEdit != null;
    Salesman? selectedSalesman;
    final TextEditingController amountController =
    TextEditingController(text: arrearToEdit?.amount.toString());
    final TextEditingController descriptionController =
    TextEditingController(text: arrearToEdit?.description);
    DateTime? dateIncurred = arrearToEdit?.dateIncurred ?? DateTime.now();
    bool _isLoadingSalesmen = true;

    if (isEditing) {
      final salesmanService = Provider.of<SalesmanService>(context, listen: false);
      try {
        final salesmen = await salesmanService.getSalesmen().first;
        selectedSalesman = salesmen.firstWhere((s) => s.id == arrearToEdit!.salesmanId);
      } catch (e) {
        debugPrint('Error finding salesman for arrear: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not find salesman for this arrear.')));
        }
        return;
      }
    }

    final result = await showDialog<Arrear>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Arrear' : 'Add New Arrear'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<List<Salesman>>(
                        stream: Provider.of<SalesmanService>(context, listen: false).getSalesmen(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No salesmen available.');
                          }
                          final salesmen = snapshot.data!;
                          return DropdownButtonFormField<Salesman>(
                            decoration: const InputDecoration(
                                labelText: 'Select Salesman', border: OutlineInputBorder()),
                            value: selectedSalesman,
                            items: salesmen.map((salesman) {
                              return DropdownMenuItem<Salesman>(
                                  value: salesman, child: Text(salesman.name));
                            }).toList(),
                            onChanged: isEditing
                                ? null
                                : (value) {
                              setStateInDialog(() {
                                selectedSalesman = value;
                              });
                            },
                            validator: (value) => value == null ? 'Select a salesman' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Amount (PKR)', border: OutlineInputBorder()),
                        validator: (value) => (value == null || double.tryParse(value) == null || double.parse(value) <= 0) ? 'Enter valid amount' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: dateIncurred != null ? DateFormat('yyyy-MM-dd').format(dateIncurred!) : ''),
                        decoration: const InputDecoration(
                            labelText: 'Date Incurred', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dateIncurred ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101));
                          if (picked != null) {
                            setStateInDialog(() {
                              dateIncurred = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && selectedSalesman != null && dateIncurred != null) {
                      final newArrear = Arrear(
                        id: isEditing ? arrearToEdit!.id : '',
                        salesmanId: selectedSalesman!.id,
                        salesmanName: selectedSalesman!.name,
                        dateIncurred: dateIncurred!,
                        amount: double.parse(amountController.text),
                        description: descriptionController.text,
                        status: isEditing ? arrearToEdit!.status : 'Outstanding',
                        clearanceDate:
                        isEditing ? arrearToEdit!.clearanceDate : null,
                        clearanceDescription: isEditing
                            ? arrearToEdit!.clearanceDescription
                            : null,
                      );
                      Navigator.of(dialogContext).pop(newArrear);
                    }
                  },
                  child: Text(isEditing ? 'Update Arrear' : 'Add Arrear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final salesmanService =
      Provider.of<SalesmanService>(context, listen: false);
      if (isEditing) {
        await salesmanService.updateArrear(result);
      } else {
        await salesmanService.addArrear(result);
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arrear "${result.description}" ${isEditing ? 'updated' : 'added'}!')));
    }
    amountController.dispose();
    descriptionController.dispose();
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating report... (Placeholder)')),
    );
  }

  void _markAsCollected(Arrear arrear) async {
    final salesmanService = Provider.of<SalesmanService>(context, listen: false);
    final updatedArrear = arrear.copyWith(
      status: 'Cleared',
      clearanceDate: DateTime.now(),
      clearanceDescription: 'Collected on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
    );
    await salesmanService.updateArrear(updatedArrear);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arrear for ${arrear.salesmanName} has been cleared.')));
  }

  @override
  Widget build(BuildContext context) {
    final salesmanService = Provider.of<SalesmanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrears'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                /* Navigate to profile */
              }),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<Arrear>>(
        stream: salesmanService.getArrears(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allArrears = snapshot.data ?? [];
          final filteredArrears = allArrears.where((arrear) {
            final date = arrear.dateIncurred;
            bool matchesDate = (_filterStartDate == null || date.isAfter(_filterStartDate!)) && (_filterEndDate == null || date.isBefore(_filterEndDate!));
            bool matchesSalesman = _selectedSalesmanFilter == null || arrear.salesmanId == _selectedSalesmanFilter!.id;
            bool matchesStatus = _filterStatus == null || arrear.status == _filterStatus;
            return matchesDate && matchesSalesman && matchesStatus;
          }).toList();

          double totalOutstandingAmount = filteredArrears
              .where((a) => a.status == 'Outstanding')
              .fold(0.0, (sum, a) => sum + a.amount);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  color: Colors.red.shade100, // Using .shade100 to avoid deprecation
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Outstanding Arrears:',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900)),
                        Text(
                          'PKR ${totalOutstandingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text('Filter Arrears',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                StreamBuilder<List<Salesman>>(
                  stream: salesmanService.getSalesmen(),
                  builder: (context, salesmanSnapshot) {
                    if (salesmanSnapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!salesmanSnapshot.hasData || salesmanSnapshot.data!.isEmpty) {
                      return const Text('No salesmen available.');
                    }
                    final salesmen = salesmanSnapshot.data!;
                    return DropdownButtonFormField<Salesman>(
                      decoration: const InputDecoration(
                          labelText: 'Filter by Salesman', border: OutlineInputBorder()),
                      value: _selectedSalesmanFilter,
                      items: salesmen.map((salesman) {
                        return DropdownMenuItem<Salesman>(
                            value: salesman, child: Text(salesman.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSalesmanFilter = value;
                        });
                      },
                      hint: const Text('All Salesmen'),
                    );
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Filter by Status', border: OutlineInputBorder()),
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Outstanding', child: Text('Outstanding')),
                    DropdownMenuItem(value: 'Cleared', child: Text('Cleared')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: _filterStartDate == null
                                ? ''
                                : DateFormat('yyyy-MM-dd')
                                .format(_filterStartDate!)),
                        decoration: const InputDecoration(
                            labelText: 'From Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _filterStartDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101));
                          if (picked != null) {
                            setState(() {
                              _filterStartDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: _filterEndDate == null
                                ? ''
                                : DateFormat('yyyy-MM-dd')
                                .format(_filterEndDate!)),
                        decoration: const InputDecoration(
                            labelText: 'To Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _filterEndDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101));
                          if (picked != null) {
                            setState(() {
                              _filterEndDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterStartDate = null;
                        _filterEndDate = null;
                        _selectedSalesmanFilter = null;
                        _filterStatus = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredArrears.length,
                    itemBuilder: (context, index) {
                      final arrear = filteredArrears[index];
                      Color statusColor = arrear.status == 'Cleared'
                          ? Colors.green
                          : Colors.orange;
                      TextDecoration? textDecoration =
                      arrear.status == 'Cleared'
                          ? TextDecoration.lineThrough
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          title: Text(
                              'PKR ${arrear.amount.toStringAsFixed(2)} - ${arrear.salesmanName}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  decoration: textDecoration)),
                          subtitle: Text(arrear.description,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  decoration: textDecoration)),
                          trailing: arrear.status == 'Outstanding'
                              ? IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () => _markAsCollected(arrear),
                          )
                              : Chip(
                            label: Text(arrear.status,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                            backgroundColor: statusColor,
                          ),
                          onTap: () => _showAddEditArrearDialog(arrearToEdit: arrear),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditArrearDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Arrear'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}