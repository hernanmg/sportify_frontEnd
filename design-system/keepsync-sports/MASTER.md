# KeepSync Sports — Design System (Master)

Fuente de verdad visual para la app Flutter y alineada a la landing (`/` + `/keepsync/`).

> Nota: ui-ux-pro-max sugirió una paleta “sports red”; **se descartó** a favor de la marca KeepSync (Ink + Volt + Pitch Blue).

## Product type
Sports team ops / SaaS mobile (plantel, finanzas, convocatorias).

## Style direction
- **Producto (app):** Ink + Volt al frente (dark-first). OLED-friendly, alto contraste, CTA Volt siempre con texto Ink.
- **Empresa (landing):** Paper/blanco + Ink; proceso en Ink con números Volt; Pitch Blue en links e industrias.
- Evitar: purple/pink AI gradients, CTAs pulsantes, blanco puro como fondo de producto oscuro.

## Color tokens

| Token | Hex | Uso |
|-------|-----|-----|
| Ink | `#0A1628` | Fondo oscuro / texto |
| Ink 2 | `#12233D` | Tarjetas dark |
| Ink 3 | `#1B3152` | Superficies elevadas dark |
| Volt | `#C8F031` | CTA / acento (texto encima = Ink) |
| Volt 2 | `#B4DC1E` | Hover Volt |
| Pitch Blue | `#3D6BFF` | Links / secundario |
| Turf | `#12B76A` | Éxito |
| Flare | `#F04438` | Error |
| Paper | `#F4F6FA` | Fondo light |
| Border light/dark | `#DDE3EE` / `#24395C` | Bordes |
| Muted light/dark | `#4A5A72` / `#A9B6CC` | Texto atenuado |
| Finance + dark | `#47E08F` | Positivo sobre Ink |
| Finance − dark | `#FF8A80` | Negativo sobre Ink |
| Finance + light | `#067647` | Positivo sobre Paper |
| Finance − light | `#C4231A` | Negativo sobre Paper |
| On Volt muted | `#3A4A12` | Texto chico sobre badge Volt |

## Flutter
- Tokens: `lib/core/theme/keepsync_colors.dart`
- Themes M3: `lib/core/theme/keepsync_theme.dart`
- Acceso semántico: `context.ks` (`KeepSyncThemeExt`)
- Default `ThemeMode.dark`

## Do / Don't
- **Do:** `Theme.of(context).colorScheme` / `KeepSyncColors` / `context.ks`
- **Do:** Volt CTA → `onPrimary` Ink
- **Don't:** `Colors.blue` / `Colors.green` hardcodeados en pantallas nuevas
- **Don't:** texto blanco sobre Volt

## Checklist pre-entrega
- [ ] Contraste texto ≥ 4.5:1
- [ ] Focus / estados visibles
- [ ] Reduced motion respetado donde haya animaciones
- [ ] Light + dark revisados
