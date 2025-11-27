import 'package:appwrite/models.dart' as models;
import 'package:expense_tracker/core/services/appwrite_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<models.User?>>((ref) {
  return AuthNotifier(ref.read(appwriteServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<models.User?>> {
  final AppwriteService _appwriteService;

  AuthNotifier(this._appwriteService) : super(const AsyncValue.loading()) {
    checkUser();
  }

  Future<void> checkUser() async {
    try {
      final user = await _appwriteService.getUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _appwriteService.login(email, password);
      await checkUser();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _appwriteService.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
