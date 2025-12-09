import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Using 127.0.0.1 for web browser or iOS simulator
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String _tokenKey = 'auth_token';

  // Store the authentication token
  static String? _token;

  // Set token after login (saves to SharedPreferences)
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('✅ Token saved: $_token');
  }

  // Get token (retrieves from SharedPreferences if not in memory)
  static Future<String?> getToken() async {
    // If token is in memory, return it
    if (_token != null) {
      return _token;
    }

    // Try to get from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    if (_token != null) {
      print('🔄 Token restored from storage: $_token');
    }

    return _token;
  }

  // Clear token on logout
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🗑️ Token cleared');
  }

  // Helper method to get headers
  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = false,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('🔑 Adding token to request');
      } else {
        print('⚠️ WARNING: Auth required but no token available!');
      }
    }

    return headers;
  }

  // ==================== AUTH ENDPOINTS ====================

  /// Register a new user
  /// POST /api/register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'user',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  /// Login user
  /// POST /api/login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save the token
        if (data['data'] != null && data['data']['token'] != null) {
          await setToken(data['data']['token']);
          print('✅ Login successful! Token saved.');
        }

        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  /// Logout user
  /// POST /api/logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        await clearToken();
        return jsonDecode(response.body);
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      throw Exception('Logout error: ${e.toString()}');
    }
  }

  /// Get current user
  /// GET /api/me
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user');
      }
    } catch (e) {
      throw Exception('Error getting user: ${e.toString()}');
    }
  }

  // ==================== PET LISTING ENDPOINTS ====================

  /// Get all pet listings (PUBLIC)
  /// GET /api/pets
  static Future<List<dynamic>> getPetListings({
    String? category,
    String? search,
  }) async {
    try {
      String url = '$baseUrl/pets';

      // Add query parameters if provided
      List<String> queryParams = [];
      if (category != null) queryParams.add('category=$category');
      if (search != null) queryParams.add('search=$search');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load pet listings');
      }
    } catch (e) {
      throw Exception('Error fetching pet listings: ${e.toString()}');
    }
  }

  /// Get single pet listing by ID (PUBLIC)
  /// GET /api/pets/{id}
  static Future<Map<String, dynamic>> getPetById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pets/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Pet not found');
      }
    } catch (e) {
      throw Exception('Error fetching pet: ${e.toString()}');
    }
  }

  /// Get user's own pets (PROTECTED)
  /// GET /api/my-pets
  static Future<List<dynamic>> getMyPets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-pets'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load my pets');
      }
    } catch (e) {
      throw Exception('Error loading my pets: ${e.toString()}');
    }
  }

  /// Create new pet listing (PROTECTED)
  /// POST /api/pets
  static Future<Map<String, dynamic>> createPetListing({
    required String petName,
    required String category,
    int? age,
    String? breed,
    String? gender,
    String? color,
    String? description,
    required double price,
    required String listingType,
    required String status,
    String? allergies,
    String? medications,
    String? foodPreferences,
    String? imagePath,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      print('🔑 Token for request: $token');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pets'));

      // Add headers with authentication
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      print('📤 Request headers: ${request.headers}');

      // Add fields
      request.fields['pet_name'] = petName;
      request.fields['category'] = category;
      if (age != null) request.fields['age'] = age.toString();
      if (breed != null) request.fields['breed'] = breed;
      if (gender != null) request.fields['gender'] = gender;
      if (color != null) request.fields['color'] = color;
      if (description != null) request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['listing_type'] = listingType;
      request.fields['status'] = status;
      if (allergies != null) request.fields['allergies'] = allergies;
      if (medications != null) request.fields['medications'] = medications;
      if (foodPreferences != null)
        request.fields['food_preferences'] = foodPreferences;

      // Add image if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          // For web, we need to use fromBytes instead of fromPath
          final bytes = await http.readBytes(Uri.parse(imagePath));
          var file = http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: 'pet_image.jpg',
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(file);
        } catch (e) {
          print('⚠️ Failed to add image: $e');
          // Continue without image if it fails
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create pet listing');
      }
    } catch (e) {
      print('❌ Error creating pet: $e');
      throw Exception('Error creating pet listing: ${e.toString()}');
    }
  }

  /// Update pet listing (PROTECTED)
  /// POST /api/pets/{id}
  static Future<Map<String, dynamic>> updatePetListing({
    required int id,
    required String petName,
    required String category,
    int? age,
    String? breed,
    String? gender,
    String? color,
    String? description,
    required double price,
    required String listingType,
    required String status,
    String? allergies,
    String? medications,
    String? foodPreferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pets/$id'),
        headers: await _getHeaders(requiresAuth: true),
        body: jsonEncode({
          'pet_name': petName,
          'category': category,
          'age': age,
          'breed': breed,
          'gender': gender,
          'color': color,
          'description': description,
          'price': price,
          'listing_type': listingType,
          'status': status,
          'allergies': allergies,
          'medications': medications,
          'food_preferences': foodPreferences,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update pet listing');
      }
    } catch (e) {
      throw Exception('Error updating pet listing: ${e.toString()}');
    }
  }

  /// Delete pet listing (PROTECTED)
  /// DELETE /api/pets/{id}
  static Future<Map<String, dynamic>> deletePetListing(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pets/$id'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete pet listing');
      }
    } catch (e) {
      throw Exception('Error deleting pet listing: ${e.toString()}');
    }
  }

  // ==================== ADOPTION REQUEST ENDPOINTS ====================

  /// Get user's adoption requests (PROTECTED)
  /// GET /api/my-adoption-requests
  static Future<List<dynamic>> getMyRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-adoption-requests'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      throw Exception('Error loading requests: ${e.toString()}');
    }
  }

  /// Get requests for user's pets (PROTECTED)
  /// GET /api/my-pet-requests
  static Future<List<dynamic>> getReceivedRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-pet-requests'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load received requests');
      }
    } catch (e) {
      throw Exception('Error loading received requests: ${e.toString()}');
    }
  }

  /// Submit adoption request (PROTECTED)
  /// POST /api/adoption-requests
  static Future<Map<String, dynamic>> submitAdoptionRequest({
    required int petId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/adoption-requests'),
        headers: await _getHeaders(requiresAuth: true),
        body: jsonEncode({'pet_id': petId, 'message': message}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit request');
      }
    } catch (e) {
      throw Exception('Error submitting request: ${e.toString()}');
    }
  }

  /// Approve adoption request (PROTECTED - Pet Owner)
  /// POST /api/pet-requests/{id}/approve
  static Future<Map<String, dynamic>> approveRequest(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pet-requests/$requestId/approve'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve request');
      }
    } catch (e) {
      throw Exception('Error approving request: ${e.toString()}');
    }
  }

  /// Reject adoption request (PROTECTED - Pet Owner)
  /// POST /api/pet-requests/{id}/reject
  static Future<Map<String, dynamic>> rejectRequest({
    required int requestId,
    required String ownerNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pet-requests/$requestId/reject'),
        headers: await _getHeaders(requiresAuth: true),
        body: jsonEncode({'owner_notes': ownerNotes}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject request');
      }
    } catch (e) {
      throw Exception('Error rejecting request: ${e.toString()}');
    }
  }

  /// Cancel adoption request (PROTECTED - Requester)
  /// DELETE /api/adoption-requests/{id}
  static Future<Map<String, dynamic>> cancelRequest(int requestId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/adoption-requests/$requestId'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to cancel request');
      }
    } catch (e) {
      throw Exception('Error canceling request: ${e.toString()}');
    }
  }

  // ==================== HISTORY ENDPOINTS ====================

  /// Get adoption history (PROTECTED)
  /// GET /api/my-adoption-history
  static Future<List<dynamic>> getAdoptionHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-adoption-history'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      throw Exception('Error loading history: ${e.toString()}');
    }
  }

  // ==================== TEST ENDPOINT ====================

  /// Test API connection
  /// GET /api/test
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API test failed');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }
}
