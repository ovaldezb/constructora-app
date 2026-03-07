import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService with ChangeNotifier {
  final _userPool = CognitoUserPool(AppConfig.userPoolId, AppConfig.clientId);
  CognitoUser? _currentUser;
  CognitoUserSession? _session;
  String _userProfile = ''; // 'ADMIN' or 'SUPERVISOR'
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  String? get token => _session?.getIdToken().getJwtToken();
  String get userProfile => _userProfile;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    _userProfile = prefs.getString('userProfile') ?? '';
    
    if (email != null) {
      // START BYPASS CHECK
      if (email == 'admin@bypass.com') {
         _isLoading = false;
         notifyListeners();
         return; // Skip cognito check for bypass
      }
      // END BYPASS CHECK

      _currentUser = CognitoUser(email, _userPool);
      try {
        _session = await _currentUser!.getSession();
         // TODO: Fetch real profile from session attributes if possible or separate API
      } catch (e) {
        print('Error refreshing session: $e');
        _session = null;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  // BYPASS LOGIN METHOD
  Future<bool> loginBypass(String role) async {
    print('DEBUG: loginBypass called with role: $role');
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock Session
    _userProfile = role; // 'ADMIN' or 'SUPERVISOR'
    print('DEBUG: userProfile set to: $_userProfile');
    
    // Fake session token just to pass isAuthenticated check if we were strictly checking it
    // But since we use _session?.isValid(), we might need to mock that or change isAuthenticated logic.
    // For now, let's change isAuthenticated to allow bypass
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', 'admin@bypass.com');
    await prefs.setString('userProfile', role);

    _isLoading = false;
    notifyListeners();
    print('DEBUG: loginBypass finished. NotifyListeners called.');
    return true;
  }

  // Update isAuthenticated to support bypass
  // bool get isAuthenticated => (_session?.isValid() ?? false) || _userProfile.isNotEmpty; 
  // actually better to separate valid cognito session from dev bypass
  
  // Revised isAuthenticated
  // Revised isAuthenticated
  bool get isAuthenticated {
     print('DEBUG: checking isAuthenticated. Profile: $_userProfile, Session valid: ${_session?.isValid()}');
     if (_userProfile.isNotEmpty) return true; // Bypass mode active
     return _session?.isValid() ?? false;
  }

  Future<bool> login(String email, String password) async {
    print('DEBUG: login called with $email');
    // START BYPASS CHECK
    if (email.trim().toLowerCase() == 'admin@bypass.com') {
      return await loginBypass('ADMIN');
    }
    if (email.trim().toLowerCase() == 'supervisor@bypass.com') {
      return await loginBypass('SUPERVISOR');
    }
    // END BYPASS CHECK

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = CognitoUser(email, _userPool);
      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );
      _session = await _currentUser!.authenticateUser(authDetails);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on CognitoUserNewPasswordRequiredException catch (e) {
      print('DEBUG: CognitoUserNewPasswordRequiredException caught');
      _isLoading = false;
      notifyListeners();
      // Throw this specific exception so the UI can catch it
      throw e;
    } catch (e) {
      print('Login Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmNewPassword(String newPassword) async {
     _isLoading = true;
     notifyListeners();

     try {
       _session = await _currentUser!.sendNewPasswordRequiredAnswer(newPassword);
       
       if (_currentUser != null && _currentUser!.username != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', _currentUser!.username!);
       }

       _isLoading = false;
       notifyListeners();
       return true;
     } catch (e) {
       print('Error setting new password: $e');
       _isLoading = false;
       notifyListeners();
       return false;
     }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await _currentUser!.signOut();
    }
    _currentUser = null;
    _session = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('userProfile');
    _userProfile = '';
    
    notifyListeners();
  }
}
