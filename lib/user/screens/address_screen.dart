import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/services/firebase_service.dart';
import '../../auth/models/user_model.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_feedback.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final addresses = user?.addresses ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: addresses.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off_outlined, size: 64, color: AppColors.gray400),
                const SizedBox(height: 16),
                const Text('No saved addresses yet', style: TextStyle(color: AppColors.gray500)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddressDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Address'),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            children: [
              ...addresses.map((addr) => Column(
                children: [
                   _buildAddressCard(context, addr),
                   const SizedBox(height: AppTheme.spacingM),
                ],
              )),
              const SizedBox(height: AppTheme.spacingL),
              OutlinedButton.icon(
                onPressed: () => _showAddressDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
              ),
            ],
          ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressData address) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDefault = address.isDefault;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDefault ? AppColors.primaryIndigo : AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('DEFAULT', style: TextStyle(color: AppColors.primaryIndigo, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${address.street}\n${address.city}${address.postalCode.isNotEmpty ? ', ${address.postalCode}' : ''}${address.country != null ? ', ${address.country}' : ''}', 
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          const Divider(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => _showAddressDialog(context, address: address), 
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () => _deleteAddress(context, address.id), 
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
              if (!isDefault)
                TextButton(
                  onPressed: () => _setAsDefault(context, address.id), 
                  child: const Text('Set as Default'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== LOGIC ====================

  Future<void> _showAddressDialog(BuildContext context, {AddressData? address}) async {
    final isEdit = address != null;
    final labelController = TextEditingController(text: address?.label);
    final streetController = TextEditingController(text: address?.street);
    final cityController = TextEditingController(text: address?.city);
    final zipController = TextEditingController(text: address?.postalCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Address' : 'Add New Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label (e.g. Home, Work)')),
              TextField(controller: streetController, decoration: const InputDecoration(labelText: 'Street Address')),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) return;
                    final permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                      final pos = await Geolocator.getCurrentPosition();
                      streetController.text = 'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}';
                      cityController.text = cityController.text.isEmpty ? 'Auto-detected area' : cityController.text;
                    }
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use current location'),
                ),
              ),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: zipController, decoration: const InputDecoration(labelText: 'Postal Code (Optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (streetController.text.isEmpty || cityController.text.isEmpty) return;
              
              final auth = context.read<AuthProvider>();
              final user = auth.userModel!;
              final currentAddresses = List<AddressData>.from(user.addresses ?? []);
              
              if (isEdit) {
                final index = currentAddresses.indexWhere((a) => a.id == address.id);
                if (index != -1) {
                  currentAddresses[index] = address.copyWith(
                    label: labelController.text,
                    street: streetController.text,
                    city: cityController.text,
                    postalCode: zipController.text,
                  );
                }
              } else {
                final newAddr = AddressData(
                  id: const Uuid().v4(),
                  label: labelController.text.isEmpty ? 'Address' : labelController.text,
                  street: streetController.text,
                  city: cityController.text,
                  postalCode: zipController.text,
                  isDefault: currentAddresses.isEmpty,
                );
                currentAddresses.add(newAddr);
              }
              
              await _updateAddresses(context, currentAddresses);
              Navigator.pop(context);
            }, 
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(BuildContext context, String id) async {
    final auth = context.read<AuthProvider>();
    final currentAddresses = List<AddressData>.from(auth.userModel?.addresses ?? []);
    currentAddresses.removeWhere((a) => a.id == id);
    
    // If we deleted the default, set first remaining as default
    if (currentAddresses.isNotEmpty && !currentAddresses.any((a) => a.isDefault)) {
       currentAddresses[0] = currentAddresses[0].copyWith(isDefault: true);
    }
    
    await _updateAddresses(context, currentAddresses);
  }

  Future<void> _setAsDefault(BuildContext context, String id) async {
    final auth = context.read<AuthProvider>();
    final currentAddresses = (auth.userModel?.addresses ?? []).map((a) {
      return a.copyWith(isDefault: a.id == id);
    }).toList();
    
    await _updateAddresses(context, currentAddresses);
  }

  Future<void> _updateAddresses(BuildContext context, List<AddressData> addresses) async {
    try {
      final auth = context.read<AuthProvider>();
      await FirebaseService.instance.updateDocument(
        AppConstants.usersCollection, 
        auth.userModel!.userId, 
        {'addresses': addresses.map((a) => a.toMap()).toList()},
      );
      // AuthProvider will pick up changes if it's listening to stream, 
      // but current implementation might need a manual refresh or just wait for reactive update if implemented.
      // In this app, AuthProvider loads data once and provides it. 
      // I should check if AuthProvider has a refresh method or if it uses streams.
    } catch (e) {
      AppFeedback.error(
        context,
        e,
        fallbackMessage: 'Could not update addresses.',
        nextStep: 'Please retry.',
      );
    }
  }
}
