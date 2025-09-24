import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/onboarding/steps/personal_info_step.dart';
import 'package:sportify_amateur/features/onboarding/steps/sports_profile_step.dart';
import 'package:sportify_amateur/features/onboarding/steps/institutional_info_step.dart';
import 'package:sportify_amateur/features/onboarding/steps/preferences_step.dart';
import 'package:sportify_amateur/core/services/user_profile_service.dart';
import 'package:sportify_amateur/models/user_profile.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  int currentStep = 0;
  final PageController pageController = PageController();
  final UserProfileService profileService = UserProfileService();

  // Data storage for the wizard
  Map<String, dynamic> wizardData = {
    'personalInfo': <String, dynamic>{},
    'sportsProfile': <String, dynamic>{},
    'institutionalInfo': <String, dynamic>{},
    'preferences': <String, dynamic>{},
  };

  bool isLoading = false;
  UserProfile? currentProfile;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => isLoading = true);
    try {
      currentProfile = await profileService.getProfile();
      _prefillWizardData();
    } catch (e) {
      _showError('Error al cargar perfil: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _prefillWizardData() {
    if (currentProfile != null) {
      wizardData['personalInfo'] = <String, dynamic>{
        'firstName': currentProfile!.firstName ?? '',
        'lastName': currentProfile!.lastName ?? '',
        'phone': currentProfile!.phone ?? '',
        'fechaNacimiento': currentProfile!.fechaNacimiento,
        'ciudad': currentProfile!.ciudad ?? '',
        'provincia': currentProfile!.provincia ?? '',
        'pais': currentProfile!.pais ?? '',
      };
      wizardData['sportsProfile'] = <String, dynamic>{
        'bio': currentProfile!.bio ?? '',
        'experienciaDeportiva': currentProfile!.experienciaDeportiva ?? '',
      };
    }
  }

  List<StepData> get steps => [
        StepData(
          title: 'Datos Personales',
          subtitle: 'Información básica sobre ti',
          icon: Icons.person,
          color: Colors.blue,
        ),
        StepData(
          title: 'Perfil Deportivo',
          subtitle: 'Tu experiencia y categoría',
          icon: Icons.sports_soccer,
          color: Colors.green,
        ),
        StepData(
          title: 'Info Institucional',
          subtitle: 'Equipos y roles',
          icon: Icons.groups,
          color: Colors.orange,
        ),
        StepData(
          title: 'Preferencias',
          subtitle: 'Configuración final',
          icon: Icons.settings,
          color: Colors.purple,
        ),
      ];

  void nextStep() {
    if (currentStep < steps.length - 1) {
      setState(() => currentStep++);
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (pageController.page != null && pageController.page! > 0) {
      final prevPage = pageController.page!.toInt() - 1;

      pageController.animateToPage(
        prevPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        currentStep = prevPage;
      });
    }
  }

  Future<void> saveStepData(int stepIndex, Map<String, dynamic> data) async {
    String stepKey;
    switch (stepIndex) {
      case 0:
        stepKey = 'personalInfo';
        break;
      case 1:
        stepKey = 'sportsProfile';
        break;
      case 2:
        stepKey = 'institutionalInfo';
        break;
      case 3:
        stepKey = 'preferences';
        break;
      default:
        return;
    }

    setState(() {
      final currentData = Map<String, dynamic>.from(
          (wizardData[stepKey] as Map<String, dynamic>?) ??
              <String, dynamic>{});
      currentData.addAll(Map<String, dynamic>.from(data));
      wizardData[stepKey] = currentData;
    });

    // Save to backend immediately (solo campos válidos de User)
    try {
      final userFields = _filterUserFields(data);
      print('📝 Datos originales: $data');
      print('✅ Datos filtrados para User: $userFields');

      if (userFields.isNotEmpty) {
        await profileService.updateProfile(userFields);
        print('💾 Guardado exitoso en backend');
      } else {
        print('⏭️ Sin campos válidos para User, saltando guardado backend');
      }
    } catch (e) {
      print('❌ Error al guardar: $e');
      _showError('Error al guardar: $e');
    }
  }

  // Filtra solo los campos que pertenecen a la entidad User
  Map<String, dynamic> _filterUserFields(Map<String, dynamic> data) {
    const validUserFields = {
      // Campos básicos
      'firstName', 'lastName', 'phone', 'fechaNacimiento', 'avatarUrl',
      // Ubicación
      'ciudad', 'provincia', 'pais',
      // Biografía y experiencia
      'bio', 'experienciaDeportiva',
      // Estado
      'estadoRegistro', 'profileCompletion',
    };

    final filtered = <String, dynamic>{};
    for (final entry in data.entries) {
      if (validUserFields.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }

    return filtered;
  }

  Future<void> finishWizard() async {
    setState(() => isLoading = true);
    try {
      await profileService.completeOnboarding();

      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      _showError('Error al finalizar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void skipWizard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Saltar configuración?'),
        content: const Text(
            'Puedes completar tu perfil más tarde desde la configuración. '
            '¿Continuar al dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: skipWizard,
            child: const Text('Saltar'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: steps.asMap().entries.map((entry) {
                    int index = entry.key;
                    StepData step = entry.value;
                    bool isActive = index == currentStep;
                    bool isCompleted = index < currentStep;

                    return Expanded(
                      child: Row(
                        children: [
                          _buildStepIndicator(step, isActive, isCompleted),
                          if (index < steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color:
                                    isCompleted ? step.color : Colors.grey[300],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  steps[currentStep].title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  steps[currentStep].subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Step content
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: (index) {
                setState(() => currentStep = index);
              },
              children: [
                PersonalInfoStep(
                  initialData: Map<String, dynamic>.from(
                      wizardData['personalInfo'] ?? {}),
                  onNext: (data) {
                    saveStepData(0, data);
                    nextStep();
                  },
                  onSkip: () => nextStep(),
                ),
                SportsProfileStep(
                  initialData: Map<String, dynamic>.from(
                      wizardData['sportsProfile'] as Map),
                  onNext: (data) {
                    saveStepData(1, data);
                    nextStep();
                  },
                  onPrevious: () => previousStep(),
                  onSkip: () => nextStep(),
                ),
                InstitutionalInfoStep(
                  initialData: Map<String, dynamic>.from(
                      wizardData['institutionalInfo'] as Map),
                  onNext: (data) {
                    saveStepData(2, data);
                    nextStep();
                  },
                  onPrevious: () => previousStep(),
                  onSkip: () => nextStep(),
                ),
                PreferencesStep(
                  initialData: Map<String, dynamic>.from(
                      wizardData['preferences'] as Map),
                  onFinish: (data) {
                    saveStepData(3, data);
                    finishWizard();
                  },
                  onPrevious: () => previousStep(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(StepData step, bool isActive, bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? step.color
            : isActive
                ? step.color.withOpacity(0.2)
                : Colors.grey[200],
        border: Border.all(
          color: isActive || isCompleted ? step.color : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check : step.icon,
        color: isCompleted
            ? Colors.white
            : isActive
                ? step.color
                : Colors.grey[500],
        size: 20,
      ),
    );
  }
}

class StepData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  StepData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
