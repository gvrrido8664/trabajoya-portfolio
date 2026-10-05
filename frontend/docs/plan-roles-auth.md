# Plan — Selección de rol y cuentas multi-rol (login/registro)

> **Fecha:** 2026-07-13 · Deriva de la sesión de arreglo de Google Sign-In (ver [BACKEND_API.md](BACKEND_API.md) para el contrato de `/auth/social`).
> **Estado:** ✅ **Implementado completo el 2026-07-13.** La decisión de la sección 3 se tomó (Opción B) y las Fases 1-4 de la sección 5 están hechas y en producción (backend desplegado a Fly, frontend compilado y listo para `deploy.ps1`). El detalle técnico completo de la migración vive en el plan de implementación de esa sesión; este documento queda como registro de la decisión de producto y su contrato.

---

## 1. Contexto

Al revisar el login con Google se encontró una inconsistencia de producto (no un bug de conexión): **la pantalla de login no deja elegir rol, la de registro sí.**

- [`login_screen.dart:87`](../lib/features/auth/presentation/pages/login_screen.dart#L87) — el botón de Google llama `auth.loginWithGoogle(rol: 'cliente')` **fijo**. Si alguien nuevo entra por ahí queriendo ser proveedor, queda registrado como cliente sin darse cuenta ni poder elegir.
- [`register_screen.dart:285`](../lib/features/auth/presentation/pages/register_screen.dart#L285) — sí respeta el toggle Cliente/Proveedor (`_isCliente`) que el usuario elige antes de tocar el botón de Google.
- Backend, [`routes_auth.py:353`](../../trabajoya-api/app/api/routes_auth.py#L353) (`POST /auth/social`): el parámetro `rol` que manda el frontend **solo se usa la primera vez que se crea la cuenta**. Si el `google_id` o el email ya existen, el usuario entra con el rol que ya tenía en la base — el `rol` enviado se ignora en silencio, sin avisar nada.

Este último punto genera un caso confuso: alguien con cuenta de cliente selecciona "Proveedor" en el registro, toca "Continuar con Google", y el backend lo deja entrar igual como cliente (porque el email ya existía) sin ningún mensaje que explique por qué no cambió de rol.

## 2. Arreglo inmediato (bajo riesgo, recomendado hacer ya) — ✅ implementado

1. ~~Agregar el mismo selector Cliente/Proveedor de `register_screen.dart` a `login_screen.dart`~~ — hecho. El toggle se extrajo a un widget compartido [`RoleToggleButton`](../lib/features/auth/presentation/widgets/role_toggle_button.dart) (antes vivía privado dentro de `register_screen.dart`) y ahora aparece en ambas pantallas, justo antes de los botones de Google/Apple.
2. ~~Avisar cuando el rol pedido no coincide con el rol real de la cuenta~~ — hecho el 2026-07-13, y **retirado** ese mismo día al implementar la Opción B: con capacidades por cuenta (`es_cliente`/`es_proveedor`) el concepto de "rol pedido vs. rol real" deja de existir — toda cuenta nueva nace cliente y el registro/login social ya no manda un rol a elegir, así que `roleMismatch()` y el selector de rol en el login se eliminaron (ver sección 5).
3. Bonus encontrado al implementar: tanto `login_screen.dart` como `register_screen.dart` navegaban según el rol **pedido** (`_isCliente`) en vez del rol **real** de la cuenta ya logueada — si había mismatch, mandaban al dashboard equivocado. Corregido de paso: ahora navegan según `auth.usuario?.rol`.
4. Alcance real: solo frontend, tal como se estimó. No se tocó el backend.

## 3. Decisión: ¿una cuenta puede ser cliente y proveedor a la vez? — ✅ Opción B

Hoy `Usuario.rol` es un único valor (`'cliente' | 'proveedor' | 'admin'`) y **toda la arquitectura da por hecho que es fijo**: `ClienteShell` vs `ProveedorShell` en el router, `RolePalette`/`ProColors` vs `CliColors`, dashboards separados, permisos de endpoints (`get_current_provider`, etc.). No es un flag aislado — está en el centro del diseño.

Tres caminos posibles, de menor a mayor esfuerzo:

| Opción | Qué implica | Esfuerzo | Cuándo tiene sentido |
|---|---|---|---|
| **A. Statu quo** — una cuenta, un rol fijo. Si alguien quiere ser cliente y proveedor, crea dos cuentas (con el mismo email no se puede hoy: `email` es único). | Ninguno — solo documentar la limitación y comunicarla bien en el registro. | — | Si el modelo de negocio no necesita que la misma persona publique servicios y también los contrate desde una sola identidad. |
| **B. Modo activo, un solo rol "guardado" pero cambiable** (como Uber rider/driver) — el usuario tiene ambos roles habilitados y elige "Entrar como cliente" / "Entrar como proveedor" en un selector, la app cambia de shell según el modo activo. | Medio: `Usuario` pasa a tener `roles: List<String>` o dos flags (`es_cliente`, `es_proveedor`) en vez de `rol` único; agregar selector de modo (persistente, ej. en `AuthProvider`); el router y los shells leen el modo activo en vez de `usuario.rol` directamente; migración de datos (`rol` actual → el flag correspondiente en true). | Reescribir cada `usuario.rol == 'x'` esparcido por el código (frontend y backend) para que lea el modo activo. Grande pero mecánico. | Si el negocio SÍ quiere permitir "soy cliente y a veces también ofrezco servicios" con una sola identidad/reputación. |
| **C. Multi-rol simultáneo en la misma sesión** (ej. barra que muestra ambos dashboards, sin "cambiar de modo") | Alto: no es solo el modelo de datos, es repensar navegación, verificación (¿un solo documento sirve para los dos roles?), pagos/cobros (¿la misma cuenta bancaria recibe pagos y los hace?), y probablemente confunde más de lo que ayuda en un marketplace de dos lados. | Alto, con riesgo de UX confusa. | Rara vez conviene en un marketplace de dos lados (comprador/vendedor); la mayoría de apps similares usan la opción B, no C. |

**Se resolvió por la Opción B** (modo activo, como Uber) — identidad única con capacidades, no cuentas separadas (A) ni multi-rol simultáneo (C).

## 4. Respuestas a las preguntas de negocio

1. **¿Una persona necesita ser cliente y proveedor con la misma cuenta?** Sí — se prioriza una sola identidad con capacidades sobre "crea otra cuenta", para no duplicar identidad ni fragmentar confianza/reputación.
2. **¿Verificación, rating e historial compartidos o por modo?** Mixto: **verificación de identidad y datos personales compartidos** (se verifica a la persona, no al rol — un documento aprobado sirve para ambos modos); **rating separado por rol** (`avg_rating_proveedor` ≠ `avg_rating_cliente` — significan cosas distintas y no deben contaminarse); **historial de contrataciones separado en la UI por modo**, unificado a nivel de cuenta para soporte/antifraude.
3. **¿Quién activa el modo proveedor?** Cualquiera puede iniciar el flujo desde su perfil, pero el modo **no se habilita hasta `doc_estado == 'approved'`** — la misma barra de verificación que ya exigía el registro directo como proveedor.

## 5. Plan de ejecución — ✅ completo (2026-07-13)

- [x] **Fase 0:** selector de rol en login + aviso de rol existente *(implementada y luego retirada, ver §2.2)*.
- [x] **Fase 1 — Backend:** columnas nuevas en `usuarios` (`es_cliente`, `es_proveedor`, `proveedor_activado_at`, `avg_rating_proveedor`, `avg_rating_cliente`), migración Alembic + SQL manual aplicada en Supabase, guards migrados de rol a capacidad (`get_current_provider` y checks inline en solicitudes/contrataciones/propuestas — efecto deliberado: un proveedor ya puede contratar), endpoint `POST /usuarios/me/activar-proveedor` (gated por `doc_estado`), `rating_service.py` unifica los dos endpoints de reseña divergentes y separa el cálculo por rol. 45/45 tests pasando. Desplegado a Fly.
- [x] **Fase 2 — Frontend:** `AuthProvider.activeMode` persistido en `AppStorage` (con seed: proveedores legacy entran directo a su shell), `switchMode()`/`activarModoProveedor()`, `router.dart` migrado de `usuario.rol` a `activeMode`/capacidad (incluye `refreshListenable`), theming (`RolePalette.of`) migrado de rol a modo, switch de modo en el footer del sidebar (`AppSidebar`) y CTA "Ofrece tus servicios" en el perfil cliente (`_ModoProveedorCard`), rating mostrado por contexto (proveedor ve `avgRatingProveedor`, cliente ve `avgRatingCliente`). Registro/login simplificados: toda cuenta nace cliente, el toggle del registro pasa a ser pregunta de intención que encadena a `/seguridad/identidad`, y se retiró `roleMismatch`/el selector de rol del login (ya no aplican con capacidades). `flutter analyze` y `flutter build web` limpios.
- [x] **Fase 3 (parcial):** limpieza de código muerto hecha sobre la marcha (`get_current_client` no usado se eliminó del backend en vez de forzarlo). Pendiente para más adelante, no bloqueante: que el backend deje de aceptar `rol` en registro/social, migrar stats de admin a capacidades, y unificar los dos perfiles (`ProfileAmplioScreen`/`PerfilProveedorScreen`) si se decide.

## 6. Relacionado: Apple Sign-In

El botón de Apple hoy es un placeholder (ver [plan-apple-signin.md](plan-apple-signin.md)). Es una integración aparte, con su propio bloqueante (cuenta paga de Apple Developer) — no depende de las decisiones de este documento, pero **el selector de rol de la Fase 0 (§2) le sirve gratis** en cuanto se implemente, sin trabajo adicional.
