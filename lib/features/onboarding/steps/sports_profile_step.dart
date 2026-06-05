import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/onboarding/widgets/onboarding_step_buttons.dart';

class SportsProfileStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  const SportsProfileStep({
    super.key,
    required this.initialData,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  @override
  State<SportsProfileStep> createState() => _SportsProfileStepState();
}

class _SportsProfileStepState extends State<SportsProfileStep> {
  late TextEditingController _bioController;
  late TextEditingController _experienciaController;

  @override
  void initState() {
    super.initState();
    _bioController =
        TextEditingController(text: widget.initialData['bio'] ?? '');
    _experienciaController = TextEditingController(
        text: widget.initialData['experienciaDeportiva'] ?? '');
  }

  void _handleNext() {
    final data = {
      'bio': _bioController.text.trim(),
      'experienciaDeportiva': _experienciaController.text.trim(),
    };
    widget.onNext(data);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu perfil deportivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cuéntanos sobre tu experiencia en el deporte',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Bio
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Biografía (opcional)',
                      hintText: 'Cuéntanos un poco sobre ti...',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Experiencia deportiva
                  TextFormField(
                    controller: _experienciaController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Experiencia deportiva (opcional)',
                      hintText:
                          'Equipos anteriores, logros, posiciones que juegas...',
                      prefixIcon:
                          const Icon(Icons.sports_soccer_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TODO: Agregar selección de categoría aquí
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.yellow.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pronto agregaremos selección de categorías y deportes',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          OnboardingStepButtons(
            onPrevious: widget.onPrevious,
            onPrimary: _handleNext,
            primaryLabel: 'Continuar',
            primaryColor: Colors.green,
            onSkip: widget.onSkip,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }
}
