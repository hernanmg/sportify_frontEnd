# Android: de APK compartido a Play Store

Guía práctica para Sportify Amateur (`applicationId`: `sportify.amateur`).

Complementa el backend: `backend_sportify_amateur/.../docs/RENDER_DEPLOY.md`.

---

## ¿Es demasiado pronto para “prod”?

**No para preparar el camino. Sí para abrir la tienda al público general.**

| Enfoque | Cuándo | Pros | Contras |
|---------|--------|------|---------|
| **APK por Drive / WhatsApp** (como ahora) | Piloto con 5–20 personas | Rápido, sin revisión Google | No hay updates automáticos; usuarios deben instalar “fuentes desconocidas”; cada build hay que reenviar |
| **Play Console → pruebas internas / cerradas** | Ya, en paralelo al piloto | Updates limpios, crashlytics, track de versiones, misma app que prod | Cuesta cuenta de desarrollador (pago único); hay que firmar bien y completar ficha mínima |
| **Play Store producción (público)** | Después de 1–2 semanas estables con Guille/Maxi + smoke OK | Distribución real | Políticas, privacidad, reviews; un bug se ve en público |

**Recomendación:** seguir compartiendo APK **y** abrir **prueba interna** en Play (hasta 100 testers por email). Eso *es* el camino a prod, sin ser “lanzamiento público”.

No esperes a “terminar el producto”: el store se prepara mientras el piloto valida.

---

## Estado actual del proyecto (checklist rápido)

| Ítem | Estado hoy | Acción antes de Play |
|------|------------|----------------------|
| `applicationId` | `sportify.amateur` | Ideal: `com.tuempresa.sportify` **antes** del primer upload (después cuesta cambiar) |
| Firma release | Usa `signingConfigs.debug` | Obligatorio: keystore propio de upload |
| API | Render (`API_BASE_URL`) | Build release con `--dart-define` fijo a prod |
| Versión | `pubspec.yaml` → `0.1.0` | Subir `version: x.y.z+N` en cada upload (`N` = versionCode) |
| Permisos | contactos, cámara, biometría, notifs | Declarar en Play Console + política de privacidad |
| Login Google/Facebook | Integrados | Verificar OAuth con SHA-1 del keystore de **release** |
| Push (FCM) | Firebase | SHA-1 release en Firebase Console |

---

## Camino A — seguir con APK (piloto)

1. Backend estable en Render (migraciones aplicadas, cold start aceptable).
2. Build:

```bash
cd d:\Dev\flutter\dev\sportify_amateur

flutter build apk --release ^
  --dart-define=API_BASE_URL=https://sportify-backend-yyqe.onrender.com
```

3. APK en: `build/app/outputs/flutter-apk/app-release.apk`
4. Compartir por Drive/WhatsApp. En el teléfono: permitir instalar apps desconocidas.
5. Anotar versión (`0.1.0+1`) en el mensaje al grupo para saber qué tienen instalado.

> Este APK firmado con **debug** no sirve para Play Store. Solo para pruebas manuales.

---

## Camino B — preparar Play Store (recomendado en paralelo)

### 1. Cuenta de desarrollador

