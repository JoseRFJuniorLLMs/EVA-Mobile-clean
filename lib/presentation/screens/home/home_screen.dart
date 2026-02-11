import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../providers/call_provider.dart';
import '../../../providers/language_provider.dart';
import '../../widgets/pulsing_button.dart';
import '../../../data/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Minimizar automaticamente apos 3 segundos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _minimizeApp();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _minimizeApp() {
    try {
      const platform = MethodChannel('com.eva.br/minimize');
      platform.invokeMethod('minimizeApp');
    } catch (e) {
      _logger.w('Erro ao minimizar: $e');
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = StorageService.getIdosoNome() ?? 'Usuario';

    return Consumer2<CallProvider, LanguageProvider>(
      builder: (context, callProvider, lang, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _minimizeApp();
          },
          child: Scaffold(
            body: Stack(
              children: [
                // Background: oceano_azul.jpg como papel de parede
                Positioned.fill(
                  child: Semantics(
                    image: true,
                    label: lang.t('background_image'),
                    excludeSemantics: true,
                    child: Image.asset(
                      'assets/images/oceano_azul.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF9F70D8), Color(0xFFFFB6C1)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Overlay escuro para legibilidade
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha:0.3),
                  ),
                ),

                // Botao de perfil (canto superior direito)
                Positioned(
                  top: 50,
                  right: 20,
                  child: Semantics(
                    button: true,
                    label: lang.t('my_profile'),
                    child: Tooltip(
                      message: lang.t('my_profile'),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/profile'),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Conteudo principal
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Estado normal (aguardando chamada)
                        if (callProvider.status != CallStatus.ringing) ...[
                          // Logo (icone.png)
                          Semantics(
                            image: true,
                            label: 'EVA Logo',
                            excludeSemantics: true,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/icone.png',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'EVA Logo',
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.favorite, size: 80, color: Color(0xFF9F70D8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nome do usuario
                          Text(
                            '${lang.t('hello')}, $nome',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 6),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status - Aguardando chamada
                          Semantics(
                            liveRegion: true,
                            label: lang.t('waiting_call'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.25),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_in_talk, color: Colors.white, size: 20,
                                    semanticLabel: 'Telefone'),
                                  const SizedBox(width: 8),
                                  Text(
                                    lang.t('waiting_call'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Botao AGENDAR
                          Semantics(
                            button: true,
                            label: lang.t('schedule'),
                            child: SizedBox(
                              width: double.infinity,
                              height: 70,
                              child: ElevatedButton(
                                onPressed: () => context.push('/schedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF9F70D8),
                                  elevation: 5,
                                  shadowColor: Colors.black.withValues(alpha:0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_month, size: 32,
                                      semanticLabel: lang.t('schedule')),
                                    const SizedBox(width: 12),
                                    Text(
                                      lang.t('schedule'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Estado: chamada tocando
                        if (callProvider.status == CallStatus.ringing)
                          PulsingButton(
                            imagePath: 'assets/images/icone.png',
                            label: '',
                            size: 400,
                            onTap: () async {
                              try {
                                if (mounted) context.go('/call');
                                await Future.delayed(const Duration(milliseconds: 100));
                                callProvider.acceptCall();
                              } catch (e) {
                                _logger.e('Erro ao atender: $e');
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
