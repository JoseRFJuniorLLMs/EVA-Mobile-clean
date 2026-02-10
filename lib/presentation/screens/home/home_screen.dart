import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../providers/call_provider.dart';
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

    // Minimizar automaticamente apos 3 segundos (terminal burro)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _minimizeApp();
        }
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
      // Fallback: usar SystemNavigator
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = StorageService.getIdosoNome() ?? 'Usuario';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _minimizeApp();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF9F70D8),
                      Color(0xFFFFB6C1),
                    ],
                  ),
                ),
              ),
            ),

            // Botao de perfil (canto superior direito)
            Positioned(
              top: 50,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/profile'),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

            // Conteudo principal
            Consumer<CallProvider>(
              builder: (context, callProvider, child) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Estado normal (aguardando chamada)
                        if (callProvider.status != CallStatus.ringing) ...[
                          // Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(125),
                            child: Image.asset(
                              'assets/images/oceano_azul.jpg',
                              height: 250,
                              width: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Nome do usuario
                          Text(
                            'Ola, $nome',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_in_talk,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Aguardando ligacao da EVA...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Indicador de que o app vai minimizar
                          Text(
                            'O app ira minimizar automaticamente.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            'Voce recebera a chamada mesmo em segundo plano.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],

                        // Estado: chamada tocando
                        if (callProvider.status == CallStatus.ringing)
                          PulsingButton(
                            imagePath: 'assets/images/oceano_azul.jpg',
                            label: '',
                            size: 400,
                            onTap: () async {
                              try {
                                if (mounted) {
                                  context.go('/call');
                                }
                                await Future.delayed(
                                    const Duration(milliseconds: 100));
                                callProvider.acceptCall();
                              } catch (e) {
                                _logger.e('Erro ao atender: $e');
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
