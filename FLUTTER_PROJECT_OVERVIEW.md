# 📱 Sportify Amateur - Flutter Frontend

## 🏗️ **Arquitectura del Proyecto**

### **Estructura de Directorios**
```
lib/
├── 📁 core/                    # Núcleo de la aplicación
│   ├── 📁 common/              # Configuraciones y clientes
│   │   ├── app_config.dart     # URLs y configuración
│   │   ├── dio_client.dart     # Cliente HTTP con interceptores
│   │   ├── themes.dart         # Temas de la aplicación
│   │   └── themes_provider.dart # Provider de temas
│   └── 📁 services/            # Servicios de negocio
│       ├── auth_services.dart
│       ├── user_service.dart
│       ├── role_service.dart
│       └── [otros servicios]
├── 📁 features/                # Funcionalidades por módulos
│   ├── 📁 auth/               # Autenticación
│   │   ├── login.dart
│   │   └── user_login.dart
│   ├── 📁 dashboard/          # Panel principal
│   ├── 📁 users/              # Gestión de usuarios
│   ├── 📁 roles/              # Gestión de roles
│   ├── 📁 games/              # Gestión de partidos
│   ├── 📁 events/             # Gestión de eventos
│   ├── 📁 gameStats/          # Estadísticas
│   └── 📁 notifications/      # Notificaciones
├── 📁 models/                 # Modelos de datos
│   ├── user.dart
│   ├── role.dart
│   ├── game.dart
│   └── event.dart
└── main.dart                  # Punto de entrada
```

## 🔧 **Tecnologías y Dependencias**

### **Dependencias Principales:**
- **🌐 Comunicación HTTP:** `dio: ^5.7.0` + `http: ^1.0.0`
- **🔐 Autenticación:** `google_sign_in`, `flutter_facebook_auth`
- **💾 Almacenamiento:** `flutter_secure_storage`, `shared_preferences`
- **🎨 UI/UX:** `provider`, `font_awesome_flutter`, `fl_chart`
- **📊 Exportación:** `csv`, `pdf`

### **Plataformas Soportadas:**
- ✅ **Android** (configurado y funcional)
- ✅ **Web** (preparado para desarrollo local)
- ✅ **iOS** (estructura lista)
- ✅ **Windows/Linux/macOS** (desktop preparado)

## 🔌 **Conectividad con Backend**

### **Configuración de API:**
```dart
// lib/core/common/app_config.dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000', // Android Emulator
);
```

### **Cliente HTTP Configurado:**
- ✅ **Interceptores automáticos** para tokens JWT
- ✅ **Refresh token automático** en caso de expiración
- ✅ **Headers consistentes** para todas las requests
- ✅ **Manejo de errores** centralizado

### **Servicios Implementados:**
1. **AuthService** - Login email/Google/Facebook
2. **UserService** - CRUD de usuarios
3. **RoleService** - Gestión de roles y permisos
4. **GameService** - Gestión de partidos
5. **EventService** - Gestión de eventos
6. **NotificationService** - Sistema de notificaciones

## 🎯 **Funcionalidades Principales**

### **✅ Implementadas:**
- 🔐 **Autenticación multi-método** (Email, Google, Facebook)
- 👥 **Gestión de usuarios y roles**
- 🏆 **Dashboard con estadísticas**
- 📊 **Visualización de datos** con FL Chart
- 🎮 **Gestión de partidos y eventos**
- 📱 **Interfaz responsive**
- 🌙 **Tema claro/oscuro**

### **🔄 En desarrollo:**
- Conexión completa con backend actualizado
- Sincronización de nuevos campos (posición, fecha_nacimiento, etc.)
- Optimización para web

## 🚀 **Estado del Proyecto**

### **✅ Fortalezas:**
- Arquitectura limpia y escalable
- Manejo robusto de autenticación
- UI moderna y funcional
- Preparado para múltiples plataformas

### **🔧 Necesita actualización:**
- URLs de backend para desarrollo local
- Modelos para nuevos campos de base de datos
- Configuración específica para web
- Integración con nueva tabla `user_auth_providers`

---

## 📋 **Próximos Pasos:**

1. **Configurar para desarrollo web local**
2. **Actualizar URLs de backend**
3. **Sincronizar modelos con BD actualizada**
4. **Probar conectividad con backend NestJS**
5. **Optimizar para desarrollo simultáneo**
