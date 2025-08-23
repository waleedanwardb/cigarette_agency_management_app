// lib/UI/screens/salesman/add_salesman_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cigarette_agency_management_app/models/salesman.dart';
import 'package:cigarette_agency_management_app/services/salesman_service.dart';

class AddSalesmanScreen extends StatefulWidget {
  final Salesman? salesman;

  const AddSalesmanScreen({super.key, this.salesman});

  @override
  State<AddSalesmanScreen> createState() => _AddSalesmanScreenState();
}

class _AddSalesmanScreenState extends State<AddSalesmanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idCardNumberController;
  late TextEditingController _addressController;
  late TextEditingController _contactNumberController;
  late TextEditingController _emergencyContactNumberController;

  File? _salesmanPic;
  File? _idCardFrontPic;
  File? _idCardBackPic;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.salesman?.name ?? '');
    _idCardNumberController = TextEditingController(text: widget.salesman?.idCardNumber ?? '');
    _addressController = TextEditingController(text: widget.salesman?.address ?? '');
    _contactNumberController = TextEditingController(text: widget.salesman?.contactNumber ?? '');
    _emergencyContactNumberController = TextEditingController(text: widget.salesman?.emergencyContactNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardNumberController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _emergencyContactNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(File?) setImage) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        setImage(File(pickedFile.path));
      });
    }
  }

  void _addEditSalesman() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final isEditing = widget.salesman != null;
      final salesmanService = Provider.of<SalesmanService>(context, listen: false);

      final newOrUpdatedSalesman = Salesman(
        id: isEditing ? widget.salesman!.id : '', // Firestore will generate new ID
        name: _nameController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        emergencyContactNumber: _emergencyContactNumberController.text.trim(),
        isFrozen: isEditing ? widget.salesman!.isFrozen : false,
        imageUrl: widget.salesman?.imageUrl ?? '',
      );

      try {
        if (isEditing) {
          await salesmanService.updateSalesman(newOrUpdatedSalesman, profilePic: _salesmanPic);
        } else {
          await salesmanService.addSalesman(newOrUpdatedSalesman, profilePic: _salesmanPic);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salesman "${newOrUpdatedSalesman.name}" ${isEditing ? 'updated' : 'added'} successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Failed to save salesman data.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.salesman != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Salesman Profile' : 'Add New Salesman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery, (file) => _salesmanPic = file),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _salesmanPic != null
                        ? FileImage(_salesmanPic!)
                        : (widget.salesman?.imageUrl.isNotEmpty ?? false ? NetworkImage(widget.salesman!.imageUrl) : null) as ImageProvider<Object>?,
                    child: (_salesmanPic == null && (widget.salesman?.imageUrl.isEmpty ?? true))
                        ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, (file) => _salesmanPic = file),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Salesman Picture'),
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Salesman Name',
                  hintText: 'Enter full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter salesman name' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _idCardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID Card Number',
                  hintText: 'e.g., 12345-6789012-3',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter ID card number' : null,
                readOnly: isEditing,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter full address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter address' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'e.g., +923XXYYYYYYY',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter contact number' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _emergencyContactNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                  hintText: 'e.g., +923XXYYYYYYY',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emergency),
                ),
              ),
              const SizedBox(height: 30),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _addEditSalesman,
                    icon: Icon(isEditing ? Icons.save : Icons.person_add),
                    label: Text(isEditing ? 'Update Salesman' : 'Add Salesman'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}