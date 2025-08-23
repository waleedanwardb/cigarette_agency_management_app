// lib/UI/screens/company_claims/company_claims_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:cigarette_agency_management_app/services/company_claim_service.dart';

class CompanyClaimsScreen extends StatefulWidget {
  const CompanyClaimsScreen({super.key});

  @override
  State<CompanyClaimsScreen> createState() => _CompanyClaimsScreenState();
}

class _CompanyClaimsScreenState extends State<CompanyClaimsScreen> {
  String? _filterStatus;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  void _showClaimOptions(BuildContext context, CompanyClaim claim, CompanyClaimService claimService) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Claimed'),
                onTap: () async {
                  Navigator.pop(bc);
                  await _markClaimAsPaid(claim, claimService);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Claim'),
                onTap: () {
                  Navigator.pop(bc);
                  _confirmDeleteClaim(claim, claimService);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markClaimAsPaid(CompanyClaim claim, CompanyClaimService claimService) async {
    final updatedClaim = claim.copyWith(status: 'Claimed');
    try {
      await claimService.updateCompanyClaim(updatedClaim);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claim for ${claim.companyName} marked as claimed.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update claim: $e')),
      );
    }
  }

  void _confirmDeleteClaim(CompanyClaim claim, CompanyClaimService claimService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this claim (PKR ${claim.amount.toStringAsFixed(2)})?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await claimService.deleteCompanyClaim(claim.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Claim deleted successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyClaimService = Provider.of<CompanyClaimService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Claims'),
        elevation: 0,
      ),
      body: StreamBuilder<List<CompanyClaim>>(
        stream: companyClaimService.getCompanyClaims(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allClaims = snapshot.data ?? [];
          final filteredClaims = allClaims.where((claim) {
            final date = claim.dateIncurred;
            bool matchesDate = (_filterStartDate == null || date.isAfter(_filterStartDate!)) &&
                (_filterEndDate == null || date.isBefore(_filterEndDate!));
            bool matchesStatus = _filterStatus == null || claim.status == _filterStatus;
            return matchesDate && matchesStatus;
          }).toList();

          double totalOutstandingClaims = filteredClaims
              .where((c) => c.status == 'Pending')
              .fold(0.0, (sum, c) => sum + c.amount);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 4,
                  color: Colors.blue.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pending Claims:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text(
                          'PKR ${totalOutstandingClaims.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text('Filter Claims', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Filter by Status', border: OutlineInputBorder()),
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Claimed', child: Text('Claimed')),
                  ],
                  onChanged: (value) { setState(() { _filterStatus = value; }); },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: _filterStartDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterStartDate!)),
                        decoration: const InputDecoration(labelText: 'From Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(context: context, initialDate: _filterStartDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                          if (picked != null) { setState(() { _filterStartDate = picked; }); }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: _filterEndDate == null ? '' : DateFormat('yyyy-MM-dd').format(_filterEndDate!)),
                        decoration: const InputDecoration(labelText: 'To Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(context: context, initialDate: _filterEndDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                          if (picked != null) { setState(() { _filterEndDate = picked; }); }
                        },
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () { setState(() { _filterStartDate = null; _filterEndDate = null; _filterStatus = null; }); },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredClaims.length,
                    itemBuilder: (context, index) {
                      final claim = filteredClaims[index];
                      Color statusColor = claim.status == 'Claimed' ? Colors.green : Colors.orange;
                      TextDecoration? textDecoration = claim.status == 'Claimed' ? TextDecoration.lineThrough : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          title: Text(claim.description, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: textDecoration)),
                          subtitle: Text(
                            'PKR ${claim.amount.toStringAsFixed(2)} for ${claim.companyName ?? 'N/A'} - ${DateFormat('yyyy-MM-dd').format(claim.dateIncurred)}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          trailing: claim.status == 'Pending'
                              ? ElevatedButton(
                            onPressed: () => _markClaimAsPaid(claim, companyClaimService),
                            child: const Text('Mark Claimed'),
                          )
                              : Chip(
                            label: Text(claim.status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                            backgroundColor: statusColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}