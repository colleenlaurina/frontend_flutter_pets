import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'my_pets_page.dart';
import 'dart:typed_data';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  _AddPetPageState createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _foodPreferencesController = TextEditingController();

  String _selectedCategory = 'dog';
  String _selectedGender = 'male';
  String _selectedListingType = 'adopt';
  String _selectedStatus = 'available';
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7F5),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF4FD1C7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Add New Pet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: _selectedImage == null
                                    ? const Color(0xFF4FD1C7).withOpacity(0.1)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF4FD1C7),
                                  width: 2,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: kIsWeb
                                          ? Image.network(
                                              _selectedImage!.path,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_selectedImage!.path),
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 50,
                                          color: Color(0xFF4FD1C7),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Add Photo',
                                          style: TextStyle(
                                            color: Color(0xFF4FD1C7),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        if (_selectedImage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Remove Photo',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),

                        _buildSectionTitle('Basic Information'),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _petNameController,
                          label: 'Pet Name',
                          icon: Icons.pets,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter pet name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'Category',
                          icon: Icons.category,
                          value: _selectedCategory,
                          items: const [
                            {'value': 'dog', 'label': 'Dog'},
                            {'value': 'cat', 'label': 'Cat'},
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _breedController,
                          label: 'Breed',
                          icon: Icons.workspaces_outlined,
                        ),
                        const SizedBox(height: 16),

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
                                icon: Icons.wc,
                                value: _selectedGender,
                                items: const [
                                  {'value': 'male', 'label': 'Male'},
                                  {'value': 'female', 'label': 'Female'},
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _colorController,
                          label: 'Color',
                          icon: Icons.palette,
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Listing Details'),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'Listing Type',
                          icon: Icons.sell,
                          value: _selectedListingType,
                          items: const [
                            {'value': 'adopt', 'label': 'For Adoption'},
                            {'value': 'sell', 'label': 'For Sale'},
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedListingType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _priceController,
                          label: 'Price (\$)',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          hint: 'Enter 0 for free adoption',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'Status',
                          icon: Icons.info_outline,
                          value: _selectedStatus,
                          items: const [
                            {'value': 'available', 'label': 'Available'},
                            {'value': 'adopted', 'label': 'Adopted'},
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Description & Details'),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: Icons.description,
                          maxLines: 4,
                          hint: 'Tell us about this pet...',
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _allergiesController,
                          label: 'Allergies (Optional)',
                          icon: Icons.health_and_safety,
                          hint: 'Any known allergies',
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _medicationsController,
                          label: 'Medications (Optional)',
                          icon: Icons.medical_services,
                          hint: 'Current medications',
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _foodPreferencesController,
                          label: 'Food Preferences (Optional)',
                          icon: Icons.restaurant,
                          hint: 'Favorite foods',
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FD1C7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Add Pet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
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
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF4FD1C7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            dropdownColor: Colors.white,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item['value'],
                child: Text(item['label']!),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF4FD1C7),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  } else {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: Color(0xFF4FD1C7),
                ),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    print(_selectedImage);

    if (_selectedImage == null) {
      print('No image selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pet image'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    print('Image path: ${_selectedImage!.path}');

    setState(() {
      _isLoading = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      final response = await ApiService.createPetListing(
        petName: _petNameController.text.trim(),
        category: _selectedCategory,
        age: _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
        breed: _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        gender: _selectedGender,
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        price: double.parse(_priceController.text),
        listingType: _selectedListingType,
        status: _selectedStatus,
        allergies: _allergiesController.text.trim().isNotEmpty
            ? _allergiesController.text.trim()
            : null,
        medications: _medicationsController.text.trim().isNotEmpty
            ? _medicationsController.text.trim()
            : null,
        foodPreferences: _foodPreferencesController.text.trim().isNotEmpty
            ? _foodPreferencesController.text.trim()
            : null,
        imageBytes: imageBytes,
        imageFileName: _selectedImage!.name,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet added successfully!'),
            backgroundColor: Color(0xFF4FD1C7),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPetsPage()),
        ).then((result) {
          if (result == true && mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add pet: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
