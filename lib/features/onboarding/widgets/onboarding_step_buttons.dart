import 'package:flutter/material.dart';

/// Botones inferiores del wizard (sin Row+Icon que desborda en pantallas angostas).
class OnboardingStepButtons extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback? onSkip;

  const OnboardingStepButtons({
    super.key,
    required this.onPrevious,
    required this.onPrimary,
    required this.primaryLabel,
    required this.primaryColor,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                child: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: const Text('Saltar este paso'),
          ),
        ],
      ],
    );
  }
}
