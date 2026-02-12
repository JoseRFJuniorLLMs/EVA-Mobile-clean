import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/data/services/native_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeAudioService - Constants', () {
    test('inputSampleRate = 16000 (Gemini input)', () {
      expect(NativeAudioService.inputSampleRate, 16000);
    });

    test('outputSampleRate = 24000 (Gemini output)', () {
      expect(NativeAudioService.outputSampleRate, 24000);
    });
  });

  group('NativeAudioService - Estado Inicial', () {
    test('nao inicializado por default', () {
      final audio = NativeAudioService();
      expect(audio.isInitialized, false);
    });

    test('volumeStream existe', () {
      final audio = NativeAudioService();
      expect(audio.volumeStream, isA<Stream<double>>());
    });
  });
}
