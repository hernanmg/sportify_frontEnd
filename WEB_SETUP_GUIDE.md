# 🌐 Sportify Amateur - Setup para Desarrollo Web

## 🎯 **Objetivo**
Configurar el proyecto Flutter para desarrollo web local, conectado al backend NestJS que corre en `localhost:3000`.

---

## 📋 **Pasos de Configuración**

### **Paso 1: Verificar Flutter Web**
```bash
# Desde la carpeta del proyecto Flutter
cd /path/to/sportify_amateur

# Verificar que Flutter tiene soporte web habilitado
flutter config --enable-web

# Verificar dispositivos disponibles
flutter devices
# Deberías ver: Chrome (web) • chrome • web-javascript
```

### **Paso 2: Actualizar Configuración de API**

**Editar:** `lib/core/common/app_config.dart`

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _getDefaultUrl(),
  );

  static String _getDefaultUrl() {
    // Detectar plataforma y retornar URL apropiada
    if (identical(0, 0.0)) {
      // Web
      return 'http://localhost:3000';
    } else {
      // Android Emulator
      return 'http://10.0.2.2:3000';
    }
  }
}
```

### **Paso 3: Configurar CORS en Backend**

**En tu backend NestJS** (ya configurado), asegurar que permite `localhost:3000`:

```typescript
// main.ts del backend
app.enableCors({
  origin: [
    'http://localhost:3000',     // Flutter Web
    'http://10.0.2.2:3000',     // Android Emulator
    'http://localhost:8080',     // Desarrollo local adicional
  ],
  credentials: true,
});
```

### **Paso 4: Actualizar URLs para Web**

**Editar:** `lib/core/services/auth_services.dart`

Cambiar la URL base para Google auth:
```dart
// Línea ~40
final response = await http.get(
  Uri.parse('$backendUrl/auth/google'), // Actualizar endpoint
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${googleAuth.accessToken}',
  },
);
```

### **Paso 5: Comando para Ejecutar en Web**

```bash
# Desarrollo web con hot reload
flutter run -d chrome --web-port 8080

# O especificar URL de backend
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:3000
```

---

## 🔧 **Configuraciones Adicionales para Web**

### **Actualizar `web/index.html`:**
```html
<!-- Agregar después de la línea 32 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<!-- Para Google Sign-In en web (antes de </head>) -->
<script src="https://accounts.google.com/gsi/client" async defer></script>
```

### **Configurar Google OAuth para Web:**

**Editar:** `lib/core/services/auth_services.dart`
```dart
// Agregar configuración específica para web
final GoogleSignIn _googleSignIn = GoogleSignIn(
  // Para web
  clientId: 'your-web-client-id.googleusercontent.com',
  scopes: ['email', 'profile'],
);
```

---

## 🚀 **Comandos de Desarrollo**

### **Desarrollo Simultáneo:**
```bash
# Terminal 1: Backend NestJS
cd backend_sportify_amateur/sportify_amateur
npm run start:dev

# Terminal 2: Flutter Web
cd sportify_amateur
flutter run -d chrome --web-port 8080
```

### **Build para Producción Web:**
```bash
# Build optimizado para web
flutter build web --release

# Build con URL específica
flutter build web --dart-define=API_BASE_URL=https://api.sportify.com
```

---

## 🔍 **Testing y Debugging**

### **URLs a Probar:**
- **Frontend:** `http://localhost:8080`
- **Backend:** `http://localhost:3000`
- **pgAdmin:** `http://localhost:8080` (puerto diferente)

### **Debug en Chrome DevTools:**
```bash
# Ejecutar con debugging
flutter run -d chrome --web-port 8080 --debug
```

### **Verificar Conectividad:**
1. Abrir Network tab en Chrome DevTools
2. Intentar login
3. Verificar requests a `localhost:3000/auth/login`
4. Comprobar headers y responses

---

## ⚡ **Optimizaciones para Desarrollo**

### **Hot Reload Mejorado:**
```bash
# Con análisis de rendimiento
flutter run -d chrome --web-port 8080 --profile
```

### **Configuración de VSCode:**

**`.vscode/launch.json`:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Web",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "-d",
        "chrome",
        "--web-port",
        "8080"
      ],
      "env": {
        "API_BASE_URL": "http://localhost:3000"
      }
    }
  ]
}
```

---

## 🚨 **Troubleshooting Común**

### **Error de CORS:**
```
Access to XMLHttpRequest at 'http://localhost:3000' from origin 'http://localhost:8080' has been blocked by CORS policy
```
**Solución:** Verificar configuración CORS en backend NestJS.

### **Google Sign-In no funciona en web:**
**Solución:** Configurar OAuth web client ID en Google Console.

### **Requests fallan:**
**Solución:** Verificar que el backend esté corriendo en puerto 3000.

---

## ✅ **Checklist de Configuración**

- [ ] Flutter web habilitado
- [ ] URLs actualizadas para localhost
- [ ] CORS configurado en backend
- [ ] Backend corriendo en puerto 3000
- [ ] Flutter web corriendo en puerto 8080
- [ ] Login básico funcionando
- [ ] Network requests visibles en DevTools
