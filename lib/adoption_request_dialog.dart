import 'dart:typed_data'; // ✅ ADD THIS
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// ✅ STEP 1: Info Dialog
class AdoptionInfoDialog extends StatelessWidget {
  final Map<String, dynamic> pet;

  const AdoptionInfoDialog({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FD1C7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4FD1C7),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Adoption Requirements',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'For ${pet['pet_name'] ?? 'this pet'}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildRequirement(
                Icons.message,
                'Adoption Message',
                'Minimum 20 characters (Required)',
              ),
              const SizedBox(height: 12),
              _buildRequirement(
                Icons.person,
                'Personal Information',
                'Full name and phone number (Required)',
              ),
              const SizedBox(height: 12),
              _buildRequirement(
                Icons.badge,
                'Valid IDs',
                '2 government-issued IDs (Required)',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All fields are required to process your adoption request',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AdoptionRequestDialog(pet: pet),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FD1C7),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4FD1C7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4FD1C7)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ✅ STEP 2: Main Adoption Dialog (All Required)
class AdoptionRequestDialog extends StatefulWidget {
  final Map<String, dynamic> pet;

  const AdoptionRequestDialog({super.key, required this.pet});

  @override
  State<AdoptionRequestDialog> createState() => _AdoptionRequestDialogState();
}

class _AdoptionRequestDialogState extends State<AdoptionRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // ✅ CHANGED - Use bytes instead of File
  Uint8List? _validId1Bytes;
  String? _validId1Name;
  Uint8List? _validId2Bytes;
  String? _validId2Name;

  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ✅ UPDATED - Works on both Web and Mobile
  Future<void> _pickImage(int idNumber) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        setState(() {
          if (idNumber == 1) {
            _validId1Bytes = bytes;
            _validId1Name = image.name;
          } else {
            _validId2Bytes = bytes;
            _validId2Name = image.name;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID #$idNumber uploaded successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ UPDATED - Works on both Web and Mobile
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Check bytes instead of File
    if (_validId1Bytes == null || _validId2Bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both Valid IDs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print('🔍 Token: $token');
      print('🔍 Pet ID: ${widget.pet['id']}');

      if (token == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://172.20.10.9:8000/api/adoption-requests',
        ), // ✅ UPDATED URL
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['pet_id'] = widget.pet['id'].toString();
      request.fields['message'] = _messageController.text.trim();
      request.fields['applicant_name'] = _nameController.text.trim();
      request.fields['phone_number'] = _phoneController.text.trim();

      // ✅ Use fromBytes - works on Web and Mobile
      request.files.add(
        http.MultipartFile.fromBytes(
          'valid_id_1',
          _validId1Bytes!,
          filename: _validId1Name ?? 'id1.jpg',
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'valid_id_2',
          _validId2Bytes!,
          filename: _validId2Name ?? 'id2.jpg',
        ),
      );

      print('📤 Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adoption request submitted successfully! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit request');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FD1C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Color(0xFF4FD1C7),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adoption Request',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.pet['pet_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Message (Required)
                const Text(
                  'Why do you want to adopt? *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Tell us why you would be a great pet parent...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4FD1C7),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Message is required';
                    }
                    if (value.trim().length < 20) {
                      return 'Message must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full Name (Required)
                const Text(
                  'Full Name *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4FD1C7),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Please enter a valid name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number (Required)
                const Text(
                  'Phone Number *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // Only allows numbers
                  ], // Limit to 11 digits
                  decoration: InputDecoration(
                    hintText: 'e.g., 09171234567',
                    prefixIcon: const Icon(Icons.phone),
                    counterText: '', // Hide the counter "0/11" text
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4FD1C7),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.trim().length != 11) {
                      return 'Phone number must be exactly 11 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'Phone number must contain only numbers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 16),

                // Valid ID #1 (Required)
                const Text(
                  'Valid ID #1 *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickImage(1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _validId1Bytes == null
                            ? Colors.red.shade300
                            : Colors.green,
                        width: _validId1Bytes == null ? 1 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _validId1Bytes != null
                          ? const Color(0xFFE8F5E9)
                          : Colors.red.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _validId1Bytes != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: _validId1Bytes != null
                              ? Colors.green
                              : Colors.red.shade300,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _validId1Bytes != null
                                ? 'ID Uploaded ✓'
                                : 'Tap to upload (Required)',
                            style: TextStyle(
                              color: _validId1Bytes != null
                                  ? Colors.green
                                  : Colors.red.shade700,
                              fontWeight: _validId1Bytes == null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_validId1Bytes != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() {
                              _validId1Bytes = null;
                              _validId1Name = null;
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Valid ID #2 (Required)
                const Text(
                  'Valid ID #2 *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickImage(2),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _validId2Bytes == null
                            ? Colors.red.shade300
                            : Colors.green,
                        width: _validId2Bytes == null ? 1 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _validId2Bytes != null
                          ? const Color(0xFFE8F5E9)
                          : Colors.red.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _validId2Bytes != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: _validId2Bytes != null
                              ? Colors.green
                              : Colors.red.shade300,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _validId2Bytes != null
                                ? 'ID Uploaded ✓'
                                : 'Tap to upload (Required)',
                            style: TextStyle(
                              color: _validId2Bytes != null
                                  ? Colors.green
                                  : Colors.red.shade700,
                              fontWeight: _validId2Bytes == null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_validId2Bytes != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() {
                              _validId2Bytes = null;
                              _validId2Name = null;
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FD1C7),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