1. [Google Play Console](https://play.google.com/console) → crear cuenta (tarifa única de desarrollador).
2. Completar perfil de pago / identidad (puede tardar 24–48 h la verificación).

### 2. Application ID definitivo

Si vas a cambiar `sportify.amateur` → hacerlo **ahora**:

- `android/app/build.gradle` → `applicationId` y `namespace`
- Carpetas Kotlin / `MainActivity` si aplica
- Firebase / Google Sign-In / Facebook: re-registrar el nuevo package name

Una vez publicada una app con un ID, **no se puede renombrar** en Play.

### 3. Keystore de upload (obligatorio)

En una máquina segura (y backup offline):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Crear `android/key.properties` ( **no commitear** ; agregar a `.gitignore`):

```properties
storePassword=***
keyPassword=***
keyAlias=upload
storeFile=../upload-keystore.jks
```

En `android/app/build.gradle`, cargar el keystore y usarlo en `release` (dejar de usar `signingConfigs.debug` en release).

Guardar el `.jks` y contraseñas en un gestor de secretos / USB cifrado. **Si se pierde, no podés actualizar la app en Play.**

### 4. SHA-1 / SHA-256 del keystore release

```bash
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Registrar huellas en:

- Firebase Console → Project settings → Android app
- Google Cloud Console → OAuth (Google Sign-In)
- Facebook Developers (si aplica)

### 5. Versión en cada release

En `pubspec.yaml`:

```yaml
version: 0.1.1+2
```

- `0.1.1` = versionName (visible al usuario)
- `+2` = versionCode (entero que **siempre sube** en Play)

### 6. Build App Bundle (lo que pide Play)

```bash
flutter build appbundle --release ^
  --dart-define=API_BASE_URL=https://sportify-backend-yyqe.onrender.com
```

Salida: `build/app/outputs/bundle/release/app-release.aab`

### 7. Crear la app en Play Console

1. Crear app → nombre, idioma por defecto (español), tipo (app), gratis/paga.
2. Declaraciones: anuncios (¿sí/no?), contenido, público objetivo (edad).
3. **Política de privacidad** (URL pública obligatoria si pedís contactos, cámara, etc.).
   - Puede ser una página simple en Notion / GitHub Pages / tu dominio.
4. Ficha de tienda corta:
   - Título, descripción corta/larga
   - Icono 512×512
   - Feature graphic 1024×500
   - Al menos 2 capturas de teléfono
5. Clasificación de contenido (cuestionario).
6. Países / zonas (empezar solo Argentina está bien).

### 8. Track de prueba (no producción pública)

Orden sugerido:

1. **Prueba interna** — emails de Guille, Maxi, vos (hasta 100).
2. **Prueba cerrada** — lista más grande del club (opcional).
3. **Producción** — cuando el piloto no tenga bugs bloqueantes.

Subí el `.aab` → release notes en español → enviar a revisión del track interno (suele ser más rápido que producción).

### 9. Smoke en dispositivo real (antes de producción)

Checklist mínima (10 taps):

- [ ] Login (email + Google si aplica)
- [ ] Home jugador / Home DT según rol
- [ ] Confirmar convocatoria
- [ ] Ver cuota / informar pago
- [ ] Push al recibir convocatoria (app en background)
- [ ] Contactos en evento social (permiso)
- [ ] Cold start: abrir app con API “dormida” y ver mensaje amigable + reintento
- [ ] Actualización: instalar vN+1 desde Play encima de vN

---

## Backend “prod” alineado con el store

Antes de usuarios reales fuera del círculo chico:

| Variable / tema | Sugerencia |
|-----------------|------------|
| `RUN_DEMO_SEED` | `false` en prod real |
| `DB_SYNCHRONIZE` | `false` |
| Backups Neon | activados |
| Dominio API | ideal custom (`api.tudominio.com`) en vez de `onrender.com` (cold start / branding) |
| Plan Render | free OK para piloto; paid si cold start molesta en el club |

La app del store **siempre** debe apuntar a la API de prod (no a localhost).

---

## Qué puede frenar la revisión de Google

- Pedir `READ_CONTACTS` / cámara sin explicar **para qué** en la ficha y en la política de privacidad.
- Firma debug o keystore distinto entre builds.
- App “incompleta” (crash al abrir, login roto).
- Data safety form mal completado (datos de usuario, finanzas del club).
- `AD_ID`: ya están intentando remover el permiso; mantenerlo así si no hay ads.

---

## Roadmap sugerido (4–6 semanas)

| Semana | Acción |
|--------|--------|
| 1 | Cuenta Play + decidir `applicationId` + generar keystore + backups |
| 1–2 | Política de privacidad + iconos/capturas mínimas |
| 2 | Primer `.aab` en **prueba interna**; Guille/Maxi desde Play |
| 2–3 | Seguir iterando: APK solo si hace falta; preferir updates por Play |
| 4+ | Si el club piloto está estable → track de producción (aún puede ser “no listada” / países limitados) |

---

## Comandos útiles

```bash
# Analizar
flutter analyze

# APK piloto
flutter build apk --release --dart-define=API_BASE_URL=https://sportify-backend-yyqe.onrender.com

# AAB Play Store
flutter build appbundle --release --dart-define=API_BASE_URL=https://sportify-backend-yyqe.onrender.com

# Ver firma del AAB (opcional, bundletool / jarsigner)
```

---

## Fuentes del repo

- `android/app/build.gradle` — `applicationId`, firma release
- `pubspec.yaml` — `version`
- `android/app/src/main/AndroidManifest.xml` — permisos
- Backend: `docs/RENDER_DEPLOY.md`
