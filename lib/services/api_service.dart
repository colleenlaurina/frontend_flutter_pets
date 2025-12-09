import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static String? getToken() {
    return _token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> _getHeaders({bool requiresAuth = false}) {
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
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
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
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['token'] != null) {
          setToken(data['token']);
        } else if (data['data'] != null && data['data']['token'] != null) {
          setToken(data['data']['token']);
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
        headers: _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        clearToken();
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
        headers: _getHeaders(requiresAuth: true),
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

      final response = await http.get(Uri.parse(url), headers: _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load pet listings');
      }
    } catch (e) {
      throw Exception('Error fetching pet listings: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getMyPets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-pets'),
        headers: _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load your pets');
      }
    } catch (e) {
      throw Exception('Error fetching your pets: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getPetById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pets/$id'),
        headers: _getHeaders(),
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
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pets'));

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.headers['Accept'] = 'application/json';

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

      if (imagePath != null && imagePath.isNotEmpty) {
        var file = await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create pet listing');
      }
    } catch (e) {
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
        headers: _getHeaders(requiresAuth: true),
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
        headers: _getHeaders(requiresAuth: true),
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

  // ADOPTION REQUESTS
  static Future<Map<String, dynamic>> createAdoptionRequest({
    required int petId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/adoption-requests'),
        headers: _getHeaders(requiresAuth: true),
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

  static Future<List<dynamic>> getMyAdoptionRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-adoption-requests'),
        headers: _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return data['data'];
        }
        return data is List ? data : [];
      } else {
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getMyPetRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-pet-requests'),
        headers: _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        throw Exception('Failed to load pet requests');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> cancelAdoptionRequest(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/adoption-requests/$id'),
        headers: _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to cancel');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> approveAdoptionRequest(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pet-requests/$id/approve'),
        headers: _getHeaders(requiresAuth: true),
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
      final response = await http.post(
        Uri.parse('$baseUrl/pet-requests/$id/reject'),
        headers: _getHeaders(requiresAuth: true),
        body: jsonEncode(reason != null ? {'reason': reason} : {}),
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
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: _getHeaders(),
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
