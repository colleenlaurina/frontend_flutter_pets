import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/api_service.dart';

class EditPetPage extends StatefulWidget {
  final Map<String, dynamic> pet;

  const EditPetPage({super.key, required this.pet});

  @override
  _EditPetPageState createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers - pre-filled with existing data
  late final TextEditingController _petNameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _colorController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _foodPreferencesController;

  String _selectedCategory = 'dog';
  String _selectedGender = 'male';
  String _selectedListingType = 'adopt';
  String _selectedStatus = 'available';

  File? _selectedImage;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing pet data
    _petNameController = TextEditingController(
      text: widget.pet['pet_name']?.toString() ?? '',
    );
    _breedController = TextEditingController(
      text: widget.pet['breed']?.toString() ?? '',
    );
    _ageController = TextEditingController(
      text: widget.pet['age']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: widget.pet['color']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.pet['description']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.pet['price']?.toString() ?? '0',
    );
    _allergiesController = TextEditingController(
      text: widget.pet['allergies']?.toString() ?? '',
    );
    _medicationsController = TextEditingController(
      text: widget.pet['medications']?.toString() ?? '',
    );
    _foodPreferencesController = TextEditingController(
      text: widget.pet['food_preferences']?.toString() ?? '',
    );

    // Set existing values
    _selectedCategory = widget.pet['category']?.toString() ?? 'dog';
    _selectedGender = widget.pet['gender']?.toString() ?? 'male';
    _selectedListingType = widget.pet['listing_type']?.toString() ?? 'adopt';
    _selectedStatus = widget.pet['status']?.toString() ?? 'available';
    _existingImageUrl = widget.pet['image_url']?.toString();
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _foodPreferencesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.updatePetListing(
        id: widget.pet['id'],
        petName: _petNameController.text.trim(),
        category: _selectedCategory,
        age: int.tryParse(_ageController.text.trim()),
        breed: _breedController.text.trim(),
        gender: _selectedGender,
        color: _colorController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        listingType: _selectedListingType,
        status: _selectedStatus,
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        medications: _medicationsController.text.trim().isEmpty
            ? null
            : _medicationsController.text.trim(),
        foodPreferences: _foodPreferencesController.text.trim().isEmpty
            ? null
            : _foodPreferencesController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back to My Pets page
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update pet: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Pet',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4FD1C7),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4FD1C7)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4FD1C7),
                              width: 2,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : _existingImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to change image',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pet Name
                    _buildTextField(
                      controller: _petNameController,
                      label: 'Pet Name',
                      icon: Icons.pets,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter pet name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category
                    _buildDropdown(
                      label: 'Category',
                      value: _selectedCategory,
                      items: const ['dog', 'cat'],
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value!),
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 16),

                    // Breed
                    _buildTextField(
                      controller: _breedController,
                      label: 'Breed',
                      icon: Icons.pets,
                    ),
                    const SizedBox(height: 16),

                    // Age & Gender Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'Age (years)',
                            icon: Icons.cake,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Gender',
                            value: _selectedGender,
                            items: const ['male', 'female'],
                            onChanged: (value) =>
                                setState(() => _selectedGender = value!),
                            icon: Icons.wc,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Color
                    _buildTextField(
                      controller: _colorController,
                      label: 'Color',
                      icon: Icons.palette,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Listing Type & Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Listing Type',
                            value: _selectedListingType,
                            items: const ['adopt', 'sell'],
                            onChanged: (value) =>
                                setState(() => _selectedListingType = value!),
                            icon: Icons.type_specimen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Status',
                            value: _selectedStatus,
                            items: const ['available', 'adopted'],
                            onChanged: (value) =>
                                setState(() => _selectedStatus = value!),
                            icon: Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price (\$)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter price';
                        if (double.tryParse(value) == null)
                          return 'Please enter valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Optional Fields
                    Text(
                      'Optional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _allergiesController,
                      label: 'Allergies',
                      icon: Icons.healing,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _medicationsController,
                      label: 'Medications',
                      icon: Icons.medical_services,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _foodPreferencesController,
                      label: 'Food Preferences',
                      icon: Icons.restaurant,
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _updatePet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FD1C7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Update Pet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF4FD1C7)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4FD1C7), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item.toUpperCase()),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF4FD1C7)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4FD1C7), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
