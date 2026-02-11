import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:eva_mobile/providers/call_provider.dart';
import 'package:eva_mobile/providers/language_provider.dart';
import 'package:eva_mobile/presentation/widgets/pulsing_button.dart';
import 'package:logger/logger.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer2<CallProvider, LanguageProvider>(
        builder: (context, provider, lang, child) {
          return Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB6C1), Color(0xFFE0B0FF)],
                    ),
                  ),
                ),
              ),

              // Logo (quando nao conectado)
              if (provider.status != CallStatus.connected)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/images/oceano_azul.jpg',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // UI Layer
              SafeArea(child: _buildCallUI(provider, lang)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCallUI(CallProvider provider, LanguageProvider lang) {
    switch (provider.status) {
      case CallStatus.idle:
      case CallStatus.connecting:
        return _buildConnectingState(lang);

      case CallStatus.ringing:
        return _buildRingingState(provider);

      case CallStatus.connected:
        return _buildConnectedState(provider, lang);

      case CallStatus.error:
        return _buildErrorState(provider, lang);

      case CallStatus.ended:
      case CallStatus.ending:
        return _buildEndedState(lang);

    }
  }

  Widget _buildRingingState(CallProvider provider) {
    return Center(
      child: PulsingButton(
        imagePath: 'assets/images/oceano_azul.jpg',
        label: '',
        size: 280,
        onTap: () async {
          try {
            provider.acceptCall();
          } catch (e) {
            _logger.e('Erro ao atender: $e');
          }
        },
      ),
    );
  }

  Widget _buildConnectingState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 30),
          Text(
            lang.t('connecting'),
            style: TextStyle(
              fontSize: 24,
              color: Colors.pink.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedState(CallProvider provider, LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Logo durante chamada
          ClipRRect(
            borderRadius: BorderRadius.circular(75),
            child: Image.asset(
              'assets/images/oceano_azul.jpg',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),

          // Duracao
          Text(
            _formatDuration(provider.callDuration),
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 3),
              ],
            ),
          ),

          const Spacer(),

          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute
              _build3DButton(
                icon: provider.isMuted ? Icons.mic_off : Icons.mic,
                label: provider.isMuted ? lang.t('muted') : lang.t('microphone'),
                colors: [const Color(0xFFE0B0FF), const Color(0xFF9F70D8)],
                onTap: () => provider.toggleMute(),
              ),

              // Desligar
              _build3DButton(
                icon: Icons.call_end,
                label: lang.t('hangup'),
                isCritical: true,
                colors: [const Color(0xFFFF6B6B), const Color(0xFFC92A2A)],
                onTap: () => provider.endCall(),
              ),

              // Speaker
              _build3DButton(
                icon: provider.isSpeakerOn ? Icons.volume_up : Icons.hearing,
                label: provider.isSpeakerOn ? lang.t('speaker') : lang.t('earpiece'),
                colors: [const Color(0xFFFFB6C1), const Color(0xFFFF69B4)],
                onTap: () => provider.toggleSpeaker(),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorState(CallProvider provider, LanguageProvider lang) {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) context.go('/home');
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 20),
          Text(
            lang.t('call_error'),
            style: TextStyle(
              fontSize: 24,
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              provider.errorMessage ?? lang.t('restarting'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedState(LanguageProvider lang) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/home');
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call_end, size: 80, color: Colors.pink.shade300),
          const SizedBox(height: 20),
          Text(
            lang.t('call_ended'),
            style: TextStyle(
              fontSize: 24,
              color: Colors.pink.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
    bool isCritical = false,
  }) {
    final size = isCritical ? 100.0 : 80.0;
    final iconSize = isCritical ? 50.0 : 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha:0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha:0.4),
                    blurRadius: 10,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.pink.shade900,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
