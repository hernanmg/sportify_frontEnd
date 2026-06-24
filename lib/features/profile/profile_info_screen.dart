import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/user_profile_service.dart';
import 'package:sportify_amateur/models/user_profile.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  final UserProfileService _profileService = UserProfileService();
  final _formKey = GlobalKey<FormState>();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _ciudadController;
  late TextEditingController _provinciaController;
  late TextEditingController _paisController;
  late TextEditingController _bioController;
  late TextEditingController _experienciaController;
  late TextEditingController _fichaOrigenController;
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _ciudadController = TextEditingController();
    _provinciaController = TextEditingController();
    _paisController = TextEditingController();
    _bioController = TextEditingController();
    _experienciaController = TextEditingController();
    _fichaOrigenController = TextEditingController();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _isSaving = false;
      });
      final profile = await _profileService.getProfile();

      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });

      _populateControllers();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: ${UserProfileService.errorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateControllers() {
    if (_userProfile != null) {
      _firstNameController.text = _userProfile!.firstName ?? '';
      _lastNameController.text = _userProfile!.lastName ?? '';
      _phoneController.text = _userProfile!.phone ?? '';
      _ciudadController.text = _userProfile!.ciudad ?? '';
      _provinciaController.text = _userProfile!.provincia ?? '';
      _paisController.text = _userProfile!.pais ?? '';
      _bioController.text = _userProfile!.bio ?? '';
      _experienciaController.text = _userProfile!.experienciaDeportiva ?? '';
      _fichaOrigenController.text = _userProfile!.fichaOrigen ?? '';
      _fechaNacimiento = _userProfile!.fechaNacimiento;
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: now,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  String _birthDateLabel() {
    if (_fechaNacimiento == null) return 'Sin fecha cargada';
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${_fechaNacimiento!.day} de ${months[_fechaNacimiento!.month - 1]}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'provincia': _provinciaController.text.trim(),
        'pais': _paisController.text.trim(),
        'bio': _bioController.text.trim(),
        'experienciaDeportiva': _experienciaController.text.trim(),
        'fichaOrigen': _fichaOrigenController.text.trim().isEmpty
            ? null
            : _fichaOrigenController.text.trim(),
        if (_fechaNacimiento != null)
          'fechaNacimiento':
              '${_fechaNacimiento!.year.toString().padLeft(4, '0')}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}',
      };

      await _profileService.updateProfile(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadProfile();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar perfil: ${UserProfileService.errorMessage(e)}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Perfil'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Error al cargar perfil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            'Completá tus datos y tocá Guardar arriba a la derecha.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        // Información básica
                        _buildSection(
                          'Información Básica',
                          Icons.person,
                          Colors.blue,
                          [
                            _buildTextField(
                              'Nombre',
                              _firstNameController,
                              Icons.person_outline,
                            ),
                            _buildTextField(
                              'Apellido',
                              _lastNameController,
                              Icons.person_outline,
                            ),
                            _buildTextField(
                              'Teléfono',
                              _phoneController,
                              Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextField(
                              'De qué hincha soy',
                              _fichaOrigenController,
                              Icons.sports_soccer,
                              hintText: 'Ej: Boca Juniors, River, San Lorenzo…',
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.cake_outlined),
                              title: const Text('Fecha de nacimiento'),
                              subtitle: Text(
                                _birthDateLabel(),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              trailing: const Icon(Icons.edit_calendar),
                              onTap: _pickBirthDate,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Ubicación
                        _buildSection(
                          'Ubicación',
                          Icons.location_on,
                          Colors.orange,
                          [
                            _buildTextField(
                              'Ciudad',
                              _ciudadController,
                              Icons.location_city_outlined,
                            ),
                            _buildTextField(
                              'Provincia/Estado',
                              _provinciaController,
                              Icons.map_outlined,
                            ),
                            _buildTextField(
                              'País',
                              _paisController,
                              Icons.public_outlined,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Información adicional
                        _buildSection(
                          'Información Adicional',
                          Icons.info,
                          Colors.purple,
                          [
                            _buildTextField(
                              'Biografía',
                              _bioController,
                              Icons.text_snippet_outlined,
                              maxLines: 3,
                            ),
                            _buildTextField(
                              'Experiencia Deportiva',
                              _experienciaController,
                              Icons.sports_outlined,
                              maxLines: 3,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Información de solo lectura
                        _buildReadOnlyInfo(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
          isDense: false,
        ),
      ),
    );
  }

  Widget _buildReadOnlyInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Información del Sistema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Email', _userProfile!.email),
            _buildInfoRow('Username', _userProfile!.username),
            _buildInfoRow(
                'Perfil completo', '${_userProfile!.profileCompletion}%'),
            _buildInfoRow('Miembro desde',
                '${_userProfile!.createdAt.day}/${_userProfile!.createdAt.month}/${_userProfile!.createdAt.year}'),
            _buildInfoRow(
                'Estado', _userProfile!.isActive ? 'Activo' : 'Inactivo'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
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
    _bioController.dispose();
    _experienciaController.dispose();
    _fichaOrigenController.dispose();
    super.dispose();
  }
}
