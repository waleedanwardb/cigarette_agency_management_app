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
  final Brand? brand; // Pass brand for pre-selection

  const AddEditProductScreen({super.key, this.product, this.brand});

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
  String? _initialImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '0');
    _initialImageUrl = widget.product?.imageUrl;

    // FIX: Await the data fetch and set the initial brand synchronously in initState
    _loadInitialData();
  }

  // NEW: Helper function to load data and set initial state
  Future<void> _loadInitialData() async {
    final brandService = Provider.of<BrandService>(context, listen: false);
    final brands = await brandService.getBrands().first;

    if (mounted && brands.isNotEmpty) {
      Brand? initialBrand;
      if (widget.product != null) {
        initialBrand = brands.firstWhere(
              (b) => b.id == widget.product!.brandId,
          orElse: () => brands.first,
        );
      } else if (widget.brand != null) {
        initialBrand = brands.firstWhere(
              (b) => b.id == widget.brand!.id,
          orElse: () => brands.first,
        );
      }

      setState(() {
        _selectedBrand = initialBrand ?? brands.first;
      });
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _initialImageUrl = null; // Clear initial image if a new one is picked
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && _selectedBrand != null) {
      final productService = Provider.of<ProductService>(context, listen: false);

      final newProduct = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        brand: _selectedBrand!.name,
        brandId: _selectedBrand!.id,
        price: double.parse(_priceController.text.trim()),
        inStock: (int.tryParse(_stockController.text.trim()) ?? 0) > 0,
        stockQuantity: int.tryParse(_stockController.text.trim()) ?? 0,
        isFrozen: widget.product?.isFrozen ?? false,
        imageUrl: widget.product?.imageUrl ?? '',
      );

      try {
        if (widget.product == null) {
          await productService.addProduct(newProduct, _pickedImage);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
        } else {
          await productService.updateProduct(newProduct, newImage: _pickedImage);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully!')));
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save product: $e')));
        }
      }
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
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final brands = snapshot.data ?? [];
                  if (brands.isEmpty) {
                    return const Text('No brands found. Please add a brand first.');
                  }

                  // FIX: Set the initial value for the dropdown from the stream
                  if (_selectedBrand == null && widget.product != null) {
                    try {
                      _selectedBrand = brands.firstWhere((b) => b.id == widget.product!.brandId);
                    } catch (e) {
                      _selectedBrand = brands.first;
                    }
                  } else if (widget.brand != null) {
                    try {
                      _selectedBrand = brands.firstWhere((b) => b.id == widget.brand!.id);
                    } catch (e) {
                      _selectedBrand = brands.first;
                    }
                  } else if (_selectedBrand == null) {
                    _selectedBrand = brands.first;
                  }

                  // Ensure _selectedBrand is a valid object from the new list
                  final currentSelectedBrand = brands.firstWhere(
                        (b) => b.id == (_selectedBrand?.id ?? ''),
                    orElse: () => brands.first,
                  );


                  return DropdownButtonFormField<Brand>(
                    decoration: const InputDecoration(labelText: 'Select Brand', border: OutlineInputBorder()),
                    // FIX: Set the dropdown value to an instance from the live list
                    value: currentSelectedBrand,
                    onChanged: (Brand? newValue) {
                      setState(() {
                        _selectedBrand = newValue;
                      });
                    },
                    items: brands.map((brand) {
                      return DropdownMenuItem<Brand>(
                        // FIX: Use a unique key for each dropdown item to prevent assertion errors
                        key: ValueKey(brand.id),
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
              ] else if (_initialImageUrl != null && _initialImageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Image.network(_initialImageUrl!, height: 150,
                  // FIX: Add an errorBuilder to prevent crashes on image load failure
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Failed to load image.');
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Icon(Icons.image, size: 150, color: Colors.grey),
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
