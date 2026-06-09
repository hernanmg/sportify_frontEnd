import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PersonalInfoStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onSkip;

  const PersonalInfoStep({
    super.key,
    required this.initialData,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _ciudadController;
  late TextEditingController _provinciaController;
  late TextEditingController _paisController;

  DateTime? _selectedDate;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _validateForm();
  }

  void _initializeControllers() {
    _firstNameController =
        TextEditingController(text: widget.initialData['firstName'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.initialData['lastName'] ?? '');
    _phoneController =
        TextEditingController(text: widget.initialData['phone'] ?? '');
    _ciudadController =
        TextEditingController(text: widget.initialData['ciudad'] ?? '');
    _provinciaController =
        TextEditingController(text: widget.initialData['provincia'] ?? '');
    _paisController =
        TextEditingController(text: widget.initialData['pais'] ?? 'Argentina');

    final fechaRaw = widget.initialData['fechaNacimiento'];
    if (fechaRaw is DateTime) {
      _selectedDate = fechaRaw;
    } else if (fechaRaw is String && fechaRaw.isNotEmpty) {
      try {
        // si lo guardás como yyyy-MM-dd
        _selectedDate = DateTime.parse(fechaRaw);
      } catch (_) {
        // si viene como dd/MM/yyyy
        final parts = fechaRaw.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            _selectedDate = DateTime(year, month, day);
          }
        }
      }
    }
    // Add listeners to validate form on change
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _ciudadController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _ciudadController.text.isNotEmpty &&
          _selectedDate != null;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      locale: Localizations.localeOf(context),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _validateForm();
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate() && _isFormValid) {
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'fechaNacimiento': _selectedDate != null
            ? '${_selectedDate!.year.toString().padLeft(4, '0')}-'
                '${_selectedDate!.month.toString().padLeft(2, '0')}-'
                '${_selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
        'ciudad': _ciudadController.text.trim(),
        'provincia': _provinciaController.text.trim(),
        'pais': _paisController.text.trim(),
      };
      widget.onNext(data);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
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
                          '¡Hola! Cuéntanos sobre ti',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Completa tu información personal para personalizar tu experiencia',
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
                    // Nombres
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _firstNameController,
                            label: 'Nombre *',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _lastNameController,
                            label: 'Apellido *',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'El apellido es requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Fecha de nacimiento
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha de Nacimiento *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDate != null
                                        ? '${_formatDate(_selectedDate!)} (${_calculateAge(_selectedDate!)} años)'
                                        : 'Selecciona tu fecha de nacimiento',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedDate != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Teléfono
                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'Teléfono *',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'El teléfono es requerido';
                        }
                        if (value!.length < 8) {
                          return 'Ingresa un teléfono válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Ubicación
                    _buildTextFormField(
                      controller: _ciudadController,
                      label: 'Ciudad *',
                      icon: Icons.location_city_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'La ciudad es requerida';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _provinciaController,
                            label: 'Provincia',
                            icon: Icons.map_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _paisController,
                            label: 'País',
                            icon: Icons.public_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _handleNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: widget.onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text(
                      'Completar más tarde',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _ciudadController.dispose();
    _provinciaController.dispose();
    _paisController.dispose();
    super.dispose();
  }
}
