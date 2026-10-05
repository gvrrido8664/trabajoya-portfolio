# Plan: Migrar todas las pantallas al diseño de la landing pública

## Context
La landing pública (`landing_screen.dart`) fue rediseñada con un sistema visual moderno: tokens de spacing/radii/elevation, paleta semántica, tipografía Inter, y componentes consistentes. El resto de las pantallas mezclan colores hardcodeados, tamaños arbitrarios y no usan los tokens disponibles. Este plan migra cada pantalla de forma incremental para lograr coherencia visual total.

---

## Design system de referencia (extraído de landing_screen.dart)

| Elemento | Valor / Token |
|---|---|
| Colores | Siempre `AppColors.*` o `AppTheme.*` — cero hex hardcodeados |
| Spacing | `Spacing.xs/sm/md/lg/xl/xl2/xl3` de `tokens.dart` |
| Border radius | `Radii.sm/md/lg/xl/pill` de `tokens.dart` |
| Sombras | `Elevation.e0/e1/e2/e3` de `tokens.dart` |
| Tipografía | `Theme.of(context).textTheme.*` — cero `TextStyle(fontSize:...)` sueltos |
| Cards | `surface` blanco, border `AppColors.border`, radius `Radii.lg` (14px), sombra `e1` |
| Badges semánticos | `primaryLight`+`primaryDark` / `successLight`+`success` / `dangerLight`+`danger` |
| Mini-labels de sección | 11px, w700, letterSpacing 2.0, color `AppTheme.primary`, uppercase |
| Botones | 52px tall, `Radii.md` (12px) — ya definido en theme |
| AppBar | Transparente, `scrolledUnderElevation: 0.5`, sin elevation propia |
| Animaciones | `Motion.fast/base/slow` + `Motion.curve` de `tokens.dart` |

---

## Regla de migración (aplica a cada pantalla)

1. **Colores**: reemplazar todo `Color(0xFF...)` hardcodeado → token equivalente de `AppColors`/`AppTheme`
2. **Spacing**: reemplazar `EdgeInsets.all(16)` etc. → `EdgeInsets.all(Spacing.lg)` etc.
3. **Radii**: reemplazar `BorderRadius.circular(12)` → `BorderRadius.circular(Radii.md)` etc.
4. **Sombras**: reemplazar `BoxShadow(...)` manual → `Elevation.e1/e2/e3`
5. **Texto**: reemplazar `TextStyle(fontSize: 18, fontWeight: w700)` → `textTheme.titleLarge`
6. **Badges**: usar patrón `Container(color: AppColors.primaryLight, child: Text(style: color: AppColors.primaryDark))`
7. **AppBar**: asegurar `elevation: 0, scrolledUnderElevation: 0.5, backgroundColor: Colors.white`

---

## Orden de migración (1 x 1)

### Bloque 1 — Shells/Layouts (afectan todas las pantallas)
| # | Archivo | Cambios clave |
|---|---|---|
| 1 | `lib/features/admin/presentation/pages/admin_shell.dart` | Sidebar usa `AppColors.primaryDark` + tokens. Reemplazar todos los hex hardcodeados. Agregar soporte a dark mode vía `colorScheme`. |
| 2 | `lib/features/cliente/presentation/pages/cliente_shell.dart` | Ya usa `AdaptiveAppShell`. Verificar que logo y nav items usen tokens correctamente. |
| 3 | `lib/features/proveedor/presentation/pages/proveedor_shell.dart` | Mismo que cliente_shell — revisar consistencia. |

### Bloque 2 — Auth (punto de entrada del usuario)
| # | Archivo | Cambios clave |
|---|---|---|
| 4 | `lib/features/auth/presentation/pages/login_screen.dart` | Unificar a `theme.textTheme`, usar `Spacing` en paddings. |
| 5 | `lib/features/auth/presentation/pages/register_screen.dart` | Mismo patrón. Ya tiene 1 lint resuelto. |
| 6 | `lib/features/auth/presentation/pages/profile_screen.dart` | Sección de perfil con cards usando token pattern. |
| 7 | `lib/features/auth/presentation/pages/forgot_password_screen.dart` | Pantalla simple — spacing + tipografía. |
| 8 | `lib/features/auth/presentation/pages/reset_password_screen.dart` | Ídem. |
| 9 | `lib/features/auth/presentation/pages/email_verification_screen.dart` | Ídem. |

### Bloque 3 — Cliente (área principal de clientes)
| # | Archivo | Cambios clave |
|---|---|---|
| 10 | `lib/features/cliente/presentation/pages/cliente_landing_screen.dart` | Hero gradient → `AppColors.primaryDark` a `AppColors.primary`. Spacing tokens. Badges semánticos. |
| 11 | `lib/features/cliente/presentation/pages/mis_solicitudes_screen.dart` | Cards de solicitudes con patrón landing. Badges de estado con `AppTheme.statusColor`. |
| 12 | `lib/features/cliente/presentation/pages/crear_solicitud_screen.dart` | Form inputs ya en tema. Revisar headers de sección y spacing. |

