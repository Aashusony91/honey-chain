import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'mock_data.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String location,
    required UserRole role,
  });
  Future<void> logout();
  Future<void> saveSession(UserModel user);
  Future<void> clearSession();
}

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    return _currentUser;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }
    final user = email.contains('consumer')
        ? MockData.demoConsumer.copyWith(email: email)
        : MockData.demoUser.copyWith(email: email);
    _currentUser = user;
    return user;
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String location,
    required UserRole role,
  }) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    final user = UserModel(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      phone: phone,
      location: location,
      role: role,
      isVerified: role == UserRole.beekeeper,
      apiaryIds: role == UserRole.beekeeper ? ['apiary-001'] : const [],
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    _currentUser = null;
  }

  @override
  Future<void> saveSession(UserModel user) async {
    _currentUser = user;
  }

  @override
  Future<void> clearSession() async {
    _currentUser = null;
  }
}
