import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'admin@inventario.local',
  );
  final _passwordController = TextEditingController(text: 'demo123');
  UserRole _selectedRole = UserRole.admin;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(UserRole role) {
    if (role == _selectedRole) return;
    Haptics.tap(context);
    setState(() {
      _selectedRole = role;
      _emailController.text =
          role == UserRole.admin
              ? 'admin@inventario.local'
              : 'dependiente@inventario.local';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final colors = context.colors;

    return LoadingOverlay(
      isLoading: authState.isLoading,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Demo mode indicator
                    _DemoBadge(),
                    const SizedBox(height: AppSpacing.xxl),

                    // App identity
                    Row(
                      children: [
                        _AppIcon(colors: colors),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Gestión de\nInventario',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 27),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

                    // Welcome message
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRole == UserRole.admin
                                  ? 'Bienvenido, Jefe'
                                  : 'Hola, equipo',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _selectedRole == UserRole.admin
                                  ? 'Acceso al panel de control.'
                                  : 'Acceso para gestionar tu turno.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Role selection tiles
                    _RoleTiles(
                      selected: _selectedRole,
                      onSelect: _switchRole,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El email es requerido';
                              }
                              if (!value.contains('@')) {
                                return 'Ingresa un email válido';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'correo@tienda.local',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es requerida';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              hintText: 'Ingresa tu contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        authState.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: () {
                        Haptics.tap(context);
                        _signIn();
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Ingresar'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
          preferredRole: _selectedRole,
        );
  }
}

class _DemoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: context.colors.info.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science_outlined,
            size: 14,
            color: context.colors.info,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Modo demo',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.colors});
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadii.md),
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(
          Icons.inventory_2_outlined,
          color: colors.primary,
          size: 30,
        ),
      ),
    );
  }
}

class _RoleTiles extends StatelessWidget {
  const _RoleTiles({
    required this.selected,
    required this.onSelect,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleTile(
            role: UserRole.admin,
            isSelected: selected == UserRole.admin,
            onTap: () => onSelect(UserRole.admin),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _RoleTile(
            role: UserRole.dependiente,
            isSelected: selected == UserRole.dependiente,
            onTap: () => onSelect(UserRole.dependiente),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.4)
                : colors.line,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: isDark ? 0.2 : 0.12)
                    : colors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                role == UserRole.admin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.badge_outlined,
                color: isSelected ? colors.primary : colors.muted,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              role == UserRole.admin ? 'Admin' : 'Dependiente',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? colors.primary : colors.muted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              role == UserRole.admin ? 'Control total' : 'Ventas y turno',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.7)
                    : colors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}