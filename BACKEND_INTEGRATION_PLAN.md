# 🔗 Plan de Integración Backend-Frontend

## 🎯 **Objetivo**
Conectar completamente el frontend Flutter con el backend NestJS actualizado, incluyendo nuevos campos y funcionalidades.

---

## 📊 **Estado Actual vs Requerido**

### **✅ Funcionalidades Existentes:**
- Login con email/password
- Autenticación con Google/Facebook
- Gestión básica de usuarios y roles
- Dashboard y estadísticas
- Gestión de partidos y eventos

### **🔄 Actualizaciones Necesarias:**

#### **1. Modelos de Datos**
**Actualizar:** `lib/models/user.dart`
```dart
class User {
  final int id;
  final String username;
  final String email;
  
  // 🆕 Nuevos campos del backend
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime? fechaNacimiento;
  final String? avatarUrl;
  final String estadoRegistro; // pending, verified, active, suspended
  final bool emailVerified;
  final bool phoneVerified;
  final bool isActive;
  final DateTime? ultimoLogin;
  
  final List<Role> roles;
  // 🆕 Nueva relación
  final List<UserAuthProvider>? authProviders;
  
  // Constructor y métodos fromJson/toJson actualizados...
}
```

#### **2. Nuevo Modelo: UserAuthProvider**
**Crear:** `lib/models/user_auth_provider.dart`
```dart
class UserAuthProvider {
  final int id;
  final int userId;
  final String provider; // 'email', 'google', 'facebook', 'apple'
  final String? providerId;
  final String? providerEmail;
  final bool isVerified;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Constructor y métodos fromJson/toJson...
}
```

#### **3. Modelo Player Actualizado**
**Actualizar:** `lib/models/player.dart` (crear si no existe)
```dart
class Player {
  final int id;
  final int userId;
  final int teamId;
  
  // 🆕 Información deportiva
  final String? posicion;
  final int? jerseyNumber;
  final double? height;
  final double? weight;
  final String? dominantFoot;
  
  // 🆕 Fechas importantes
  final DateTime joinedTeamDate;
  final DateTime? contractEndDate;
  
  // 🆕 Estado del jugador
  final bool isActive;
  final bool isCaptain;
  final String injuryStatus; // healthy, injured, recovering
  
  // Relaciones
  final User? user;
  final Team? team;
}
```

---

## 🔧 **Servicios a Actualizar**

### **1. AuthService Mejorado**
**Archivo:** `lib/core/services/auth_services.dart`

```dart
class AuthService {
  // 🆕 Registro con múltiples providers
  Future<bool> registerWithProvider({
    required String provider,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'provider': provider,
        'userData': data,
      });
      
      if (response.statusCode == 201) {
        await _storeAuthData(response.data);
        return true;
      }
      return false;
    } catch (e) {
      print('Error en registro: $e');
      return false;
    }
  }
  
  // 🆕 Verificar email
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await _dio.post('/auth/verify-email', data: {
        'token': token,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // 🆕 Actualizar último login
  Future<void> updateLastLogin() async {
    try {
      await _dio.patch('/auth/update-login');
    } catch (e) {
      print('Error actualizando último login: $e');
    }
  }
}
```

### **2. UserService Completo**
**Archivo:** `lib/core/services/user_service.dart`

```dart
class UserService {
  final Dio _dio = DioClient.instance;
  
  // 🆕 Obtener perfil completo
  Future<User?> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Error obteniendo perfil: $e');
    }
  }
  
  // 🆕 Actualizar perfil
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/users/profile', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print('Error actualizando perfil: $e');
      return false;
    }
  }
  
  // 🆕 Subir avatar
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imageFile.path),
      });
      
      final response = await _dio.post('/users/upload-avatar', 
        data: formData);
      
      if (response.statusCode == 200) {
        return response.data['avatarUrl'];
      }
      return null;
    } catch (e) {
      print('Error subiendo avatar: $e');
      return null;
    }
  }
}
```

### **3. PlayerService Nuevo**
**Crear:** `lib/core/services/player_service.dart`

```dart
class PlayerService {
  final Dio _dio = DioClient.instance;
  
  Future<List<Player>> getPlayers({int? teamId}) async {
    try {
      final response = await _dio.get('/players', 
        queryParameters: teamId != null ? {'teamId': teamId} : null);
      
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Player.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error obteniendo jugadores: $e');
    }
  }
  
  Future<bool> updatePlayerInfo(int playerId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/players/$playerId', data: data);
      return response.statusCode == 200;
    } catch (e) {
      print('Error actualizando jugador: $e');
      return false;
    }
  }
}
```

