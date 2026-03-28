import 'dart:convert';

import 'package:dromos/models/user_model.dart';
import 'package:dromos/utils/api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service that manages the current user's session and profile data.
///
/// Usage anywhere in the app:
/// final userService = UserService();
///
/// await userService.init();
///
/// final user = userService.currentUser;
///
/// final token = userService.token;
class UserService {
  // ---- singleton boilerplate ----
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // ---- state ----
  String _token = '';
  String _userId = '';
  UserModel _currentUser = UserModel();

  String get token => _token;
  String get userId => _userId;
  UserModel get currentUser => _currentUser;
  bool get isLoggedIn => _token.isNotEmpty;

  // ---- initialise from SharedPreferences (call once on app start) ----
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    _userId = prefs.getString('user_id') ?? '';

    // If we have a token, try to fetch the latest profile
    if (_token.isNotEmpty) {
      await fetchProfile();
    }
  }

  // ---- persist token + userId after login / register ----
  Future<void> saveSession({
    required String token,
    required String userId,
  }) async {
    _token = token;
    _userId = userId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', userId);
  }

  // ---- fetch profile via GET auth/me (Bearer token) ----
  Future<UserModel?> fetchProfile() async {
    if (_token.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse('${Api.url}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          // The user object may be nested under body['data']['user'] or body['data']
          final userData = body['data'];
          _currentUser = UserModel.fromJson(userData);
          _userId = _currentUser.userId;
          return _currentUser;
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('UserService.fetchProfile error: $e');
    }
    return null;
  }

  // ---- fetch public profile via GET users/:user_id/profile ----
  Future<UserModel?> fetchUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.url}/users/$userId/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final userData = body['data']['user'] ?? body['data'];

          return UserModel.fromJson(userData);
        }
      }
    } catch (e) {
      debugPrint('UserService.fetchUserProfile error: $e');
    }
    return null;
  }

  Future<void> setCurrentUser(UserModel user) async {
    _currentUser = user;
    _userId = user.userId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.userId);
    await prefs.setString('full_name', user.fullName);
  }

  // ---- update profile via PUT /auth/update ----
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? deptName,
    String? hallName,
    String? gender,
  }) async {
    if (_token.isEmpty) return false;

    try {
      final response = await http.put(
        Uri.parse('${Api.url}/auth/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'deptName': deptName,
          'hallName': hallName,
          'gender': gender,
        }),
      );

      debugPrint('updateProfile status: ${response.statusCode}');
      debugPrint('updateProfile body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          // Update currentUser with the new values locally
          _currentUser = UserModel(
            userId: _currentUser.userId,
            fullName: fullName ?? _currentUser.fullName,
            email: _currentUser.email,
            phoneNumber: phoneNumber ?? _currentUser.phoneNumber,
            registrationNumber: _currentUser.registrationNumber,
            deptName: deptName ?? _currentUser.deptName,
            hallName: hallName ?? _currentUser.hallName,
            gender: gender ?? _currentUser.gender,
            verificationStatus: _currentUser.verificationStatus,
          );
          // Also try to merge server response if available
          if (body['data'] != null) {
            final userData = body['data']['user'] ?? body['data'];
            _currentUser = UserModel.fromJson(userData);
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint('UserService.updateProfile error: $e');
    }
    return false;
  }

  // ---- clear session (logout) ----
  Future<void> logout() async {
    _token = '';
    _userId = '';
    _currentUser = UserModel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('full_name');
  }
}
