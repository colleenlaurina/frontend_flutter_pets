import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class ApiService {
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String baseUrl = 'http://172.20.10.9:8000/api';

  static String? _token;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _initialized = true;

      if (_token != null) {
        print('✅ Token loaded from storage');
      } else {
        print('⚠️ No token found');
      }
    } catch (e) {
      print('❌ Error loading token: $e');
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _token = token;
      print('✅ Token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  static String? getToken() {
    return _token;
  }

  static Future<bool> isAuthenticated() async {
    await initialize();
    return _token != null && _token!.isNotEmpty;
  }

  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _token = null;
      print('✅ Token cleared');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }

  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = false,
  }) async {
    await initialize();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // AUTH
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'user',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return data;
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
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['token'] != null) {
          await saveToken(data['token']);
        } else if (data['data'] != null && data['data']['token'] != null) {
          await saveToken(data['data']['token']);
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
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
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
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          return data['user'];
        } else if (data['data'] != null) {
          return data['data'];
        }
        return data;
      } else {
        throw Exception('Failed to get current user');
      }
    } catch (e) {
      throw Exception('Error getting current user: ${e.toString()}');
    }
  }

  // PETS
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

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['data'] != null) {
          return data['data'];
        }

        return data is List ? data : [];
      } else {
        throw Exception('Failed to load pet listings');
      }
    } catch (e) {
      throw Exception('Error fetching pet listings: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getMyPets() async {
    try {
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.get(
        Uri.parse('$baseUrl/my-pets'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['data'] != null) {
          return data['data'];
        }

        return data is List ? data : [];
      } else {
        throw Exception('Failed to load your pets');
      }
    } catch (e) {
      throw Exception('Error fetching your pets: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getPetById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/pets/$id'),
        headers: headers,
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
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      await initialize();
      print('🚀 Starting pet creation...');
      print('🔑 Current token: ${_token != null ? "EXISTS" : "NULL"}');

      if (_token == null) {
        throw Exception('Not authenticated - please log in again');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pets'));

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_token';

      print('🔑 Token being sent: ${_token!.substring(0, 20)}...');

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

      print('📝 Fields added: ${request.fields}');

      if (imageBytes != null && imageBytes.isNotEmpty) {
        print('📸 Adding image from bytes (${imageBytes.length} bytes)');
        var file = http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName ?? 'pet_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
        print('📸 Image added successfully');
      }

      print('📤 Sending request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Pet created successfully!');
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - token may be expired');
        throw Exception('Unauthorized - please log in again');
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        print('❌ Validation error: $error');
        throw Exception(error['message'] ?? 'Validation failed');
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error: $error');
        throw Exception(error['message'] ?? 'Failed to create pet listing');
      }
    } catch (e) {
      print('❌ Exception: $e');
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
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.post(
        Uri.parse('$baseUrl/pets/$id'),
        headers: headers,
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
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.delete(
        Uri.parse('$baseUrl/pets/$id'),
        headers: headers,
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

  static Future<Map<String, dynamic>> createAdoptionRequest({
    required int petId,
    required String message,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.post(
        Uri.parse('$baseUrl/adoption-requests'),
        headers: headers,
        body: jsonEncode({'pet_id': petId, 'message': message}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create request');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ✅ REMOVED - Backend doesn't have this endpoint yet
  // Use getMyPetRequests instead (requests received as owner)
  static Future<List<dynamic>> getMyAdoptionRequests() async {
    try {
      final headers = await _getHeaders(requiresAuth: true);

      // ✅ Try the endpoint, if it fails return empty list
      final response = await http.get(
        Uri.parse('$baseUrl/my-adoption-requests'),
        headers: headers,
      );

      print('📥 My requests status: ${response.statusCode}');
      print('📥 My requests body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return data['data'];
        }
        return data is List ? data : [];
      } else {
        // ✅ If endpoint doesn't exist, return empty
        print('⚠️ Endpoint not available, returning empty list');
        return [];
      }
    } catch (e) {
      print('❌ Error loading requests: $e');
      // ✅ Return empty instead of throwing
      return [];
    }
  }

  static Future<List<dynamic>> getMyPetRequests() async {
    try {
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.get(
        Uri.parse('$baseUrl/my-pet-requests'),
        headers: headers,
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> rawRequests = [];

        if (data is Map && data['data'] != null) {
          rawRequests = data['data'];
        } else if (data is List) {
          rawRequests = data;
        } else {
          print('❌ Unexpected data format: ${data.runtimeType}');
          return [];
        }

        print('✅ Found ${rawRequests.length} raw requests');

        return rawRequests;
      } else {
        throw Exception('Failed to load pet requests: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getMyPetRequests: $e');
      rethrow;
    }
  }

  // ✅ SIMPLIFIED - No deletion for now since backend doesn't have it
  static Future<Map<String, dynamic>> cancelAdoptionRequest(int id) async {
    try {
      print('🚫 Canceling request ID: $id');

      final headers = await _getHeaders(requiresAuth: true);
      final response = await http
          .delete(Uri.parse('$baseUrl/adoption-requests/$id'), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      print('📥 Cancel Response: ${response.statusCode}');
      print('📥 Cancel Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to cancel request');
      }
    } catch (e) {
      print('❌ Cancel error: $e');
      throw Exception('Error canceling request: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> approveAdoptionRequest(int id) async {
    try {
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.post(
        Uri.parse('$baseUrl/pet-requests/$id/approve'),
        headers: headers,
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve request');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> rejectAdoptionRequest(
    int id, {
    String? reason,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.post(
        Uri.parse('$baseUrl/pet-requests/$id/reject'),
        headers: headers,
        body: jsonEncode({'owner_notes': reason ?? ''}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject request');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: headers,
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

  static Future<List<dynamic>> getMyAdoptionHistory() async {
    try {
      final headers = await _getHeaders(requiresAuth: true);
      final response = await http.get(
        Uri.parse('$baseUrl/my-adoption-history'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        throw Exception('Failed to load adoption history');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }
}
