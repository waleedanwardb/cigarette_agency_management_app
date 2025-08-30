// lib/UI/screens/company_claims/company_claims_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cigarette_agency_management_app/models/company_claim.dart';
import 'package:cigarette_agency_management_app/services/company_claim_service.dart';
import 'package:cigarette_agency_management_app/UI/screens/mt_management/add_mt_claim_screen.dart';
import 'package:cigarette_agency_management_app/UI/screens/vehicle/add_vehicle_expense_screen.dart';

class CompanyClaimsScreen extends StatefulWidget {
  const CompanyClaimsScreen({super.key});

  @override
  State<CompanyClaimsScreen> createState() => _CompanyClaimsScreenState();
}

class _CompanyClaimsScreenState extends State<CompanyClaimsScreen> {
  String? _filterStatus;
  String? _filterCategory;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isDeleting = false;

  // Method to group claims by type for a grouped list view
  Map<String, List<CompanyClaim>> _groupClaimsByType(List<CompanyClaim> claims) {
    Map<String, List<CompanyClaim>> groupedClaims = {};
    for (var claim in claims) {
      final type = claim.type;
      if (!groupedClaims.containsKey(type)) {
        groupedClaims[type] = [];
      }
      groupedClaims[type]!.add(claim);
    }
    return groupedClaims;
  }

  // Method to mark all filtered pending claims as paid
  Future<void> _markAllPendingAsClaimed(List<CompanyClaim> claims) async {
    final claimService = Provider.of<CompanyClaimService>(context, listen: false);
    final pendingClaims = claims.where((claim) => claim.status == 'Pending').toList();

    if (pendingClaims.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending claims to mark.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Mark All'),
          content: Text('Are you sure you want to mark all ${pendingClaims.length} pending claims as claimed?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        for (var claim in pendingClaims) {
          final updatedClaim = claim.copyWith(status: 'Claimed');
          await claimService.updateCompanyClaim(updatedClaim);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All pending claims marked as claimed.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update claims: $e')),
          );
        }
      }
    }
  }

  // Method to handle marking a claim as paid
  Future<void> _markClaimAsPaid(CompanyClaim claim, CompanyClaimService claimService) async {
    final updatedClaim = claim.copyWith(status: 'Claimed');
    try {
      await claimService.updateCompanyClaim(updatedClaim);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim for ${claim.companyName} marked as claimed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update claim: $e')),
        );
      }
    }
  }

  // Method to handle deleting a claim
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Claim deleted successfully!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // New method to delete all claims
  Future<void> _deleteAllClaims(List<CompanyClaim> claims) async {
    final claimService = Provider.of<CompanyClaimService>(context, listen: false);

    if (claims.isEmpty) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No claims to delete.')),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete All'),
          content: Text('Are you sure you want to delete all ${claims.length} claims? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        for (var claim in claims) {
          await claimService.deleteCompanyClaim(claim.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All claims deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete claims: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }


  // Method to show add claim options with a bottom sheet
  void _showAddClaimOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.monetization_on),
                title: const Text('Add MT Claim'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMTClaimScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.car_rental),
                title: const Text('Add Vehicle Expense'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVehicleExpenseScreen()));
                },
              ),
            ],
          ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Delete All Claims',
            onPressed: _isDeleting ? null : () async {
              final allClaims = await companyClaimService.getCompanyClaims().first;
              _deleteAllClaims(allClaims);
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Mark all pending as claimed',
            onPressed: () async {
              final allClaims = await companyClaimService.getCompanyClaims().first;
              final pendingClaims = allClaims.where((claim) => claim.status == 'Pending').toList();
              _markAllPendingAsClaimed(pendingClaims);
            },
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<CompanyClaim>>(
        stream: companyClaimService.getCompanyClaims(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allClaims = snapshot.data ?? [];
          final allClaimTypes = allClaims.map((claim) => claim.type).toSet().toList();

          final filteredClaims = allClaims.where((claim) {
            final date = claim.dateIncurred;
            bool matchesDate = (_filterStartDate == null || date.isAfter(_filterStartDate!)) &&
                (_filterEndDate == null || date.isBefore(_filterEndDate!.add(const Duration(days: 1))));
            bool matchesStatus = _filterStatus == null || claim.status == _filterStatus;
            bool matchesCategory = _filterCategory == null || claim.type == _filterCategory;
            return matchesDate && matchesStatus && matchesCategory;
          }).toList();

          double totalOutstandingClaims = filteredClaims
              .where((c) => c.status == 'Pending')
              .fold(0.0, (sum, c) => sum + c.amount);

          final groupedClaims = _groupClaimsByType(filteredClaims);

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
                // FIX: Changed Row to Column for responsive layout
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Filter by Status', border: OutlineInputBorder()),
                            value: _filterStatus,
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All Statuses')),
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'Claimed', child: Text('Claimed')),
                            ],
                            onChanged: (value) { setState(() { _filterStatus = value; }); },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Filter by Category', border: OutlineInputBorder()),
                            value: _filterCategory,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Categories')),
                              ...allClaimTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                            ],
                            onChanged: (value) { setState(() { _filterCategory = value; }); },
                          ),
                        ),
                      ],
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
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () { setState(() { _filterStartDate = null; _filterEndDate = null; _filterStatus = null; _filterCategory = null; }); },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: filteredClaims.isEmpty
                      ? const Center(child: Text('No claims available.'))
                      : ListView.builder(
                    itemCount: groupedClaims.keys.length,
                    itemBuilder: (context, index) {
                      final claimType = groupedClaims.keys.elementAt(index);
                      final claimsOfType = groupedClaims[claimType]!;
                      final totalAmount = claimsOfType.fold<double>(0.0, (sum, claim) => sum + claim.amount);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ExpansionTile(
                          title: Text(claimType, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Total: PKR ${totalAmount.toStringAsFixed(2)}'),
                          children: claimsOfType.map((claim) {
                            Color statusColor = claim.status == 'Claimed' ? Colors.green : Colors.orange;
                            TextDecoration? textDecoration = claim.status == 'Claimed' ? TextDecoration.lineThrough : null;

                            return ListTile(
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
                            );
                          }).toList(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClaimOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

}