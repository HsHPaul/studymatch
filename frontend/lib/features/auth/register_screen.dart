import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../shared/widgets/study_match_logo.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studiengangController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _aliasController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studiengangController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
          alias: _aliasController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          studiengang: _studiengangController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── Logo ────────────────────────────────────────────────
                const Center(child: StudyMatchLogo(size: 48)),

                const SizedBox(height: 32),

                // ── Register Card ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Konto erstellen 🎓', style: tt.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Werde Teil der StudyMatch-Community.',
                        style: tt.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      // ── Form ──────────────────────────────────────────
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _aliasController,
                              decoration: const InputDecoration(
                                labelText: 'Anzeigename / Alias',
                                prefixIcon: Icon(Icons.badge_outlined),
                                helperText: 'Wie sollen andere dich nennen?',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().length < 2) {
                                  return 'Mindestens 2 Zeichen erforderlich';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-Mail',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              validator: (v) => v != null && v.contains('@')
                                  ? null
                                  : 'Gültige E-Mail eingeben',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Passwort',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                helperText: 'Mindestens 8 Zeichen',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.length < 8) {
                                  return 'Mindestens 8 Zeichen';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _studiengangController,
                              decoration: const InputDecoration(
                                labelText: 'Studiengang (optional)',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),

                      // ── Error ─────────────────────────────────────────
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          auth.error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Submit Button ─────────────────────────────────
                      FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Konto erstellen'),
                      ),

                      const SizedBox(height: 8),

                      // ── Login Link ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Bereits registriert?', style: tt.bodySmall),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(left: 4),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Anmelden'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
