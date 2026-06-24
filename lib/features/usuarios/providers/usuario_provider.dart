import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/usuario.dart';
import '../data/usuario_repository.dart';

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return SqliteUsuarioRepository();
});

final usuariosControllerProvider = NotifierProvider<UsuariosController, UsuariosState>(
  UsuariosController.new,
);

class UsuariosState {
  const UsuariosState({
    this.usuarios = const [],
    this.isLoading = false,
  });

  final List<Usuario> usuarios;
  final bool isLoading;

  UsuariosState copyWith({
    List<Usuario>? usuarios,
    bool? isLoading,
  }) {
    return UsuariosState(
      usuarios: usuarios ?? this.usuarios,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UsuariosController extends Notifier<UsuariosState> {
  @override
  UsuariosState build() {
    loadUsuarios();
    return const UsuariosState(isLoading: true);
  }

  Future<void> loadUsuarios() async {
    final repo = ref.read(usuarioRepositoryProvider);
    final usuarios = await repo.fetchUsuarios();
    state = state.copyWith(usuarios: usuarios, isLoading: false);
  }

  Future<String> crearUsuario({
    required String nombre,
    required String email,
    required UserRole rol,
  }) async {
    final repo = ref.read(usuarioRepositoryProvider);
    final id = const Uuid().v4();
    final usuario = Usuario(
      id: id,
      email: email.trim().toLowerCase(),
      nombre: nombre.trim(),
      rol: rol,
      createdAt: DateTime.now(),
    );
    await repo.upsertUsuario(usuario);
    await loadUsuarios();
    return id;
  }

  Future<void> actualizarUsuario(Usuario usuario) async {
    final repo = ref.read(usuarioRepositoryProvider);
    await repo.upsertUsuario(usuario);
    await loadUsuarios();
  }

  Future<void> eliminarUsuario(String id) async {
    final repo = ref.read(usuarioRepositoryProvider);
    await repo.deleteUsuario(id);
    await loadUsuarios();
  }

  Future<bool> existeEmail(String email, {String? excludeId}) async {
    final repo = ref.read(usuarioRepositoryProvider);
    return repo.existsEmail(email.trim().toLowerCase(), excludeId: excludeId);
  }
}
