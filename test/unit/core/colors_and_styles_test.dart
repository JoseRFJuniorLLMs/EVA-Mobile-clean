import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eva_mobile/core/constants/colors.dart';
import 'package:eva_mobile/core/constants/text_styles.dart';
import 'package:eva_mobile/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('cores primarias definidas', () {
      expect(AppColors.primary, const Color(0xFF6200EE));
      expect(AppColors.secondary, const Color(0xFF03DAC6));
      expect(AppColors.background, const Color(0xFF121212));
      expect(AppColors.surface, const Color(0xFF1E1E1E));
      expect(AppColors.error, const Color(0xFFCF6679));
    });

    test('cores de feedback definidas', () {
      expect(AppColors.success, const Color(0xFF4CAF50));
      expect(AppColors.info, const Color(0xFF2196F3));
      expect(AppColors.warning, const Color(0xFFFFC107));
    });

    test('cores EVA definidas', () {
      expect(AppColors.evaBlue, const Color(0xFF2196F3));
      expect(AppColors.evaPurple, const Color(0xFF9C27B0));
      expect(AppColors.evaPink, const Color(0xFFE91E63));
    });

    test('cores de texto definidas', () {
      expect(AppColors.textPrimary, Colors.white);
      expect(AppColors.textSecondary, Colors.white70);
      expect(AppColors.onPrimary, Colors.white);
    });
  });

  group('AppTextStyles - Tamanhos minimos para idosos', () {
    test('tamanho minimo >= 16', () {
      expect(AppTextStyles.minElderlyFontSize, 16.0);
    });

    test('tamanho recomendado body = 20', () {
      expect(AppTextStyles.recommendedBodySize, 20.0);
    });

    test('tamanho recomendado titulo = 28', () {
      expect(AppTextStyles.recommendedTitleSize, 28.0);
    });

    test('tamanho recomendado botao = 20', () {
      expect(AppTextStyles.recommendedButtonSize, 20.0);
    });
  });

  group('AppTextStyles - Estilos para idosos', () {
    test('elderlyTitle >= 32px', () {
      expect(AppTextStyles.elderlyTitle.fontSize, greaterThanOrEqualTo(32));
      expect(AppTextStyles.elderlyTitle.fontWeight, FontWeight.bold);
    });

    test('elderlySubtitle >= 24px', () {
      expect(AppTextStyles.elderlySubtitle.fontSize, greaterThanOrEqualTo(24));
    });

    test('elderlyBody >= 20px', () {
      expect(AppTextStyles.elderlyBody.fontSize, greaterThanOrEqualTo(20));
    });

    test('elderlyCaption >= 16px (nunca menor para idosos)', () {
      expect(AppTextStyles.elderlyCaption.fontSize, greaterThanOrEqualTo(16));
    });

    test('elderlyButton >= 20px', () {
      expect(AppTextStyles.elderlyButton.fontSize, greaterThanOrEqualTo(20));
      expect(AppTextStyles.elderlyButton.fontWeight, FontWeight.bold);
    });

    test('elderlyNumber >= 28px', () {
      expect(AppTextStyles.elderlyNumber.fontSize, greaterThanOrEqualTo(28));
    });

    test('elderlyHint >= 20px', () {
      expect(AppTextStyles.elderlyHint.fontSize, greaterThanOrEqualTo(20));
    });
  });

  group('AppTextStyles - Estilos padrao', () {
    test('h1 = 24px bold', () {
      expect(AppTextStyles.h1.fontSize, 24);
      expect(AppTextStyles.h1.fontWeight, FontWeight.bold);
    });

    test('body = 16px normal', () {
      expect(AppTextStyles.body.fontSize, 16);
      expect(AppTextStyles.body.fontWeight, FontWeight.normal);
    });

    test('caption = 12px grey', () {
      expect(AppTextStyles.caption.fontSize, 12);
      expect(AppTextStyles.caption.color, Colors.grey);
    });
  });

  group('AppTextStyles - Cards', () {
    test('cardTitle = 20px bold', () {
      expect(AppTextStyles.cardTitle.fontSize, 20);
      expect(AppTextStyles.cardTitle.fontWeight, FontWeight.bold);
    });

    test('listItem = 18px', () {
      expect(AppTextStyles.listItem.fontSize, 18);
    });
  });

  group('AppTheme', () {
    test('constantes de tamanho definidas', () {
      expect(AppTheme.fontSizeSmall, 12.0);
      expect(AppTheme.fontSizeBody, 16.0);
      expect(AppTheme.fontSizeLarge, 20.0);
      expect(AppTheme.fontSizeTitle, 24.0);
      expect(AppTheme.fontSizeHeadline, 32.0);
    });

    test('touch target minimo = 48px', () {
      expect(AppTheme.recommendedTouchTargetSize, 48.0);
    });

    test('darkTheme usa Material3', () {
      expect(AppTheme.darkTheme.useMaterial3, true);
    });

    test('darkTheme tem brightness dark', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });

    test('darkTheme tem cores corretas', () {
      expect(AppTheme.darkTheme.colorScheme.primary, AppColors.primary);
      expect(AppTheme.darkTheme.colorScheme.secondary, AppColors.secondary);
    });

    test('darkTheme background color correto', () {
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppColors.background);
    });
  });
}
