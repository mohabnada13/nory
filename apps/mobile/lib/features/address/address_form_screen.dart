import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import '../../providers.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/background_gradient.dart';
import '../../ui/widgets/glass_card.dart';
import '../../ui/widgets/gradient_button.dart';

/// Screen for adding or editing a delivery address
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address});

  /// Optional address to edit (null for new address)
  final Address? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController(text: 'Cairo');
  final _areaController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _notesController = TextEditingController();

  // Form state
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Populate form if editing an existing address
    if (widget.address != null) {
      _fullNameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phone;
      _cityController.text = widget.address!.city;
      _areaController.text = widget.address!.area;
      _streetController.text = widget.address!.street;
      _buildingController.text = widget.address!.building;
      _apartmentController.text = widget.address!.apartment;
      _notesController.text = widget.address!.notes;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.address == null ? 'Add New Address' : 'Edit Address',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppPalette.textPrimary,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BackgroundGradient(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Address Details
                    _buildSectionTitle('Address Details'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter city name',
                            icon: Icons.location_city_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter city name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _areaController,
                            label: 'Area/District',
                            hint: 'Enter area or district',
                            icon: Icons.map_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter area or district';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _streetController,
                            label: 'Street',
                            hint: 'Enter street name/number',
                            icon: Icons.add_road_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter street name/number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _buildingController,
                            label: 'Building',
                            hint: 'Enter building name/number',
                            icon: Icons.home_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter building name/number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _apartmentController,
                            label: 'Apartment',
                            hint: 'Enter apartment/unit number',
                            icon: Icons.apartment_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter apartment/unit number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _notesController,
                            label: 'Delivery Notes (Optional)',
                            hint: 'Additional instructions for delivery',
                            icon: Icons.note_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Default Address Switch
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set as Default Address',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppPalette.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This address will be selected by default during checkout',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppPalette.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isDefault,
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value;
                              });
                            },
                            activeColor: AppPalette.primaryStart,
                            activeTrackColor: AppPalette.primaryEnd.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    GradientButton(
                      label: 'Save Address',
                      onPressed: _isLoading ? null : _saveAddress,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimary,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppPalette.primaryStart),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppPalette.primaryStart, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.textSecondary,
            ),
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.textSecondary.withValues(alpha: 0.7),
            ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final addressRepository = ref.read(addressRepositoryProvider);
        
        // Create address object with temporary id and current time
        // (repository will replace with server-generated values)
        final address = Address(
          id: widget.address?.id ?? 'temp',
          userId: widget.address?.userId ?? 'temp',
          fullName: _fullNameController.text,
          phone: _phoneController.text,
          city: _cityController.text,
          area: _areaController.text,
          street: _streetController.text,
          building: _buildingController.text,
          apartment: _apartmentController.text,
          notes: _notesController.text,
          isDefault: _isDefault,
          createdAt: widget.address?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.address == null) {
          // Add new address
          await addressRepository.add(address);
        } else {
          // Update existing address
          await addressRepository.update(address);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error saving address: ${e.toString()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
