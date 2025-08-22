// lib/UI/screens/salesman/add_salesman_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For File operations
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For using Timestamp
import 'package:flutter/foundation.dart';

// Import models and services
import 'package:cigarette_agency_management_app/models/salesman.dart'; // Import Salesman model
import 'package:cigarette_agency_management_app/services/salesman_service.dart'; // Import SalesmanService

class AddSalesmanScreen extends StatefulWidget {
  final Salesman? salesman; // Optional salesman for editing

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
      final isEditing = widget.salesman != null;
      final salesmanService = Provider.of<SalesmanService>(context, listen: false);

      // Create a new Salesman object from form data
      final newOrUpdatedSalesman = Salesman(
        id: isEditing ? widget.salesman!.id : _idCardNumberController.text, // Use existing ID or new ID card no. as ID
        name: _nameController.text,
        idCardNumber: _idCardNumberController.text,
        address: _addressController.text,
        contactNumber: _contactNumberController.text,
        emergencyContactNumber: _emergencyContactNumberController.text,
        isFrozen: isEditing ? widget.salesman!.isFrozen : false,
        imageUrl: widget.salesman?.imageUrl ?? '', // Preserve existing URL if not updating
        createdAt: isEditing ? widget.salesman!.createdAt : Timestamp.now(), // Preserve existing timestamp
      );

      try {
        // Call the service to add/update with images
        if (isEditing) {
          await salesmanService.updateSalesman(newOrUpdatedSalesman, profilePic: _salesmanPic, idFrontPic: _idCardFrontPic, idBackPic: _idCardBackPic);
        } else {
          await salesmanService.addSalesman(newOrUpdatedSalesman, profilePic: _salesmanPic, idFrontPic: _idCardFrontPic, idBackPic: _idCardBackPic);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salesman "${newOrUpdatedSalesman.name}" ${isEditing ? 'updated' : 'added'} successfully!')),
        );
        Navigator.pop(context, newOrUpdatedSalesman); // Return the updated salesman to the list screen
      } catch (e) {
        // Handle errors from Firebase operations
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Failed to save salesman data.')),
        );
        debugPrint('Firebase Error: $e');
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
              // Salesman Picture
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

              // Salesman Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Salesman Name',
                  hintText: 'Enter full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter salesman name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ID Card
              TextFormField(
                controller: _idCardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID Card Number',
                  hintText: 'e.g., 12345-6789012-3',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ID card number';
                  }
                  return null;
                },
                readOnly: isEditing, // ID card number fixed if editing
              ),
              const SizedBox(height: 20),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter full address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Contact
              TextFormField(
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'e.g., +923XXYYYYYYY',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Emergency Contact
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

              // ID Card Pictures (Optional)
              const Text(
                'ID Card Pictures (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            image: _idCardFrontPic != null
                                ? DecorationImage(image: FileImage(_idCardFrontPic!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _idCardFrontPic == null
                              ? Center(child: Icon(Icons.image, size: 40, color: Colors.grey[400]))
                              : null,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery, (file) => _idCardFrontPic = file),
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Front ID'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            image: _idCardBackPic != null
                                ? DecorationImage(image: FileImage(_idCardBackPic!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _idCardBackPic == null
                              ? Center(child: Icon(Icons.image, size: 40, color: Colors.grey[400]))
                              : null,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery, (file) => _idCardBackPic = file),
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Back ID'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
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