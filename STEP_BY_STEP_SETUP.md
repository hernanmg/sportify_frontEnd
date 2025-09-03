# 🚀 Guía Paso a Paso - Sportify Amateur Web Setup

## 📋 **Resumen de Archivos Creados**

He creado 4 documentos de referencia:
1. **`FLUTTER_PROJECT_OVERVIEW.md`** - Análisis completo de la estructura
2. **`WEB_SETUP_GUIDE.md`** - Configuración para desarrollo web
3. **`BACKEND_INTEGRATION_PLAN.md`** - Plan de integración completa
4. **`STEP_BY_STEP_SETUP.md`** - Esta guía paso a paso

---

## 🎯 **Fase 1: Configuración Web Básica**

### **Paso 1.1: Verificar Flutter Web**
```bash
cd /home/gringo/Documents/DevOps/flutter/dev/sportify_amateur

# Habilitar web (si no está habilitado)
flutter config --enable-web

# Verificar dispositivos
flutter devices
```
**Resultado esperado:** Ver `Chrome (web) • chrome • web-javascript`

---

### **Paso 1.2: Actualizar Configuración de API**

**Editar:** `lib/core/common/app_config.dart`

**Cambiar de:**
```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);
```

**A:**
```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _getDefaultUrl(),
  );

  static String _getDefaultUrl() {
    // Para web usa localhost, para Android usa 10.0.2.2
    if (identical(0, 0.0)) {
      return 'http://localhost:3000';  // Web
    } else {
      return 'http://10.0.2.2:3000';  // Android
    }
  }
}
```

**Resultado esperado:** URL automática según plataforma

---

### **Paso 1.3: Probar Conectividad Web**

```bash
# Terminal 1: Asegurar que el backend esté corriendo
cd /home/gringo/Documents/DevOps/flutter/dev/backend_sportify_amateur/sportify_amateur
npm run start:dev

# Terminal 2: Ejecutar Flutter Web
cd /home/gringo/Documents/DevOps/flutter/dev/sportify_amateur
flutter run -d chrome --web-port 8080
```

**Resultado esperado:** 
- Backend en `http://localhost:3000`
- Frontend en `http://localhost:8080`
- Página de login visible

---

### **Paso 1.4: Verificar Login Básico**

1. **Abrir navegador:** `http://localhost:8080`
2. **Intentar login** con credenciales de prueba
3. **Abrir DevTools** (F12) → Network tab
4. **Verificar requests** a `localhost:3000`

**Resultado esperado:** Ver requests HTTP al backend (aunque fallen por CORS)

---

## 🔧 **Fase 2: Solucionar CORS (si es necesario)**

### **Paso 2.1: Verificar CORS en Backend**

**Revisar:** `/home/gringo/Documents/DevOps/flutter/dev/backend_sportify_amateur/sportify_amateur/src/main.ts`

**Asegurar que tiene:**
```typescript
app.enableCors({
  origin: [
    'http://localhost:8080',  // Flutter Web
    'http://10.0.2.2:3000',  // Android
  ],
  credentials: true,
});
```

### **Paso 2.2: Reiniciar Backend si se Hizo Cambios**
```bash
# En el terminal del backend
# Ctrl+C para detener
npm run start:dev
```

---

## 🎨 **Fase 3: Actualizar UI para Web**

### **Paso 3.1: Mejorar web/index.html**

**Editar:** `web/index.html`

**Agregar antes de `</head>`:**
```html
<!-- Viewport para responsive -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<!-- Para Google Sign-In en web -->
<script src="https://accounts.google.com/gsi/client" async defer></script>
```

### **Paso 3.2: Probar Responsividad**

1. **Redimensionar ventana** del navegador
2. **Probar en modo móvil** de DevTools
3. **Verificar que la UI se adapte**

**Resultado esperado:** Interfaz responsive

---

## 📱 **Fase 4: Testing de Funcionalidades**

### **Paso 4.1: Probar Autenticación**

**En el navegador web:**
1. **Login con email/password**
2. **Verificar en Network tab** las requests
3. **Comprobar almacenamiento** de tokens
4. **Probar navegación** post-login

### **Paso 4.2: Probar Navegación**

1. **Dashboard**
2. **Gestión de usuarios**
3. **Roles y permisos**
4. **Estadísticas**

**Resultado esperado:** Navegación fluida sin errores de consola

---

## 🔍 **Troubleshooting Común**

### **Error: "Chrome no encontrado"**
```bash
# Instalar Chrome si no está instalado
sudo apt update
sudo apt install google-chrome-stable

# O usar Chromium
sudo apt install chromium-browser
flutter run -d chromium
```

### **Error: CORS**
```
Access to XMLHttpRequest blocked by CORS policy
```
**Solución:** Verificar configuración CORS en backend `main.ts`

### **Error: "Connection refused"**
**Solución:** 
1. Verificar que backend esté corriendo en puerto 3000
2. Comprobar que Docker PostgreSQL esté activo

### **Error: Hot reload no funciona**
```bash
# Reiniciar con flag adicional
flutter run -d chrome --web-port 8080 --debug
```

---

## ✅ **Checklist de Verificación**

### **Configuración Básica:**
- [ ] Flutter web habilitado
- [ ] URL configurada para localhost
- [ ] Backend corriendo en puerto 3000
- [ ] Frontend corriendo en puerto 8080

### **Conectividad:**
- [ ] Página de login carga
- [ ] Requests aparecen en Network tab
- [ ] Sin errores CORS en consola
- [ ] Login básico funciona

### **UI/UX:**
- [ ] Interfaz responsive
- [ ] Navegación fluida
- [ ] Temas claro/oscuro funcionan
- [ ] Sin errores en consola del navegador

---

## 🎯 **Próximos Pasos Recomendados**

### **Una vez que Fase 1-4 funcionen:**

1. **Actualizar modelos** según `BACKEND_INTEGRATION_PLAN.md`
2. **Implementar nuevos campos** (fecha_nacimiento, posición, etc.)
3. **Mejorar formularios** de registro y perfil
4. **Agregar subida de avatares**
5. **Implementar notificaciones en tiempo real**

---

## 💡 **Comandos de Desarrollo Diario**

```bash
# Terminal 1: Backend
cd backend_sportify_amateur/sportify_amateur && npm run start:dev

# Terminal 2: Base de datos (si no está corriendo)
cd backend_sportify_amateur/sportify_amateur && npm run db:start

# Terminal 3: Frontend Web
cd sportify_amateur && flutter run -d chrome --web-port 8080

# Terminal 4: (Opcional) Android
cd sportify_amateur && flutter run
```

---

**¿Quieres empezar con el Paso 1.1?** 🚀
