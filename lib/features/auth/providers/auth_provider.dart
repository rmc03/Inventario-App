import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/usuario.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});

  final Usuario? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Usuario? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> signIn({
    required String email,
    required String password,
    UserRole? preferredRole,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (password.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ingresa una contraseña para continuar.',
      );
      return;
    }

    final repository = ref.read(authRepositoryProvider);
    final user = repository.signIn(
      email: email,
      password: password,
      preferredRole: preferredRole,
    );

    state = AuthState(user: user);
  }

  void signOut() {
    state = const AuthState();
  }
}
