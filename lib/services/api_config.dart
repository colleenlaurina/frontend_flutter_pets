import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://172.20.10.9:8000/api';
  static const String _tokenKey = 'auth_token';

  static String? _token;

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('✅ Token saved: $_token');
  }

  static Future<String?> getToken() async {
    if (_token != null) {
      return _token;
    }

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    if (_token != null) {
      print('🔄 Token restored from storage: $_token');
    }

    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🗑️ Token cleared');
  }

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

  static Future<List<dynamic>> getPetListings({
    String? category,
    String? search,
  }) async {
    try {
      String url = '$baseUrl/pets';

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

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      print('📤 Request headers: ${request.headers}');

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
      if (foodPreferences != null) {
        request.fields['food_preferences'] = foodPreferences;
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        try {
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
