import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../providers/language_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final nome = StorageService.getIdosoNome() ?? 'Usuario';
    final cpf = StorageService.getIdosoCpf() ?? '-';
    final telefone = StorageService.getIdosoTelefone() ?? '-';
    final id = StorageService.getIdosoId()?.toString() ?? 'N/A';

    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              lang.t('my_profile'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/home'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(lang.t('logout')),
                      content: Text(lang.t('logout_confirm')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(lang.t('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(lang.t('logout')),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await StorageService.clearAll();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9F70D8), Color(0xFFFFB6C1)],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  _buildHeader(nome, lang),
                  const SizedBox(height: 24),
                  _buildInfoSection(nome, cpf, telefone, id, lang),
                  const SizedBox(height: 24),
                  _buildActionButtons(lang),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String name, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE0B0FF),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
              ],
            ),
          ),
          Text(
            lang.t('eva_user'),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String nome, String cpf, String telefone, String id, LanguageProvider lang,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: Colors.white.withValues(alpha:0.9),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _buildInfoTile(Icons.person, lang.t('name'), nome),
            _buildInfoTile(Icons.badge, lang.t('doc_label'), _formatCpf(cpf)),
            _buildInfoTile(Icons.phone, lang.t('phone'), telefone),
            _buildInfoTile(Icons.key, lang.t('system_id'), id, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon, String title, String value, {bool isLast = false,}
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xFF9F70D8)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 70, color: Colors.grey.withValues(alpha:0.3)),
      ],
    );
  }

  Widget _buildActionButtons(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildPremiumButton(
            icon: Icons.settings,
            label: lang.t('settings'),
            colors: [const Color(0xFFE0B0FF), const Color(0xFF9F70D8)],
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.t('settings_dev'))),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildPremiumButton(
            icon: Icons.help_outline,
            label: lang.t('help_support'),
            colors: [const Color(0xFFFFB6C1), const Color(0xFFFF69B4)],
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.t('help_dev'))),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha:0.4),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCpf(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }
}