### Bloque 4 — Proveedor
| # | Archivo | Cambios clave |
|---|---|---|
| 13 | `lib/features/proveedor/presentation/pages/oportunidades_screen.dart` | Base sólida. Limpiar `AppColors` directos → `colorScheme`. Aplicar `Elevation.e1`. |
| 14 | `lib/features/proveedor/presentation/pages/proveedor_profile_screen.dart` | Cards de perfil con patrón token. |

### Bloque 5 — Admin (mayor deuda de diseño)
| # | Archivo | Cambios clave |
|---|---|---|
| 15 | `lib/features/admin/presentation/pages/admin_full_dashboard_screen.dart` | Reescribir stat cards con `Elevation.e1` + badges semánticos. Tipografía → textTheme. Colores → colorScheme. |
| 16 | `lib/features/admin/presentation/pages/admin_usuarios_screen.dart` | Tabla/lista con cards estándar. |
| 17 | `lib/features/admin/presentation/pages/admin_servicios_screen.dart` | Ídem. |
| 18 | `lib/features/admin/presentation/pages/admin_pagos_screen.dart` | Ídem + badges de estado de pago con colores semánticos. |
| 19 | `lib/features/admin/presentation/pages/admin_suscripciones_screen.dart` | Ídem. |
| 20 | `lib/features/admin/presentation/pages/admin_disputas_screen.dart` | Badges de disputa → `dangerLight`/`danger`. |

### Bloque 6 — Servicios
| # | Archivo | Cambios clave |
|---|---|---|
| 21 | `lib/features/servicios/presentation/pages/servicio_detail_screen.dart` | Hero image + card de detalle con tokens. |
| 22 | `lib/features/servicios/presentation/pages/servicios_list_screen.dart` | List/grid con `ServicioCard` estándar. |
| 23 | `lib/features/servicios/presentation/pages/mis_servicios_screen.dart` | Cards con badge de estado activo/inactivo. |
| 24 | `lib/features/servicios/presentation/pages/crear_editar_servicio_screen.dart` | Form sections con headers de landing. |

### Bloque 7 — Contrataciones
| # | Archivo | Cambios clave |
|---|---|---|
| 25 | `lib/features/contrataciones/presentation/pages/mis_contrataciones_screen.dart` | Cards con `AppTheme.statusColor` y badges semánticos. |
| 26 | `lib/features/contrataciones/presentation/pages/contratacion_detail_screen.dart` | Timeline de estado con colores semánticos. |
| 27 | `lib/features/contrataciones/presentation/pages/solicitar_servicio_screen.dart` | Form con spacing tokens. |

### Bloque 8 — Chat
| # | Archivo | Cambios clave |
|---|---|---|
| 28 | `lib/features/chat/presentation/pages/conversaciones_screen.dart` | Lista de chats con avatar + badge de no leídos. |
| 29 | `lib/features/chat/presentation/pages/chat_screen.dart` | Burbujas con colores `primaryLight`/surface. |

### Bloque 9 — Pagos, Propuestas, Reseñas, Suscripciones, Splash
| # | Archivo | Cambios clave |
|---|---|---|
| 30 | `lib/features/pagos/presentation/pages/pago_screen.dart` | CTA button → `AppColors.success`. Resumen con card estándar. |
| 31 | `lib/features/pagos/presentation/pages/pago_resultado_screen.dart` | Success/error state con `successLight`/`dangerLight`. |
| 32 | `lib/features/propuestas/presentation/pages/enviar_propuesta_screen.dart` | Form estándar. |
| 33 | `lib/features/propuestas/presentation/pages/mis_propuestas_screen.dart` | Cards con badges de estado. |
| 34 | `lib/features/resenas/presentation/pages/resena_screen.dart` | Estrellas con `AppTheme.secondary`. Botón con `AppColors.success`. |
| 35 | `lib/features/suscripciones/presentation/pages/planes_screen.dart` | Pricing cards con `primaryLight` y borde `primary`. |
| 36 | `lib/features/splash/splash_screen.dart` | Logo + `AppColors.primary` background. |

---

## Archivos de referencia (no modificar, sólo consultar)
- `lib/features/public/presentation/pages/landing_screen.dart` — diseño objetivo
- `lib/shared/theme/tokens.dart` — todos los tokens disponibles
- `lib/utils/colors.dart` — paleta maestra
- `lib/app/theme.dart` — theme completo + `statusColor` helper
- `lib/features/proveedor/presentation/pages/oportunidades_screen.dart` — mejor pantalla existente

---

## Verificación por pantalla
Después de cada pantalla: `flutter analyze` sin errores, hot reload visual, revisar en mobile y desktop.
Después de cada bloque: smoke test de flujo completo del rol correspondiente.
