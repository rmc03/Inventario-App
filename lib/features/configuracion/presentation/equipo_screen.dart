import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/usuario.dart';
import '../../usuarios/providers/usuario_provider.dart';

class EquipoScreen extends ConsumerStatefulWidget {
  const EquipoScreen({super.key});

  @override
  ConsumerState<EquipoScreen> createState() => _EquipoScreenState();
}

class _EquipoScreenState extends ConsumerState<EquipoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuariosControllerProvider);
    final usuarios = state.usuarios;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipo'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            onPressed: () => _showUserDialog(context),
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Nuevo miembro',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: state.isLoading
                  ? const CircularProgressIndicator(key: ValueKey('loading'))
                  : usuarios.isEmpty
                      ? const _EmptyUsuarios(key: ValueKey('empty'))
                      : _buildUserList(usuarios, context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<Usuario> usuarios, BuildContext context) {
    return ListView(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Icon(
                Icons.people_rounded,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${usuarios.length} ${usuarios.length == 1 ? 'miembro' : 'miembros'}',
                  key: ValueKey('count-${usuarios.length}'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colors.muted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < usuarios.length; i++) ...[
          _AnimatedCard(
            index: i,
            controller: _entranceCtrl,
            child: _UserCard(
              key: ValueKey(usuarios[i].id),
              usuario: usuarios[i],
              index: i + 1,
              onEdit: () => _showUserDialog(
                context,
                usuario: usuarios[i],
              ),
              onDelete: () => _confirmDeleteUser(
                context,
                usuarios[i],
              ),
            ),
          ),
          if (i < usuarios.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Future<void> _showUserDialog(
    BuildContext context, {
    Usuario? usuario,
  }) async {
    final isEdit = usuario != null;
    final result = await showDialog<({String nombre, String email})>(
      context: context,
      builder: (_) => _UserDialog(
        title: isEdit ? 'Editar miembro' : 'Crear miembro',
        initialName: isEdit ? usuario.nombre : null,
        initialEmail: isEdit ? usuario.email : null,
      ),
    );

    if (result == null) return;

    final nombre = result.nombre.trim();
    final email = result.email.trim().toLowerCase();

    final repo = ref.read(usuarioRepositoryProvider);
    final exists = await repo.existsEmail(
      email,
      excludeId: isEdit ? usuario.id : null,
    );
    if (exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ya existe un usuario con este email'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
      return;
    }

    if (isEdit) {
      await ref
          .read(usuariosControllerProvider.notifier)
          .actualizarUsuario(usuario.copyWith(
            nombre: nombre,
            email: email,
          ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Miembro actualizado correctamente'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } else {
      await ref
          .read(usuariosControllerProvider.notifier)
          .crearUsuario(
            nombre: nombre,
            email: email,
            rol: UserRole.dependiente,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Miembro creado correctamente'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    Usuario usuario,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: context.colors.danger,
              size: 32,
            ),
          ),
          title: const Text('¿Eliminar miembro?'),
          content: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(
                  text: 'Se desactivará el acceso de ',
                ),
                TextSpan(
                  text: '"${usuario.nombre}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '. ¿Deseas continuar?'),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Haptics.warning(context);
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.danger,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await ref
          .read(usuariosControllerProvider.notifier)
          .eliminarUsuario(usuario.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Miembro eliminado'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }
}

// ─── Animated Card Wrapper ──────────────────────────────────────────────────

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({
    required this.index,
    required this.controller,
    required this.child,
  });

  final int index;
  final Animation<double> controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double stagger = index * 0.08;
    final double start = stagger;
    final double end = (stagger + 0.35).clamp(0.0, 1.0);

    final Animation<double> anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child!,
        ),
      ),
      child: child,
    );
  }
}

// ─── User Card ──────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({
    super.key,
    required this.usuario,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Usuario usuario;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAdmin = usuario.rol == UserRole.admin;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.line,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isAdmin
                        ? [
                            context.colors.primary.withValues(alpha: 0.2),
                            context.colors.primary.withValues(alpha: 0.1),
                          ]
                        : [
                            context.colors.warning.withValues(alpha: 0.2),
                            context.colors.warning.withValues(alpha: 0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isAdmin
                      ? Icon(
                          Icons.admin_panel_settings_rounded,
                          color: context.colors.primary,
                          size: 24,
                        )
                      : Text(
                          usuario.nombre.isNotEmpty
                              ? usuario.nombre[0].toUpperCase()
                              : '?',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: context.colors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            usuario.nombre,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ADMIN',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.muted,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isAdmin) ...[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
                  style: IconButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    backgroundColor:
                        context.colors.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'Eliminar',
                  style: IconButton.styleFrom(
                    foregroundColor: context.colors.danger,
                    backgroundColor: context.colors.danger.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────

class _EmptyUsuarios extends StatelessWidget {
  const _EmptyUsuarios({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No hay miembros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Agrega tu primer miembro desde el botón superior',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.muted,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User Dialog ────────────────────────────────────────────────────────────

class _UserDialog extends StatefulWidget {
  const _UserDialog({
    required this.title,
    this.initialName,
    this.initialEmail,
  });

  final String title;
  final String? initialName;
  final String? initialEmail;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emailCtrl;
  late final FocusNode _nombreFocus;
  late final FocusNode _emailFocus;

  String? _nombreError;
  String? _emailError;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialName ?? '');
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _nombreFocus = FocusNode();
    _emailFocus = FocusNode();

    _validateForm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nombreFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _nombreFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _validateForm() {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    setState(() {
      if (nombre.isEmpty) {
        _nombreError = null;
      } else if (nombre.length < 2) {
        _nombreError = 'Mínimo 2 caracteres';
      } else {
        _nombreError = null;
      }

      if (email.isEmpty) {
        _emailError = null;
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Email inválido';
      } else if (email.length < 5) {
        _emailError = 'Email muy corto';
      } else {
        _emailError = null;
      }

      _isValid = nombre.length >= 2 &&
          email.contains('@') &&
          email.contains('.') &&
          email.length >= 5 &&
          _nombreError == null &&
          _emailError == null;
    });
  }

  void _submit() {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (nombre.isEmpty) {
      setState(() => _nombreError = 'El nombre es obligatorio');
      _nombreFocus.requestFocus();
      return;
    }
    if (nombre.length < 2) {
      setState(() => _nombreError = 'Mínimo 2 caracteres');
      _nombreFocus.requestFocus();
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Introduce un email válido');
      _emailFocus.requestFocus();
      return;
    }

    Haptics.confirm(context);
    Navigator.of(context).pop((nombre: nombre, email: email));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    final nombreValid = _nombreCtrl.text.trim().length >= 2 && _nombreError == null;
    final emailValid = _emailCtrl.text.trim().contains('@') &&
        _emailCtrl.text.trim().contains('.') &&
        _emailError == null;

    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
          color: context.colors.primary,
          size: 28,
        ),
      ),
      title: Text(widget.title, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreCtrl,
              focusNode: _nombreFocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                hintText: 'Ej: Juan Pérez',
                prefixIcon: Icon(
                  Icons.person_outlined,
                  color: _nombreError != null
                      ? context.colors.danger
                      : (nombreValid ? context.colors.success : context.colors.muted),
                ),
                errorText: _nombreError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: nombreValid
                        ? context.colors.success.withValues(alpha: 0.5)
                        : context.colors.line,
                    width: nombreValid ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _nombreError != null
                        ? context.colors.danger
                        : context.colors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.colors.danger,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => _validateForm(),
              onSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'ejemplo@correo.com',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: _emailError != null
                      ? context.colors.danger
                      : (emailValid ? context.colors.success : context.colors.muted),
                ),
                errorText: _emailError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: emailValid
                        ? context.colors.success.withValues(alpha: 0.5)
                        : context.colors.line,
                    width: emailValid ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _emailError != null
                        ? context.colors.danger
                        : context.colors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.colors.danger,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => _validateForm(),
              onSubmitted: (_) {
                if (_isValid) _submit();
              },
            ),
            if (!isEdit && _nombreCtrl.text.isEmpty && _emailCtrl.text.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: context.colors.primary,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Crea credenciales para un nuevo miembro del equipo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(100, 44),
          ),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isValid ? _submit : null,
          icon: Icon(
            isEdit ? Icons.check_rounded : Icons.person_add_rounded,
            size: 20,
          ),
          label: Text(isEdit ? 'Actualizar' : 'Crear'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 44),
            disabledBackgroundColor: context.colors.muted.withValues(alpha: 0.3),
            disabledForegroundColor: context.colors.muted,
          ),
        ),
      ],
    );
  }
}
