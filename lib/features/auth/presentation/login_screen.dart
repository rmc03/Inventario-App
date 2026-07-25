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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'admin@inventario.local',
  );
  final _passwordController = TextEditingController(text: 'demo123');
  UserRole _selectedRole = UserRole.admin;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

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
                constraints: BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadii.md),
                            ),
                            boxShadow: AppShadows.subtle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: context.colors.primary,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Gestión de\nInventario',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(fontSize: 27),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                    Text(
                      'Ingresar',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Acceso interno para jefe y dependientes.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: context.colors.muted),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(
                          value: UserRole.admin,
                          label: Text('Admin'),
                          icon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                        ButtonSegment(
                          value: UserRole.dependiente,
                          label: Text('Dependiente'),
                          icon: Icon(Icons.badge_outlined),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedRole = selection.first;
                          _emailController.text =
                              _selectedRole == UserRole.admin
                              ? 'admin@inventario.local'
                              : 'dependiente@inventario.local';
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        authState.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.danger,
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
