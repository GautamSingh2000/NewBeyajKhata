import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/SharedPreferenceKeys.dart';
import '../core/di/ServiceLocator.dart';
import '../data/models/User.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  static String _userDataKey(String mobile) => 'user_data_$mobile';

  final prefs = locator<SharedPreferences>();


  // Check if user exists by checking if we have stored their data
  Future<bool> checkUserExists(String mobile) async {
    try {
      debugPrint("Checking if user exists with mobile: $mobile");
      final userData = prefs.getString(_userDataKey(mobile));

      // Also check the legacy hardcoded check for backward compatibility
      final isHardcodedUser = mobile == '9876543210';

      final exists = userData != null || isHardcodedUser;
      debugPrint("User exists check result: $exists (userData: ${userData != null}, hardcoded: $isHardcodedUser)");
      return exists;
    } catch (e) {
      debugPrint("Error checking if user exists: $e");
      // Fallback to hardcoded check for safety
      return mobile == '9876543210';
    }
  }

  Future<void> loginWithMobile(String mobile) async {
    try {
      debugPrint("Logging in user with mobile: $mobile");
      // Try to load existing user data
      final userData = prefs.getString(_userDataKey(mobile));

      if (userData != null) {
        // We have stored data for this user
        debugPrint("Found stored user data");
        final userJson = json.decode(userData) as Map<String, dynamic>;
        _user = User.fromJson(userJson);
      } else {
        // Fallback for existing hardcoded user
        debugPrint("No stored data found, using fallback data");
        _user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Existing User',
          mobile: mobile,
        );

        // Save this user data so it's available next time
        await _saveUserDataByMobile(mobile, _user!);
      }

      // Update login status
      await prefs.setBool(SharedPreferenceKeys.IS_LOGGIN_KEY, true);
      await _saveUserData(); // Save to standard keys as well

      debugPrint("User logged in successfully: ${_user?.name} (${_user?.mobile})");
      notifyListeners();
    } catch (e) {
      debugPrint("Login error: $e");
      throw Exception('Failed to login: $e');
    }
  }

  // Register new user
  Future<void> registerUser({
    required String name,
    String? mobile = '',
  }) async {
    try {
      debugPrint("Registering new user: $name, $mobile");
      // Create new user
      _user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        mobile: mobile,
      );

      // Save user data to both traditional way and by mobile
      await _saveUserData();

      if (mobile != null && mobile.isNotEmpty) {
        await _saveUserDataByMobile(mobile, _user!);

        // Add to list of registered users
        await _addToRegisteredUsers(mobile);
      }

      debugPrint("User registered successfully: ${_user?.name} (${_user?.mobile})");
      notifyListeners();
    } catch (e) {
      debugPrint("Registration error: $e");
      throw Exception('Failed to register: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? mobile,
    String? profileImagePath,
  }) async {
    if (_user == null) return;

    try {
      final oldMobile = _user!.mobile;
      if (name != null) _user!.name = name;
      if (mobile != null) _user!.mobile = mobile;
      if (profileImagePath != null) _user!.profileImagePath = profileImagePath;

      // Save updated user data
      await _saveUserData();

      // Also update the user data by mobile
      if (_user!.mobile != null && _user!.mobile!.isNotEmpty) {
        await _saveUserDataByMobile(_user!.mobile!, _user!);
      }

      // If mobile changed, update the registered users list
      if (mobile != null && oldMobile != mobile && mobile.isNotEmpty) {
        await _addToRegisteredUsers(mobile);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Update profile error: $e");
      throw Exception('Failed to update profile: $e');
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final isLoggedIn = prefs.getBool(SharedPreferenceKeys.IS_LOGGIN_KEY) ?? false;

      if (isLoggedIn) {
        final id = prefs.getString(SharedPreferenceKeys.USER_ID_KEY);
        final name = prefs.getString(SharedPreferenceKeys.USER_NAME_KEY);
        final mobile = prefs.getString(SharedPreferenceKeys.USER_MOBILE_KEY);
        final profileImagePath = prefs.getString(SharedPreferenceKeys.USER_PROFILE_IMAGE_KEY);

        if (id != null && name != null) {
          _user = User(
            id: id,
            name: name,
            mobile: mobile,
            profileImagePath: profileImagePath,
          );

          debugPrint("Loaded user data from SharedPreferences: ${_user?.name} (${_user?.mobile})");
        }
      } else {
        debugPrint("No logged in user found");
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }
  // Helper to add mobile to registered users list
  Future<void> _addToRegisteredUsers(String mobile) async {
    try {
      final registeredUsers = prefs.getStringList(SharedPreferenceKeys.REGISTER_USER_KEY) ?? [];
      if (!registeredUsers.contains(mobile)) {
        registeredUsers.add(mobile);
        await prefs.setStringList(SharedPreferenceKeys.REGISTER_USER_KEY, registeredUsers);
        debugPrint("Added to registered users: $mobile");
      }
    } catch (e) {
      debugPrint("Error adding to registered users: $e");
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_user != null) {
        await prefs.setString(SharedPreferenceKeys.USER_ID_KEY, _user!.id);
        await prefs.setString(SharedPreferenceKeys.USER_NAME_KEY, _user!.name);
        if (_user!.mobile != null && _user!.mobile!.isNotEmpty) {
          await prefs.setString(SharedPreferenceKeys.USER_MOBILE_KEY, _user!.mobile!);
        }
        if (_user!.profileImagePath != null) {
          await prefs.setString(SharedPreferenceKeys.USER_PROFILE_IMAGE_KEY, _user!.profileImagePath!);
        }
        await prefs.setBool(SharedPreferenceKeys.IS_LOGGIN_KEY, true);

        debugPrint("Saved user data to shared preferences");
      }
    } catch (e) {
      debugPrint("Error saving user data: $e");
    }
  }

  // Helper to save user data by mobile number
  Future<void> _saveUserDataByMobile(String mobile, User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(_userDataKey(mobile), userJson);
      debugPrint("Saved user data by mobile: $mobile");
    } catch (e) {
      debugPrint("Error saving user data by mobile: $e");
    }
  }


  // Initialize provider and load persisted user data
  Future<void> initialize() async {
    try {
      await _loadUserData();
      debugPrint('UserProvider initialization complete: user = ${_user?.name} (${_user?.mobile})');
    } catch (e) {
      debugPrint('Error initializing UserProvider: $e');
      // Ensure we don't leave the user in a stuck state
      _user = null;
    } finally {
      // Always notify listeners even if there was an error
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logout() async {
      try {
        _user = null;
        // Clears all stored data (⚠️ wipes user data too)
        await prefs.clear();
        debugPrint("User logged out and all prefs cleared");
        notifyListeners();
      } catch (e) {
        debugPrint("Logout error: $e");
      }
    }
}