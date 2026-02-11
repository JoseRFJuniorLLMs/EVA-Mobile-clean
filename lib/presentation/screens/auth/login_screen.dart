import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../core/constants/text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  String _formatCpf(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digitsOnly[i]);
    }

    return buffer.toString();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginByCpf(_cpfController.text);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      context.go('/home');
    } else {
      final lang = context.read<LanguageProvider>();
      _showError(authProvider.errorMessage ?? lang.t('error_login'));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildFlagButton(String langCode, String label, Color c1, Color c2, Color c3, LanguageProvider langProvider) {
    final isSelected = langProvider.lang == langCode;
    return GestureDetector(
      onTap: () => langProvider.setLanguage(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF9F70D8), width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: Column(
                children: [
                  Expanded(child: Container(color: c1)),
                  Expanded(child: Container(color: c2)),
                  Expanded(child: Container(color: c3)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF9F70D8) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9F70D8), Color(0xFFFFB6C1)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 3 Bandeiras (EN, ES, RU)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFlagButton('en', 'EN',
                                const Color(0xFF00247D), Colors.white, const Color(0xFFCF142B), lang),
                            const SizedBox(width: 8),
                            _buildFlagButton('es', 'ES',
                                const Color(0xFFAA151B), const Color(0xFFF1BF00), const Color(0xFFAA151B), lang),
                            const SizedBox(width: 8),
                            _buildFlagButton('ru', 'RU',
                                Colors.white, const Color(0xFF0039A6), const Color(0xFFD52B1E), lang),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Logo (logox.png)
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logox.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.favorite, size: 60, color: Color(0xFF9F70D8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Titulo
                        Text(lang.t('welcome'), style: AppTextStyles.elderlyTitle),
                        const SizedBox(height: 12),
                        Text(
                          lang.t('login_subtitle'),
                          style: AppTextStyles.elderlyBody.copyWith(
                            color: Colors.white.withValues(alpha:0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Campo CPF/DNI/ID
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _cpfController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                return TextEditingValue(
                                  text: _formatCpf(newValue.text),
                                  selection: TextSelection.collapsed(
                                    offset: _formatCpf(newValue.text).length,
                                  ),
                                );
                              }),
                            ],
                            style: AppTextStyles.elderlyNumber,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: lang.t('doc_hint'),
                              hintStyle: AppTextStyles.elderlyNumber.copyWith(
                                color: Colors.grey[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.grey[600],
                                  size: 28,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                              if (digits.isEmpty) return lang.t('doc_empty');
                              if (digits.length != 11) return lang.t('doc_invalid');
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Botao Entrar
                        SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF9F70D8),
                              disabledBackgroundColor: Colors.white.withValues(alpha:0.7),
                              elevation: 5,
                              shadowColor: Colors.black.withValues(alpha:0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9F70D8)),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.login, size: 32),
                                      const SizedBox(width: 12),
                                      Text(lang.t('enter'), style: AppTextStyles.elderlyButtonLarge),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Ajuda
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(lang.t('help_title')),
                                content: Text(lang.t('help_body')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(lang.t('help_ok')),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.help_outline,
                            color: Colors.white.withValues(alpha:0.9),
                            size: 28,
                          ),
                          label: Text(
                            lang.t('help'),
                            style: AppTextStyles.elderlyLabel.copyWith(
                              color: Colors.white.withValues(alpha:0.9),
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
      },
    );
  }
}
