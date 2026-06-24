import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/usuario.dart';
import '../providers/usuario_provider.dart';

class UsuarioFormScreen extends ConsumerStatefulWidget {
  const UsuarioFormScreen({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends ConsumerState<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.userId != null;
    if (_isEdit) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final repo = ref.read(usuarioRepositoryProvider);
    final usuario = await repo.findUsuario(widget.userId!);
    if (usuario != null && mounted) {
      _nombreCtrl.text = usuario.nombre;
      _emailCtrl.text = usuario.email;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nombre = _nombreCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();

      final repo = ref.read(usuarioRepositoryProvider);
      final exists = await repo.existsEmail(
        email,
        excludeId: _isEdit ? widget.userId : null,
      );
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya existe un usuario con este email')),
          );
        }
        return;
      }

      if (_isEdit) {
        final usuario = await repo.findUsuario(widget.userId!);
        if (usuario != null) {
          await ref
              .read(usuariosControllerProvider.notifier)
              .actualizarUsuario(usuario.copyWith(
                nombre: nombre,
                email: email,
              ));
        }
      } else {
        await ref
            .read(usuariosControllerProvider.notifier)
            .crearUsuario(
              nombre: nombre,
              email: email,
              rol: UserRole.dependiente,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Usuario actualizado correctamente'
                  : 'Dependiente creado correctamente',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'El email es obligatorio';
    if (!email.contains('@')) return 'Email inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar usuario' : 'Crear dependiente'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isEdit)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.surface,
                      child: const Icon(Icons.person, size: 20),
                    ),
                    title: Text('Rol: ${UserRole.dependiente.label}'),
                    enabled: false,
                  ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validarEmail,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? 'Guardar cambios' : 'Crear dependiente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
