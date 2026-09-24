import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthService extends ChangeNotifier {
  AuthService({AuthRepository? repository})
      : _repository = repository ?? MockAuthRepository();

  final AuthRepository _repository;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        _currentUser = await _repository.getCurrentUser();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _repository.login(email: email, password: password);
      await _persistSession(user);
      _currentUser = user;
      notifyListeners();
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String location,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _repository.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        location: location,
        role: role,
      );
      await _persistSession(user);
      _currentUser = user;
      notifyListeners();
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession(UserModel user) async {
    await _repository.saveSession(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_role', user.role.name);
  }
}
