import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/usuario.dart';
import '../providers/usuario_provider.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usuariosControllerProvider);
    final usuarios = state.usuarios;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            onPressed: () => context.push('/admin/usuarios/nuevo'),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Crear usuario',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : usuarios.isEmpty
              ? const _EmptyUsuarios()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _UsuarioTile(usuario: usuario),
                    );
                  },
                ),
    );
  }
}

class _UsuarioTile extends ConsumerWidget {
  const _UsuarioTile({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: usuario.rol == UserRole.admin
              ? AppColors.primary
              : AppColors.warning,
          foregroundColor: AppColors.surface,
          child: Text(
            usuario.nombre.isNotEmpty
                ? usuario.nombre[0].toUpperCase()
                : '?',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(usuario.nombre),
        subtitle: Text(usuario.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: usuario.rol == UserRole.admin
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                usuario.rol.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: usuario.rol == UserRole.admin
                      ? AppColors.primary
                      : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
        onTap: () =>
            context.push('/admin/usuarios/${usuario.id}/editar'),
      ),
    );
  }
}

class _EmptyUsuarios extends StatelessWidget {
  const _EmptyUsuarios();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            size: 48,
            color: AppColors.muted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hay usuarios',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Crea un dependiente desde la pantalla de Ajustes\no desde el botón + de esta pantalla.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
