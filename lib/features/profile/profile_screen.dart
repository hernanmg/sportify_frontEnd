import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/user_profile_service.dart';
import 'package:sportify_amateur/models/user_profile.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/widgets/smooth_header_gradient.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthStorageService _authStorage = AuthStorageService();
  final UserProfileService _profileService = UserProfileService();

  UserProfile? _userProfile;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final profile = await _profileService.getProfile();
      final role = profile.role?.trim().isNotEmpty == true
          ? profile.role
          : await _authStorage.getRole();
      if (profile.role != null && profile.role!.isNotEmpty) {
        await _authStorage.saveRole(profile.role!);
      }

      setState(() {
        _userRole = role;
        _userProfile = profile;
        _isLoading = false;
      });
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

  bool _hasAdminAccess() {
    return _userRole == 'super_admin' || _userRole == 'manager';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil y Configuración'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Error al cargar perfil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header del perfil
                      _buildProfileHeader(),
                      const SizedBox(height: 24),

                      // Opciones del perfil
                      _buildProfileOptions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SmoothHeaderGradient.primary(
        Colors.blue.shade700,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _userProfile!.avatarUrl != null
                    ? NetworkImage(_userProfile!.avatarUrl!)
                    : null,
                child: _userProfile!.avatarUrl == null
                    ? Text(
                        _userProfile!.firstName
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            _userProfile!.username
                                .substring(0, 1)
                                .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _userProfile!.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userProfile!.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  RoleService.getRoleDisplayName(_userRole ?? 'guest'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Text(
                    'Perfil completo: ${_userProfile!.profileCompletion}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _userProfile!.profileCompletion / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOptions() {
    final options = [
      {
        'title': 'Información de tu perfil',
        'subtitle': 'Edita tus datos personales y configuración',
        'icon': Icons.person,
        'color': Colors.green,
        'route': '/profile/info',
        'showForAll': true,
      },
      {
        'title': 'Seguridad',
        'subtitle': 'Cambia tu contraseña y configura la seguridad',
        'icon': Icons.security,
        'color': Colors.orange,
        'route': '/profile/security',
        'showForAll': true,
      },
      if (_hasAdminAccess())
        {
          'title': 'Configuración General',
          'subtitle': 'Gestiona usuarios, roles y configuración del sistema',
          'icon': Icons.admin_panel_settings,
          'color': Colors.red,
          'route': '/profile/admin',
          'showForAll': false,
        },
    ];

    return Column(
      children: options.map((option) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pushNamed(context, option['route'] as String);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (option['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        option['icon'] as IconData,
                        color: option['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
