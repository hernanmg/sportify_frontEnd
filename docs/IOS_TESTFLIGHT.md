# iOS: de cero a TestFlight (KeepSync Sports)

Guía para publicar la app en TestFlight desde Windows usando **Codemagic** (compila en Mac en la nube).

### Nombre de marca

Marca actual: **KeepSync Sports** (antes Sportify / Sportify Amateur).

| Qué | Valor | ¿Se puede cambiar después? |
|-----|-------|----------------------------|
| Nombre en el iPhone / App Store | `KeepSync Sports` | Sí, en cualquier build |
| Bundle ID | `app.keepsync.sports` | **No** una vez creado el App ID en Apple |

El package Dart interno del repo (`sportify_amateur`) no se ve en la tienda; no hace falta renombrarlo.

---

## 1. Qué ya quedó listo en el código

| Área | Estado |
|------|--------|
| Bundle ID | `app.keepsync.sports` (igual que Android) |
| iOS mínimo | 13.0 (`project.pbxproj` + `ios/Podfile`) |
| Dispositivos | Solo iPhone (`TARGETED_DEVICE_FAMILY = 1`) |
| Face ID | `NSFaceIDUsageDescription` + `local_auth` |
| Contactos | `NSContactsUsageDescription` + macro `PERMISSION_CONTACTS` en Podfile |
| Cámara / fotos (comprobantes, escudos) | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` |
| Push | `Runner.entitlements` (aps-environment), `UIBackgroundModes: remote-notification`, delegate en `AppDelegate.swift`, espera del token APNs antes de pedir el token FCM |
| Cifrado (export compliance) | `ITSAppUsesNonExemptEncryption = false` → TestFlight no pregunta en cada build |
| Facebook SDK | Configurado en `Info.plist` solo para que la app no crashee al abrir (el login con Facebook no está expuesto) |
| Eliminar cuenta (regla 5.1.1(v)) | Perfil → Seguridad → Eliminar cuenta (pide contraseña, anonimiza datos) |
| Cerrar sesión | Perfil → botón "Cerrar sesión" y en Seguridad |
| Ícono | PNG sin canal alfa (Apple rechaza íconos con transparencia) |
| Pipeline | `codemagic.yaml` → workflow `ios-testflight` |

### Sign in with Apple: NO hace falta

La regla 4.8 de Apple exige "Sign in with Apple" **solo si la app ofrece login con Google/Facebook u otro tercero**. La pantalla de login real (`/login`) es solo email + contraseña, así que no aplica.

> Si en el futuro se habilita Google o Facebook en iOS, hay que sumar Sign in with Apple **antes** de subir esa versión.

---

## 2. Apple Developer Program (con la SAS)

1. **D-U-N-S** de la SAS (gratis): se pide desde el formulario de Apple
   ([developer.apple.com/enroll/duns-lookup](https://developer.apple.com/enroll/duns-lookup/)). Suele tardar de 5 a 14 días hábiles.
2. Requisitos para inscribirse como **Organización**:
   - Razón social exacta igual a la del D-U-N-S.
   - Sitio web con dominio propio (puede ser una landing simple).
   - Email con ese dominio (recomendado).
   - Quien inscribe debe tener autoridad legal para firmar por la SAS.
3. Inscribirse en [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/) con un Apple ID con **2FA activado**. Costo: USD 99/año.
4. Anotar el **Team ID** (Membership details), que tiene 10 caracteres.

> Alternativa rápida: inscribirse como persona física (sin D-U-N-S). En la tienda aparece tu nombre como vendedor. Después se puede migrar a organización, pero es un trámite con soporte de Apple.

---

## 3. Identificador de la app y Push

1. [Certificates, IDs & Profiles](https://developer.apple.com/account/resources/identifiers/list) → **Identifiers** → `+` → App IDs → App.
   - Description: `KeepSync Sports`
   - Bundle ID (Explicit): `app.keepsync.sports`
   - Capabilities: marcar **Push Notifications**.
2. **Keys** → `+` → nombre `KeepSync APNs` → marcar **Apple Push Notifications service (APNs)** → descargar el `.p8`. Se descarga **una sola vez**, así que guardalo. Anotar el **Key ID**.

---

## 4. Firebase (push)

Los package/bundle viejos (`app.sportify`, `sportify.amateur`, `com.example.sportifyAmateur`) ya no valen. Hay que registrar **Android e iOS** con `app.keepsync.sports`.

1. [Firebase Console](https://console.firebase.google.com/) → proyecto `sportify-amateur-dev` → Configuración del proyecto.
2. **Agregar app → Android**
   - Nombre del paquete: `app.keepsync.sports`
   - Descargar y reemplazar `android/app/google-services.json`
   - En `lib/firebase_options.dart` (bloque `android`), actualizar `appId` si cambió.
3. **Agregar app → iOS**
   - ID del paquete: `app.keepsync.sports`
   - Descargar `GoogleService-Info.plist` (solo para copiar el `GOOGLE_APP_ID`; no hace falta agregarlo al proyecto).
   - En `lib/firebase_options.dart` (bloque `ios`), reemplazar `appId`. `iosBundleId` ya está en `app.keepsync.sports`.
4. **Cloud Messaging** → app iOS `app.keepsync.sports` → **Clave de autenticación de APNs** → subir el `.p8`, con su Key ID y Team ID.
5. Podés borrar las apps viejas de Firebase cuando las nuevas funcionen.

> El id del proyecto Firebase (`sportify-amateur-dev`) es interno; no hace falta renombrarlo.

---

## 5. App Store Connect

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com/) → Apps → `+` → Nueva app.
   - Plataforma: iOS
   - Nombre: `KeepSync Sports` (si está tomado, probar `KeepSync Sports - Equipos`)
   - Idioma principal: Español (México) o Español (España)
   - Bundle ID: `app.keepsync.sports`
   - SKU: `keepsync-001`
2. Entrar a la app → **Información de la app** → copiar el **Apple ID** numérico (ej. `6740000000`).
3. Pegar ese número en `codemagic.yaml` → `APP_STORE_APPLE_ID`.

### API key para Codemagic

1. App Store Connect → **Usuarios y acceso** → **Integraciones** → **App Store Connect API** → Claves de equipo → `+`.
   - Nombre: `Codemagic`
   - Acceso: **App Manager**
2. Descargar el `.p8` (una sola vez) y anotar el **Issuer ID** y el **Key ID**.

---

## 6. Codemagic

1. Crear cuenta en [codemagic.io](https://codemagic.io/) (plan gratuito: 500 min/mes en Mac M2, alcanza para unos 20 a 30 builds).
2. **Teams → Integrations → Developer Portal / App Store Connect** → Add key:
   - Nombre: **`KeepSync ASC`** (tiene que coincidir con `integrations.app_store_connect` en `codemagic.yaml`)
   - Issuer ID, Key ID y el `.p8` del paso anterior.
3. **Code signing identities → iOS certificates** → "Generate certificate" (tipo Apple Distribution) con la misma key. Codemagic lo guarda y lo reutiliza.
4. Agregar la app: conectar el repositorio (GitHub/GitLab/Bitbucket). Codemagic detecta `codemagic.yaml`.
5. **Start new build** → rama → workflow **iOS TestFlight**.

El workflow hace lo siguiente:
- `flutter pub get` y `pod install`.
- Descarga o crea el perfil de App Store para `app.keepsync.sports`.
- Calcula el build number como el último de TestFlight más uno.
- Ejecuta `flutter build ipa` con `API_BASE_URL` apuntando a Render.
- Sube a App Store Connect y lo manda a TestFlight.

La versión visible sale de `version:` en `pubspec.yaml` (hoy `0.1.0`).

---

## 7. TestFlight

Después de subir, Apple procesa el build (de 10 a 30 minutos). Te llega un email.

| Tipo | Quiénes | Revisión de Apple |
|------|---------|-------------------|
| **Internos** | Hasta 100 usuarios del equipo de App Store Connect (Usuarios y acceso) | No |
| **Externos** | Hasta 10.000 por email o link público | Sí (Beta App Review, ~24 h, solo el primer build de cada versión) |

Para externos, completar en TestFlight → Información de prueba:
- Descripción de la beta y email de feedback.
- **Cuenta demo** (email + contraseña de un usuario de prueba con equipo cargado).
- Qué probar (se puede reutilizar `docs/GUIA_TESTER_JUGADOR.md`).

El tester instala la app **TestFlight** desde la App Store y acepta la invitación.

---

## 8. Qué probar en el primer build (iPhone real)

- [ ] Registro y login con email.
- [ ] Face ID: activarlo en Seguridad, cerrar la app y volver a abrir.
- [ ] Push: pedir permiso, recibir una convocatoria con la app cerrada y abierta, y que al tocarla navegue al detalle.
- [ ] Contactos: crear evento → invitar externo desde contactos.
- [ ] Cámara/galería: subir comprobante de cuota.
- [ ] Compartir (share) y PDF de reportes.
- [ ] Cerrar sesión.
- [ ] Eliminar cuenta con un usuario descartable y verificar que no puede volver a entrar.

> Push **no funciona en simulador**. Si no llega en un iPhone real, revisar el `.p8` en Firebase y que la app iOS de Firebase tenga el bundle `app.keepsync.sports`.

---

## 9. Antes de pasar de TestFlight a App Store (checklist)

- [ ] **Política de privacidad** publicada en una URL (obligatoria).
- [ ] **Etiquetas de privacidad** (App Privacy) en App Store Connect:
  - Datos de contacto: nombre, email y teléfono, vinculados al usuario, para funcionalidad de la app.
  - Contenido del usuario: fotos (comprobantes y escudos).
  - Contactos: solo si se sube el teléfono de invitados al backend (hoy sí, al invitar externos).
  - Identificadores: ID de usuario.
  - Sin tracking ni publicidad.
- [ ] Capturas: iPhone 6.9" (1320×2868) obligatorias; 6.5" opcional.
- [ ] Descripción, palabras clave, URL de soporte, categoría (Deportes).
- [ ] Cuenta demo en "Información para la revisión".
- [ ] Backend estable: Render free tiene cold start de 30 a 60 s. El revisor puede reportarlo como "la app no carga" (regla 2.1), así que conviene un plan pago o un ping que lo mantenga despierto.
- [ ] Clasificación por edad: 4+.

---

## 10. Backend

Los cambios de cuenta requieren **redeploy en Render**:
- `DELETE /users/me` (JWT, body `{ "password": "..." }`): soft delete + anonimización + baja de tokens de push.
- `GET /users/:id` ahora exige JWT y no devuelve `passwordHash`.
- `POST /users`, `PUT /users/:id` y `DELETE /users/:id` quedan solo para `super_admin` / `manager`.

---

## 11. Problemas frecuentes

| Error | Solución |
|-------|----------|
| `No matching profiles found for bundle identifier "app.keepsync.sports"` | Falta el App ID (paso 3) o la key de Codemagic no es App Manager |
| `Invalid large app icon ... alpha channel` | Regenerar íconos con `remove_alpha_ios: true` (ya configurado en `pubspec.yaml`) |
| `The bundle version must be higher than the previously uploaded version` | Revisar `APP_STORE_APPLE_ID` en `codemagic.yaml` (lo usa para calcular el build number) |
| La app se cierra al abrir | Revisar las claves `Facebook*` en `Info.plist` |
| Push no llega | Key APNs en Firebase, `appId` iOS en `firebase_options.dart` y permiso aceptado en el iPhone |
| `ITMS-91053 Missing API declaration` (email de Apple) | Solo es un aviso: actualizar plugins (`flutter pub upgrade`). Si persiste, agregar `PrivacyInfo.xcprivacy` en `ios/Runner` |