---

## 📱 **Pantallas a Actualizar**

### **1. Formulario de Registro Completo**
**Crear:** `lib/features/auth/registration_form.dart`

```dart
class RegistrationForm extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          // Campos básicos
          TextFormField(
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) => EmailValidator.validate(value!),
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Nombre'),
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Apellido'),
          ),
          
          // 🆕 Campos adicionales
          TextFormField(
            decoration: InputDecoration(labelText: 'Teléfono'),
          ),
          DatePickerField(
            labelText: 'Fecha de Nacimiento',
            onDateSelected: (date) => fechaNacimiento = date,
          ),
          
          // Avatar picker
          AvatarPicker(
            onImageSelected: (file) => avatarFile = file,
          ),
          
          ElevatedButton(
            onPressed: _register,
            child: Text('Registrarse'),
          ),
        ],
      ),
    );
  }
}
```

### **2. Perfil de Usuario Expandido**
**Actualizar:** `lib/features/users/user_profile_screen.dart`

```dart
class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mi Perfil')),
      body: Column(
        children: [
          // Avatar circular con opción de cambio
          CircleAvatar(
            radius: 50,
            backgroundImage: user.avatarUrl != null 
              ? NetworkImage(user.avatarUrl!) 
              : null,
            child: user.avatarUrl == null 
              ? Icon(Icons.person, size: 50) 
              : null,
          ),
          
          // Información personal
          ListTile(
            leading: Icon(Icons.person),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Text('Nombre completo'),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text(user.email),
            subtitle: Text('Email'),
            trailing: user.emailVerified 
              ? Icon(Icons.verified, color: Colors.green)
              : Icon(Icons.warning, color: Colors.orange),
          ),
          ListTile(
            leading: Icon(Icons.phone),
            title: Text(user.phone ?? 'No especificado'),
            subtitle: Text('Teléfono'),
          ),
          ListTile(
            leading: Icon(Icons.cake),
            title: Text(user.fechaNacimiento?.toString() ?? 'No especificado'),
            subtitle: Text('Fecha de nacimiento'),
          ),
          
          // Estado de verificación
          Card(
            child: ListTile(
              leading: Icon(
                user.isActive ? Icons.check_circle : Icons.block,
                color: user.isActive ? Colors.green : Colors.red,
              ),
              title: Text('Estado: ${user.estadoRegistro}'),
              subtitle: Text(user.isActive ? 'Cuenta activa' : 'Cuenta inactiva'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔄 **Plan de Implementación por Pasos**

### **Fase 1: Configuración Base (1-2 días)**
1. ✅ Configurar Flutter para web
2. ✅ Actualizar URLs y configuración de API
3. ✅ Verificar conectividad básica con backend
4. ✅ Probar login existente

### **Fase 2: Modelos y Servicios (2-3 días)**
1. 🔄 Actualizar modelo User con nuevos campos
2. 🔄 Crear modelo UserAuthProvider
3. 🔄 Actualizar AuthService para nuevos endpoints
4. 🔄 Crear PlayerService
5. 🔄 Actualizar UserService

### **Fase 3: UI y UX (3-4 días)**
1. 🔄 Actualizar formularios de registro
2. 🔄 Mejorar pantalla de perfil
3. 🔄 Implementar subida de avatar
4. 🔄 Agregar validación de campos
5. 🔄 Mejorar manejo de estados

### **Fase 4: Testing y Optimización (1-2 días)**
1. 🔄 Probar todas las funcionalidades
2. 🔄 Optimizar rendimiento web
3. 🔄 Verificar responsividad
4. 🔄 Testing en múltiples navegadores

---

## ✅ **Checklist de Integración**

### **Backend:**
- [ ] Endpoints de auth funcionando
- [ ] CORS configurado para web
- [ ] Nuevos campos en base de datos
- [ ] Validaciones implementadas

### **Frontend:**
- [ ] Modelos actualizados
- [ ] Servicios conectados
- [ ] Pantallas actualizadas
- [ ] Manejo de errores

### **Testing:**
- [ ] Login/registro funciona
- [ ] Perfil se carga correctamente
- [ ] Nuevos campos se guardan
- [ ] Navegación entre pantallas
