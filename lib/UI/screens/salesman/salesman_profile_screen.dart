// lib/UI/screens/salesman/salesman_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cigarette_agency_management_app/models/salesman.dart';

class SalesmanProfileScreen extends StatelessWidget {
  final Salesman salesman;

  const SalesmanProfileScreen({super.key, required this.salesman});

  Widget _buildImageSection(String title, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (imageUrl != null && imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
            },
          )
        else
          const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salesman Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: salesman.imageUrl.isNotEmpty
                    ? NetworkImage(salesman.imageUrl)
                    : null,
                child: salesman.imageUrl.isEmpty
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                salesman.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text('Contact Information', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Phone Number: ${salesman.phoneNumber}'),
            Text('Contact Number: ${salesman.contactNumber}'),
            Text('Emergency Contact: ${salesman.emergencyContactNumber}'),
            Text('Address: ${salesman.address}'),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text('Official Details', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('ID Card Number: ${salesman.idCardNumber}'),
            _buildImageSection('ID Card Front', salesman.idCardFrontUrl),
            _buildImageSection('ID Card Back', salesman.idCardBackUrl),
          ],
        ),
      ),
    );
  }
}
