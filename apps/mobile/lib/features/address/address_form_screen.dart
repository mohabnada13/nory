import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:models/models.dart';
import '../../providers.dart';

/// Screen for adding or editing a delivery address
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address});

  /// Optional address to edit (null for new address)
  final Address? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  // App brand colors
  static const Color cream = Color(0xFFFFF8E7);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color gold = Color(0xFFD4AF37);

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
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          widget.address == null ? 'Add New Address' : 'Edit Address',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: brown,
          ),
        ),
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
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
                  const SizedBox(height: 24),

                  // Address Details
                  _buildSectionTitle('Address Details'),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),

                  // Default Address Switch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set as Default Address',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: brown,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This address will be selected by default during checkout',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
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
                          activeColor: brown,
                          activeTrackColor: gold.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: Text(
                        'Save Address',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(gold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: brown,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: brown),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade700,
          ),
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey,
          ),
        ),
        style: GoogleFonts.poppins(),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
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
                style: GoogleFonts.poppins(),
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
