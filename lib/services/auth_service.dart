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
  bool _isNewPasswordRequired = false;

  bool get isLoading => _isLoading;
  bool get isNewPasswordRequired => _isNewPasswordRequired;
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
      _currentUser = CognitoUser(email, _userPool);
      try {
        _session = await _currentUser!.getSession();
        if (_session != null && _session!.isValid()) {
           _userProfile = _session!.getIdToken().payload['custom:PROFILE'] ?? '';
           await prefs.setString('userProfile', _userProfile);
           await prefs.setString('token', _session!.getIdToken().getJwtToken()!);
        }
      } catch (e) {
        print('Error refreshing session: $e');
        _session = null;
      }
    }
    _isLoading = false;
    notifyListeners();
  }
  bool get isAuthenticated {
     return _session?.isValid() ?? false;
  }

  Future<bool> login(String email, String password) async {
    print('DEBUG: login called with $email');
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
      
      if (_session != null && _session!.isValid()) {
         _userProfile = _session!.getIdToken().payload['custom:PROFILE'] ?? '';
         await prefs.setString('userProfile', _userProfile);
         await prefs.setString('token', _session!.getIdToken().getJwtToken()!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on CognitoUserNewPasswordRequiredException catch (e) {
      print('DEBUG: CognitoUserNewPasswordRequiredException caught');
      _isNewPasswordRequired = true;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Login Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> confirmNewPassword(String newPassword) async {
     _isLoading = true;
     notifyListeners();

     try {
       _session = await _currentUser!.sendNewPasswordRequiredAnswer(newPassword);
       
       if (_currentUser != null && _currentUser!.username != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', _currentUser!.username!);
       }

       if (_session != null && _session!.isValid()) {
          _userProfile = _session!.getIdToken().payload['custom:PROFILE'] ?? '';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userProfile', _userProfile);
          await prefs.setString('token', _session!.getIdToken().getJwtToken()!);
       }

       _isNewPasswordRequired = false;
       _isLoading = false;
       notifyListeners();
       return null; // Null means success
     } catch (e) {
       print('Error setting new password: $e');
       _isLoading = false;
       notifyListeners();
       
       if (e is CognitoClientException) {
         return e.message ?? 'Error de seguridad con la contraseña.';
       }
       return 'Error: Ocurrió un problema al guardar la contraseña.';
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
    await prefs.remove('token');
    _userProfile = '';
    
    notifyListeners();
  }
}
