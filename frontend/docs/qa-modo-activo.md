# QA — Identidad única con capacidades y modo activo

> **Fecha:** 2026-07-15 · Complementa [plan-roles-auth.md](plan-roles-auth.md). Backend desplegado a Fly, frontend compilado y pendiente de `deploy.ps1`.

---

## 1. Cómo funciona ahora

### El modelo mental

Antes: una cuenta tenía **un** rol fijo (`cliente` | `proveedor` | `admin`), decidido para siempre en el registro.

Ahora: una cuenta tiene **capacidades** (puede ser cliente, puede ser proveedor, ambas a la vez) y un **modo activo** que decide qué ve en cada momento — como elegir "modo pasajero" o "modo conductor" en Uber.

- **Toda cuenta nace cliente.** `es_cliente = true` por defecto para todos.
- **El modo proveedor se activa, no se elige al registrarse.** Requiere verificación de identidad aprobada (`doc_estado == 'approved'`) antes de que `es_proveedor` pase a `true`.
- **El campo `rol` legacy se conserva** (solo distingue `admin` del resto en la práctica) — nada lo borra, es la fuente de verdad para las cuentas viejas y para no romper nada que todavía lo lea.
- **El "modo activo" (`cliente` | `proveedor`) vive solo en el frontend**, guardado en `AppStorage` bajo la clave `active_mode`. El backend nunca lo ve — autoriza por capacidad (`es_proveedor`/`es_cliente`), no por modo.

### Backend (`trabajoya-api`)

| Pieza | Qué hace |
|---|---|
| `usuarios.es_cliente`, `usuarios.es_proveedor` | Columnas nuevas, booleanas. Ya migradas y pobladas en Supabase. |
| `usuarios.avg_rating_proveedor`, `usuarios.avg_rating_cliente` | Rating separado por rol — calificar a alguien como proveedor no afecta su rating como cliente y viceversa. `avg_rating` (legacy, global) se sigue actualizando también. |
| `usuarios.proveedor_activado_at` | Timestamp de cuándo se activó el modo proveedor (auditoría). |
| `POST /usuarios/me/activar-proveedor` | Activa `es_proveedor=true`. 403 si `doc_estado != 'approved'`. Idempotente. |
| `get_current_provider` (dependencies.py) | Ahora exige `es_proveedor` (capacidad), no `rol == 'proveedor'`. |
| Checks de `solicitudes`/`contrataciones`/`propuestas` | Migrados a `es_cliente`/`es_proveedor`. **Efecto deliberado: un proveedor ya puede contratar servicios de otros** (antes estaba bloqueado por rol). |
| `app/services/rating_service.py` | Único lugar que crea reseñas y recalcula los 3 ratings (global/proveedor/cliente). Tanto `POST /resenas/{id}` como `POST /contrataciones/{id}/resena` delegan ahí — antes eran dos implementaciones divergentes con bugs distintos. |

### Frontend (`trabajoya-app`)

| Pieza | Qué hace |
|---|---|
| `AuthProvider.activeMode` | `'cliente'` o `'proveedor'`. Se resuelve tras cada login/checkAuth: respeta lo guardado en `AppStorage` si la cuenta todavía tiene esa capacidad; si no hay nada guardado y el `rol` legacy es `proveedor`, arranca ahí (para no descolocar a los proveedores que ya existían antes de este cambio). |
| `AuthProvider.switchMode('cliente'\|'proveedor')` | Cambia el modo (valida que la cuenta tenga la capacidad), persiste, notifica. |
| `AuthProvider.activarModoProveedor()` | Llama al endpoint nuevo, refresca el usuario, cambia a modo proveedor. |
| `router.dart` | Los redirects post-login y los guards de `/perfil`, `/admin`, `/proveedor/*` ahora leen `activeMode`/capacidad, no `usuario.rol`. `/proveedor/:id` (perfil público) queda **excluido** del guard de capacidad a propósito. |
| Sidebar (desktop) | Footer con botón "Cambiar a modo Proveedor/Cliente". Solo aparece "→ Proveedor" si la cuenta tiene la capacidad; "→ Cliente" siempre aparece en el sidebar Pro (todos tienen `es_cliente=true`). |
| Perfil cliente → card **"Ofrece tus servicios"** | Tres estados: (a) ya tiene capacidad → botón para cambiar de modo; (b) `doc_estado=='approved'` pero sin capacidad → botón "Activar modo Proveedor"; (c) sin verificar → botón a `/seguridad/identidad`. **Es también el único punto de entrada en móvil** (el bottom nav no tiene footer). |
| Registro | El toggle Cliente/Proveedor ya no decide el `rol` de la cuenta (siempre nace `cliente`) — ahora es una pregunta de intención: si eligió "Proveedor", después de crear la cuenta lo manda directo a `/seguridad/identidad`. |
| Login | Ya no tiene selector de rol (no tenía sentido: el rol/capacidad ya existe en la cuenta). |

