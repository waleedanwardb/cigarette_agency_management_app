// lib/UI/screens/products/add_edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final productService = Provider.of<ProductService>(context, listen: false);

      final newProduct = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        brand: _selectedBrand!.name,
        brandId: _selectedBrand!.id,
        price: double.parse(_priceController.text.trim()),
        inStock: int.parse(_stockController.text.trim()) > 0,
        stockQuantity: int.parse(_stockController.text.trim()),
        isFrozen: widget.product?.isFrozen ?? false,
        imageUrl: widget.product?.imageUrl ?? '',
      );

      if (widget.product == null) {
        await productService.addProduct(newProduct, _pickedImage);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
      } else {
        await productService.updateProduct(newProduct, newImage: _pickedImage);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully!')));
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandService = Provider.of<BrandService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add New Product' : 'Edit Product'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (PKR)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value!) == null ? 'Please enter a valid number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value!) == null ? 'Please enter a valid integer' : null,
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Brand>>(
                stream: brandService.getBrands(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  final brands = snapshot.data ?? [];
                  if (brands.isEmpty) {
                    return const Text('No brands found. Please add a brand first.');
                  }
                  return DropdownButtonFormField<Brand>(
                    decoration: const InputDecoration(labelText: 'Select Brand', border: OutlineInputBorder()),
                    value: _selectedBrand,
                    onChanged: (Brand? newValue) {
                      setState(() {
                        _selectedBrand = newValue;
                      });
                    },
                    items: brands.map((brand) {
                      return DropdownMenuItem<Brand>(
                        value: brand,
                        child: Text(brand.name),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Please select a brand' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Product Image'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              if (_pickedImage != null) ...[
                const SizedBox(height: 16),
                Image.file(_pickedImage!, height: 150),
              ] else if (widget.product?.imageUrl.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Image.network(widget.product!.imageUrl, height: 150),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text(widget.product == null ? 'Add Product' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}