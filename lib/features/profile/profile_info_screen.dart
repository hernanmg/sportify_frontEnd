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
  bool _isEditing = false;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _ciudadController;
  late TextEditingController _provinciaController;
  late TextEditingController _paisController;
  late TextEditingController _bioController;
  late TextEditingController _experienciaController;

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
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
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
            content: Text('Error al cargar perfil: $e'),
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
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'provincia': _provinciaController.text.trim(),
        'pais': _paisController.text.trim(),
        'bio': _bioController.text.trim(),
        'experienciaDeportiva': _experienciaController.text.trim(),
      };

      await _profileService.updateProfile(updateData);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Recargar perfil
      _loadProfile();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: const Text(
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: _isEditing
              ? const Color.fromARGB(255, 82, 75, 75)
              : const Color.fromARGB(255, 24, 22, 22),
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
    super.dispose();
  }
}