---

## 2. Checklist de pruebas manuales

Marca cada uno probándolo en la app real (no solo leyendo el código). Los marcados con **⚠️** son los que más probabilidad tienen de estar rotos — priorízalos.

### Registro

- [ ] Registrar cuenta nueva con toggle en "Cliente" → entra a `/cliente`, sin pedir nada de identidad.
- [ ] Registrar cuenta nueva con toggle en "Proveedor" → tras crear la cuenta, aterriza en `/seguridad/identidad` (no en `/proveedor` — todavía no tiene la capacidad).
- [ ] Registrar con Google (botón real, web) con intención "Proveedor" → mismo comportamiento: cuenta nueva como cliente, redirige a verificación.
- [ ] Registrar con Google en **móvil** (si hay build nativa a mano) con ambas intenciones.
- [ ] Registrar con un email que ya existe como cuenta de Google existente (proveedor legado) → debe entrar a SU cuenta real, no crear una nueva ni reasignarle nada.

### Login

- [ ] Login con email/password de una cuenta cliente normal → `/cliente`.
- [ ] Login con email/password de un proveedor **legado** (creado antes de esta migración) → debe aterrizar directo en `/proveedor` (el seed de `activeMode`), no en `/cliente`. **⚠️ Este es el caso más importante de probar** — si falla, todos los proveedores existentes ven la app rota el día del deploy.
- [ ] Login con Google (botón real) de una cuenta existente → entra a su modo activo actual, sin pedir nada de rol.
- [ ] Login de una cuenta `admin` → va a `/admin` (o `/seguridad/2fa` si no tiene TOTP activado), nunca pasa por `/cliente` o `/proveedor`.

### Activar modo proveedor (el flujo nuevo)

- [ ] Desde el perfil cliente, con cuenta **sin verificar**: botón dice "Verificar identidad", lleva a `/seguridad/identidad`.
- [ ] Subir documentos → estado pasa a "en revisión" → el botón del perfil debe reflejar "Verificación en revisión" (no debe ofrecer activar todavía).
- [ ] Un admin aprueba la verificación (`admin_verificaciones_screen`) → el usuario recarga/vuelve al perfil → el botón ahora dice "Activar modo Proveedor".
- [ ] Tocar "Activar modo Proveedor" → llama al backend, cambia a modo proveedor, navega a `/proveedor`. **⚠️ Probar también qué pasa si se toca dos veces seguidas** (debe ser idempotente, no debe romper ni duplicar nada).
- [ ] Con cuenta rechazada (`doc_estado == 'rejected'`) → confirmar qué mensaje ve el usuario (hoy cae en el mismo texto que "pendiente"; decidir si conviene un mensaje distinto).

### Switch de modo (cuenta con ambas capacidades)

- [ ] Desktop: en el sidebar de cliente, con una cuenta que YA es proveedor, debe aparecer "Cambiar a modo Proveedor" en el footer. Tocarlo navega a `/proveedor` y el sidebar cambia al tema Pro.
- [ ] Desktop: en el sidebar de proveedor, "Cambiar a modo Cliente" siempre visible. Tocarlo vuelve a `/cliente`.
- [ ] Móvil: no hay botón en el bottom nav — confirmar que el switch **solo** es alcanzable desde el perfil, y que efectivamente funciona ahí.
- [ ] Cerrar la app (o refrescar en web) después de cambiar de modo → al volver a entrar, **debe recordar el último modo elegido**, no resetear al default.
- [ ] Cerrar sesión y volver a entrar con la misma cuenta → el modo debe resolverse de nuevo desde cero (no debe quedar pegado el modo de otro usuario si comparten dispositivo/navegador). **⚠️ Importante en web**: `active_mode` se guarda en `localStorage`, que es **global por navegador, no por pestaña ni por usuario** — probar específicamente el caso "cerrar sesión de un proveedor → loguear una cuenta cliente nueva en el mismo navegador" y confirmar que NO hereda el modo proveedor por error.

### Navegación cruzada / guards

