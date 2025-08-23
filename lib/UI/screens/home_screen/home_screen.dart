// lib/UI/screens/home_screen/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:cigarette_agency_management_app/UI/screens/dashboard/dashboard_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/salesman/salesman_stock_list_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/payments/payments_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/widgets/app_drawer.dart';
import 'package:cigarette_agency_management_app/UI/screens/products/brand_products_list_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/stock/stock_main_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/scheme_management/scheme_management_screen.dart';

import 'package:cigarette_agency_management_app/models/brand.dart';
import 'package:cigarette_agency_management_app/models/product.dart';
import 'package:cigarette_agency_management_app/services/product_service.dart';
import 'package:cigarette_agency_management_app/services/brand_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index != 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => [
          const HomeScreen(),
          const DashboardScreen(),
          const StockMainScreen(),
          const PaymentsMainScreen()
        ][index]),
      );
    }
  }

  void _showBrandOptions(BuildContext context, Brand brand, BrandService brandService) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Brand'),
                onTap: () {
                  Navigator.pop(bc);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit ${brand.name} functionality!')),
                  );
                },
              ),
              ListTile(
                leading: Icon(brand.isFrozen ? Icons.person_add_disabled : Icons.person_off),
                title: Text(brand.isFrozen ? 'Unfreeze Brand' : 'Freeze Brand'),
                onTap: () async {
                  Navigator.pop(bc);
                  await brandService.updateBrand(brand.copyWith(isFrozen: !brand.isFrozen));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${brand.name} is now ${brand.isFrozen ? 'unfrozen' : 'frozen'}!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Brand'),
                onTap: () {
                  Navigator.pop(bc);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete brand "${brand.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await brandService.deleteBrand(brand.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${brand.name} deleted!')));
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

  void _showProductOptions(BuildContext context, Product product, ProductService productService) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Product'),
                onTap: () {
                  Navigator.pop(bc);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit ${product.name} functionality!')),
                  );
                },
              ),
              ListTile(
                leading: Icon(product.isFrozen ? Icons.unarchive : Icons.archive),
                title: Text(product.isFrozen ? 'Unfreeze Product' : 'Freeze Product'),
                onTap: () async {
                  Navigator.pop(bc);
                  await productService.updateProduct(product.copyWith(isFrozen: !product.isFrozen));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} is now ${product.isFrozen ? 'frozen' : 'unfrozen'}!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Product'),
                onTap: () {
                  Navigator.pop(bc);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete product "${product.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await productService.deleteProduct(product.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} deleted!')));
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

  Future<void> _showAddBrandDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    File? _pickedImage;
    bool _isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Add New Brand'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Brand Name'),
                        validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 10),
                      if (_pickedImage != null)
                        Image.file(_pickedImage!, height: 100, width: 100, fit: BoxFit.contain)
                      else
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () async {
                            final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setStateInDialog(() {
                                _pickedImage = File(pickedFile.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                      const SizedBox(height: 10),
                      if (_isLoading) const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      setStateInDialog(() {
                        _isLoading = true;
                      });

                      final brandService = Provider.of<BrandService>(context, listen: false);
                      final newBrand = Brand(
                        id: '',
                        name: _nameController.text.trim(),
                        icon: '📦',
                        isFrozen: false,
                        imageUrl: '',
                      );
                      await brandService.addBrand(newBrand, brandLogo: _pickedImage);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Brand added successfully!')),
                      );

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save Brand'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddProductDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _priceController = TextEditingController();
    final _stockController = TextEditingController();
    Brand? _selectedBrand;
    File? _pickedImage;
    bool _isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Product Name'),
                        validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) => double.tryParse(value!) == null ? 'Please enter a valid price' : null,
                      ),
                      TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Stock Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (value) => int.tryParse(value!) == null ? 'Please enter a valid quantity' : null,
                      ),
                      StreamBuilder<List<Brand>>(
                        stream: Provider.of<BrandService>(context, listen: false).getBrands(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No brands available.');
                          }

                          final brands = snapshot.data!;
                          // Fix for the crash: find the actual instance from the fetched list
                          if (_selectedBrand != null) {
                            try {
                              _selectedBrand = brands.firstWhere((brand) => brand.id == _selectedBrand!.id);
                            } catch (e) {
                              // If the previously selected brand is no longer in the list, reset it
                              _selectedBrand = null;
                            }
                          }

                          return DropdownButtonFormField<Brand>(
                            decoration: const InputDecoration(labelText: 'Brand'),
                            value: _selectedBrand,
                            items: brands.map((brand) {
                              return DropdownMenuItem<Brand>(
                                value: brand,
                                child: Text(brand.name),
                              );
                            }).toList(),
                            onChanged: (Brand? newValue) {
                              setStateInDialog(() {
                                _selectedBrand = newValue;
                              });
                            },
                            validator: (value) => value == null ? 'Please select a brand' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_pickedImage != null)
                        Image.file(_pickedImage!, height: 100, width: 100, fit: BoxFit.contain)
                      else
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () async {
                            final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setStateInDialog(() {
                                _pickedImage = File(pickedFile.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                      const SizedBox(height: 10),
                      if (_isLoading) const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate() && _selectedBrand != null) {
                      setStateInDialog(() {
                        _isLoading = true;
                      });

                      final productService = Provider.of<ProductService>(context, listen: false);
                      final newProduct = Product(
                        id: '',
                        name: _nameController.text.trim(),
                        brand: _selectedBrand!.name,
                        brandId: _selectedBrand!.id,
                        price: double.parse(_priceController.text.trim()),
                        inStock: int.parse(_stockController.text.trim()) > 0,
                        stockQuantity: int.parse(_stockController.text.trim()),
                        isFrozen: false,
                        imageUrl: '',
                      );
                      await productService.addProduct(newProduct, _pickedImage);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added successfully!')),
                      );

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save Product'),
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
    final brandService = Provider.of<BrandService>(context);
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cigarette Management Agency'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Brands', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<List<Brand>>(
                stream: brandService.getBrands(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No brands found.'));
                  }

                  final brands = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 1.2,
                    ),
                    itemCount: brands.length,
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => BrandProductsListScreen(brand: brand)));
                        },
                        onLongPress: () => _showBrandOptions(context, brand, brandService),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: brand.isFrozen ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (brand.imageUrl.isNotEmpty)
                                      Image.network(brand.imageUrl, height: 60, width: 60, fit: BoxFit.contain)
                                    else
                                      const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(brand.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                              if (brand.isFrozen)
                                const Positioned(top: 8, right: 8, child: Icon(Icons.ac_unit, color: Colors.red, size: 24)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              const Text('All Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<List<Product>>(
                stream: productService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  final products = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: product.isFrozen ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none),
                        child: InkWell(
                          onTap: () {},
                          onLongPress: () => _showProductOptions(context, product, productService),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      child: product.imageUrl.isNotEmpty
                                          ? Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                                          : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(product.brand, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        Text('PKR ${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        if (product.inStock)
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)), child: Text('Stock: ${product.stockQuantity}', style: TextStyle(color: Colors.green[700], fontSize: 10)))
                                        else
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)), child: Text('Out of Stock', style: TextStyle(color: Colors.red[700], fontSize: 10))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (product.isFrozen)
                                const Positioned(top: 8, right: 8, child: Icon(Icons.lock, color: Colors.blue, size: 24)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext bc) {
              return SafeArea(
                child: Wrap(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.group),
                      title: const Text('Add Brand'),
                      onTap: () {
                        Navigator.pop(bc);
                        _showAddBrandDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.add_shopping_cart),
                      title: const Text('Add Product'),
                      onTap: () {
                        Navigator.pop(bc);
                        _showAddProductDialog();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}