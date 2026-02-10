import 'dart:math';
import 'package:flutter/material.dart';

enum AvatarState { idle, listening, speaking, ringing }

/// Avatar realista da EVA usando sprite frames com lip sync
class EvaAvatar extends StatefulWidget {
  final double size;
  final AvatarState state;

  const EvaAvatar({
    super.key,
    this.size = 280,
    this.state = AvatarState.idle,
  });

  @override
  State<EvaAvatar> createState() => _EvaAvatarState();
}

class _EvaAvatarState extends State<EvaAvatar> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  // Frame atual do lip sync (0-8)
  int _currentFrame = 0;
  bool _isTalking = false;

  // Mapeamento de frames:
  // 0 = boca fechada neutral
  // 1 = boca levemente aberta
  // 2 = boca aberta pequena
  // 3 = boca fechada 2
  // 4 = boca semi-aberta
  // 5 = boca media
  // 6 = boca aberta falando
  // 7 = boca bem aberta
  // 8 = sorriso

  // Sequencia de lip sync (simula fala natural)
  static const List<List<int>> _talkSequences = [
    [0, 1, 4, 6, 4, 1, 0],
    [0, 2, 5, 7, 5, 2, 0],
    [0, 1, 6, 4, 7, 5, 1, 0],
    [0, 4, 7, 6, 2, 5, 4, 0],
    [0, 1, 2, 6, 7, 6, 2, 1, 0],
  ];

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _updateState();
  }

  @override
  void didUpdateWidget(covariant EvaAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateState();
    }
  }

  void _updateState() {
    switch (widget.state) {
      case AvatarState.idle:
        _stopTalking();
        setState(() => _currentFrame = 8); // sorriso
        break;
      case AvatarState.listening:
        _stopTalking();
        setState(() => _currentFrame = 0); // neutral
        break;
      case AvatarState.speaking:
        _startTalking();
        break;
      case AvatarState.ringing:
        _stopTalking();
        setState(() => _currentFrame = 8); // sorriso
        break;
    }
  }

  void _startTalking() {
    if (_isTalking) return;
    _isTalking = true;
    _runTalkLoop();
  }

  void _stopTalking() {
    _isTalking = false;
  }

  void _runTalkLoop() async {
    final random = Random();
    while (_isTalking && mounted) {
      // Pegar sequencia aleatoria
      final seq = _talkSequences[random.nextInt(_talkSequences.length)];

      for (final frame in seq) {
        if (!_isTalking || !mounted) return;
        setState(() => _currentFrame = frame);
        // Velocidade variavel para parecer natural
        await Future.delayed(Duration(milliseconds: 60 + random.nextInt(80)));
      }

      // Pausa curta entre frases (as vezes)
      if (random.nextDouble() > 0.6) {
        setState(() => _currentFrame = 0);
        await Future.delayed(Duration(milliseconds: 150 + random.nextInt(300)));
      }
    }
  }

  @override
  void dispose() {
    _isTalking = false;
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == AvatarState.speaking ||
        widget.state == AvatarState.ringing;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar com glow
            Container(
              width: widget.size,
              height: widget.size * 1.5,
              decoration: isActive
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size * 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.state == AvatarState.ringing
                                  ? const Color(0xFFFF69B4)
                                  : const Color(0xFF9F70D8))
                              .withAlpha((_glowAnim.value * 100).toInt()),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.size * 0.15),
                child: Image.asset(
                  'assets/images/eva_frame_$_currentFrame.png',
                  width: widget.size,
                  height: widget.size * 1.5,
                  fit: BoxFit.cover,
                  gaplessPlayback: true, // Evita flicker entre frames
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Nome
            Text(
              'EVA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(60),
                    offset: const Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