- [ ] Estando en modo cliente, escribir manualmente `/proveedor/dashboard` en la URL (web) sin tener la capacidad → debe redirigir a `/cliente/perfil`, no mostrar la pantalla.
- [ ] Ir a `/proveedor/algún-uuid` (perfil público de un proveedor) **sin** tener capacidad proveedor → esto **debe funcionar igual** (es la ruta pública `/proveedor/:id`, no debe estar bloqueada por el guard nuevo). **⚠️ Este es el caso que más fácil se rompe** si el guard de capacidad se aplica de más.
- [ ] Reseñar una contratación **desde el lado proveedor** (antes solo el cliente podía reseñar) → confirmar que el formulario de reseña aparece y que al enviarla se actualiza `avg_rating_cliente` de la contraparte, no `avg_rating_proveedor`.
- [ ] Como proveedor, intentar contratar el servicio de OTRO proveedor (nueva capacidad habilitada) → debe funcionar de punta a punta (crear contratación, chatear, pagar).
- [ ] Como proveedor, intentar contratar tu **propio** servicio → debe seguir bloqueado (400 "no puedes contratar tu propio servicio", no un error de permisos).

### Rating y perfil

- [ ] Perfil cliente muestra `avgRatingCliente` (no el rating de proveedor, aunque la cuenta tenga ambas capacidades).
- [ ] Perfil proveedor (`/proveedor/perfil`) muestra `avgRatingProveedor`.
- [ ] Dejar una reseña como cliente a un proveedor → verificar en el perfil de ESE proveedor que su rating subió/bajó correctamente, y que el rating que ve el mismo proveedor **como cliente** (si tiene ambas capacidades) no cambió.

### Cosas que NO deberían haber cambiado (regresión)

- [ ] Login con 2FA (TOTP) sigue pidiendo el código igual que antes.
- [ ] `roleMismatch`/selector de rol ya no aparecen en el login — confirmar que de verdad desaparecieron de la UI, no solo del código.
- [ ] El botón de Apple (placeholder) sigue mostrando "próximamente", sin romperse por los cambios de layout alrededor.
- [ ] Datos bancarios (`bank_info_card.dart`) siguen apareciendo solo si la cuenta tiene capacidad proveedor (esto se dejó por **capacidad**, no por modo, a propósito — un proveedor viendo su perfil en modo cliente sigue teniendo sus datos bancarios intactos si vuelve a modo proveedor).

---

## 3. Riesgos conocidos / posibles bugs a vigilar

Cosas que noté al implementar y que decidí dejar así por alcance/tiempo, pero que vale la pena tener en el radar:

1. **Diálogos de `contratacion_detail_screen.dart` usan el modo activo de la cuenta para el tema, pero el contenido principal de la pantalla usa el rol *dentro de esa transacción específica*** (si sos cliente o proveedor *en ese contrato*, comparando IDs). Si una cuenta con ambas capacidades ve un contrato donde es proveedor mientras está en modo cliente, los diálogos (confirmar, abrir disputa, editar monto) podrían verse con un tema distinto al resto de la pantalla. Es un detalle visual, no rompe funcionalidad — pendiente de unificar si se nota feo en la práctica.
2. **`active_mode` es global por navegador en web**, no por pestaña (a diferencia del token de sesión, que sí es per-tab). Ver el caso de prueba correspondiente en la sección 2.
3. **`chat_panel.dart`** todavía infiere el rol de la otra persona en el chat usando el `rol` legacy de la cuenta (fallback, no la fuente principal), no el modo activo ni el rol dentro de esa contratación específica. Bajo riesgo (es solo un fallback cuando el backend no manda el rol explícito), pero si se nota mal etiquetado el interlocutor del chat, es el primer lugar a mirar.
4. **Cuentas con `doc_estado == 'rejected'`** ven el mismo botón/mensaje que las pendientes ("Verificación en revisión") en el CTA del perfil — no hay un mensaje específico de "fue rechazada, vuelve a intentar". Vale la pena revisarlo con una cuenta de prueba rechazada.
5. **El backend ahora deja que cualquier cuenta (incluidos proveedores) cree solicitudes y contrataciones** — es un cambio de comportamiento deliberado, pero si en algún dashboard de admin o métrica se contaban "solicitudes de clientes" asumiendo que solo clientes las creaban, esos números podrían cambiar de significado. No se tocaron las stats de admin en esta fase (ver plan-roles-auth.md §5, Fase 3 pendiente).
6. **Build de frontend cacheado**: si algún usuario tiene la PWA/web abierta desde antes del deploy y no refresca, puede estar corriendo el código viejo contra el backend nuevo. El modelo `Usuario.fromJson` tiene fallbacks para que el código viejo no se rompa contra el backend nuevo, pero no hay mecanismo de "fuerza refresco" — si se nota gente con comportamiento raro justo después del deploy, primero pedirles que refresquen/reinstalen.
