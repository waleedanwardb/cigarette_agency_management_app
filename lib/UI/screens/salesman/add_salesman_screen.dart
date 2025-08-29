// lib/UI/screens/salesman/add_salesman_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  late TextEditingController _idCardNumberController;
  late TextEditingController _contactNumberController;
  late TextEditingController _emergencyContactNumberController;

  File? _pickedProfilePic;
  File? _pickedIdCardFrontPic;
  File? _pickedIdCardBackPic;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.salesman?.name ?? '');
    _phoneNumberController = TextEditingController(text: widget.salesman?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.salesman?.address ?? '');
    _idCardNumberController = TextEditingController(text: widget.salesman?.idCardNumber ?? '');
    _contactNumberController = TextEditingController(text: widget.salesman?.contactNumber ?? '');
    _emergencyContactNumberController = TextEditingController(text: widget.salesman?.emergencyContactNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _emergencyContactNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(File) onPick) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        onPick(File(pickedFile.path));
      });
    }
  }

  Future<void> _saveSalesman() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final salesmanService = Provider.of<SalesmanService>(context, listen: false);

      final newSalesman = Salesman(
        id: widget.salesman?.id ?? '',
        name: _nameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        address: _addressController.text.trim(),
        idCardNumber: _idCardNumberController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        emergencyContactNumber: _emergencyContactNumberController.text.trim(),
        isFrozen: widget.salesman?.isFrozen ?? false,
        imageUrl: widget.salesman?.imageUrl ?? '',
        idCardFrontUrl: widget.salesman?.idCardFrontUrl ?? '',
        idCardBackUrl: widget.salesman?.idCardBackUrl ?? '',
      );

      try {
        if (widget.salesman == null) {
          await salesmanService.addSalesman(
            newSalesman,
            profilePic: _pickedProfilePic,
            idCardFrontPic: _pickedIdCardFrontPic,
            idCardBackPic: _pickedIdCardBackPic,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salesman added successfully!')),
          );
        } else {
          await salesmanService.updateSalesman(
            newSalesman,
            profilePic: _pickedProfilePic,
            idCardFrontPic: _pickedIdCardFrontPic,
            idCardBackPic: _pickedIdCardBackPic,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salesman updated successfully!')),
          );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save salesman: $e')),
        );
      } finally {
        if (!mounted) return;
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
        title: Text(widget.salesman == null ? 'Add Salesman' : 'Edit Salesman'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _pickedProfilePic != null
                          ? FileImage(_pickedProfilePic!)
                          : (widget.salesman?.imageUrl != null && widget.salesman!.imageUrl.isNotEmpty
                          ? NetworkImage(widget.salesman!.imageUrl)
                          : null) as ImageProvider?,
                      child: (_pickedProfilePic == null && (widget.salesman?.imageUrl == null || widget.salesman!.imageUrl.isEmpty))
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery, (file) {
                        setState(() {
                          _pickedProfilePic = file;
                        });
                      }),
                      icon: const Icon(Icons.photo),
                      label: const Text('Pick Profile Picture'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter a contact number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactNumberController,
                decoration: const InputDecoration(labelText: 'Emergency Contact Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter an emergency contact number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idCardNumberController,
                decoration: const InputDecoration(labelText: 'ID Card Number', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter an ID card number' : null,
              ),
              const SizedBox(height: 24),
              // ID Card Images Section
              const Text('ID Card Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _pickedIdCardFrontPic != null
                            ? Image.file(_pickedIdCardFrontPic!, height: 100, fit: BoxFit.cover)
                            : (widget.salesman?.idCardFrontUrl != null && widget.salesman!.idCardFrontUrl!.isNotEmpty
                            ? Image.network(widget.salesman!.idCardFrontUrl!, height: 100, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 100, color: Colors.grey)),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery, (file) {
                            setState(() {
                              _pickedIdCardFrontPic = file;
                            });
                          }),
                          icon: const Icon(Icons.credit_card),
                          label: const Text('ID Card Front'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _pickedIdCardBackPic != null
                            ? Image.file(_pickedIdCardBackPic!, height: 100, fit: BoxFit.cover)
                            : (widget.salesman?.idCardBackUrl != null && widget.salesman!.idCardBackUrl!.isNotEmpty
                            ? Image.network(widget.salesman!.idCardBackUrl!, height: 100, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 100, color: Colors.grey)),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery, (file) {
                            setState(() {
                              _pickedIdCardBackPic = file;
                            });
                          }),
                          icon: const Icon(Icons.credit_card),
                          label: const Text('ID Card Back'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSalesman,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.salesman == null ? 'Add Salesman' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
