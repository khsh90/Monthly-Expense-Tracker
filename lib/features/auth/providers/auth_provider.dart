import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart';
import 'package:appwrite/appwrite.dart';
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
    } on AppwriteException catch (e, st) {
      if (e.code == 401) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(e, st);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _appwriteService.login(email, password);
      await checkUser();
    } catch (e, st) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _appwriteService.signUp(
        email: email,
        password: password,
        name: name,
      );
      // Automatically login after signup
      await login(email, password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithGoogle() async {
    // Note: OAuth login redirects the user, so we don't set loading state here
    // as the app will likely pause/restart.
    try {
      await _appwriteService.loginWithOAuth2(provider: OAuthProvider.google);
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
