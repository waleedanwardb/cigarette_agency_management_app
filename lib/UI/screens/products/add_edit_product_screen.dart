import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/models/brand.dart';
import 'package:cigarette_agency_management_app/services/product_service.dart';
import 'package:cigarette_agency_management_app/services/brand_service.dart';


class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  Brand? _selectedBrand;
  File? _productImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '');

    if (widget.product != null) {
      _selectedBrand = Brand.dummyBrands.firstWhere((b) => b.id == widget.product!.brandId, orElse: () => Brand.dummyBrands.first);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _productImage = File(pickedFile.path);
      });
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final productService = Provider.of<ProductService>(context, listen: false);
      final isEditing = widget.product != null;

      final productToSave = Product(
        id: isEditing ? widget.product!.id : DateTime.now().millisecondsSinceEpoch.toString(), // FIX: Using timestamp for ID
        name: _nameController.text,
        brand: _selectedBrand!.name,
        brandId: _selectedBrand!.id,
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        imageUrl: widget.product?.imageUrl ?? '',
        isFrozen: isEditing ? widget.product!.isFrozen : false,
        createdAt: isEditing ? widget.product!.createdAt : Timestamp.now(),
      );

      try {
        if (isEditing) {
          await productService.updateProduct(productToSave, imageFile: _productImage);
        } else {
          await productService.addProduct(productToSave, imageFile: _productImage);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product "${productToSave.name}" ${isEditing ? 'updated' : 'added'}!')));
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving product: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Failed to save product.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final brandService = Provider.of<BrandService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
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
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _productImage != null
                        ? FileImage(_productImage!)
                        : (widget.product?.imageUrl.isNotEmpty ?? false ? NetworkImage(widget.product!.imageUrl) : null) as ImageProvider<Object>?,
                    child: (_productImage == null && (widget.product?.imageUrl.isEmpty ?? true))
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<Brand>>(
                stream: brandService.getBrands(),
                builder: (context, snapshot) {
                  final brands = snapshot.data ?? [];
                  return DropdownButtonFormField<Brand>(
                    decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
                    value: _selectedBrand,
                    items: brands.map((brand) => DropdownMenuItem<Brand>(value: brand, child: Text(brand.name))).toList(),
                    onChanged: (brand) => setState(() { _selectedBrand = brand; }),
                    validator: (value) => value == null ? 'Select a brand' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()), validator: (value) => value!.isEmpty ? 'Enter name' : null),
              const SizedBox(height: 20),
              TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per Pack', border: OutlineInputBorder()), validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter valid price' : null),
              const SizedBox(height: 20),
              TextFormField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()), validator: (value) => (value == null || int.tryParse(value) == null) ? 'Enter valid quantity' : null),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _saveProduct, child: const Text('Save Product')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}