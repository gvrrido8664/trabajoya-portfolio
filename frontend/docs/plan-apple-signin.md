# Plan — Sign in with Apple

> **Fecha:** 2026-07-13 · Relacionado con [plan-roles-auth.md](plan-roles-auth.md) (mismo selector de rol aplicaría acá).
> **Estado:** propuesta, no implementado. Depende de una decisión de negocio (§2) antes de poder arrancar.

---

## 1. Estado actual

El botón de Apple ya existe en la UI pero es un placeholder: en [`login_screen.dart:74`](../lib/features/auth/presentation/pages/login_screen.dart#L74) y [`register_screen.dart:272`](../lib/features/auth/presentation/pages/register_screen.dart#L272), cualquier proveedor distinto de `'Google'` solo muestra un snackbar *"Apple Sign-In estará disponible próximamente"* — no dispara ningún flujo real.

El backend ya tiene el terreno preparado pero no implementado:
- [`Usuario.auth_provider`](../../trabajoya-api/app/models/usuario.py#L27) ya documenta `local | google | apple` como valores válidos — el campo está listo, falta el código que lo use.
- [`routes_auth.py:363`](../../trabajoya-api/app/api/routes_auth.py#L363) (`POST /auth/social`) rechaza con 400 cualquier `provider` que no sea `"google"` — hoy es literalmente imposible loguearse con Apple aunque el frontend lo intentara.
- `python-jose` (usado para JWT en todo el proyecto) ya está en `requirements.txt` — es la misma librería que se necesita para validar el token de Apple, no hay que agregar una dependencia nueva ahí.

## 2. Requisito bloqueante: cuenta de pago de Apple Developer

A diferencia de Google (gratis), **Sign in with Apple exige una membresía paga de Apple Developer Program (99 USD/año)** — es uno de los servicios restringidos que Apple no habilita sin cuenta paga, ni siquiera para probarlo en desarrollo.

**Antes de planificar el resto, hay que confirmar: ¿existe ya una cuenta de Apple Developer para TrabajoYa, o hay que contratarla?** Si no existe, este ítem no puede avanzar hasta que se resuelva eso — es la primera pregunta a responder, no un detalle técnico.

## 3. Qué hay que configurar (una vez con la cuenta paga)

En el portal de Apple Developer:
1. Crear un **Services ID** (identificador tipo `cl.somostrabajoya.web`, distinto del bundle ID de una eventual app iOS nativa).
2. Habilitar "Sign in with Apple" en ese Services ID.
3. Registrar el/los dominio(s) en **Domains and Subdomains** (`somostrabajoya.cl`, y el dominio de dev si aplica).
4. Registrar la **Return URL** — el callback donde Apple devuelve el resultado del login (ej. `https://api.somostrabajoya.cl/auth/apple/callback`). Este debe ser un endpoint del **backend**, no del frontend: Apple en web usa `response_mode=form_post`, es decir, hace un POST directo con el resultado — el frontend nunca lo recibe solo.

En el frontend web:
- Agregar el script `https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js` en `web/index.html` (mismo patrón que ya existe ahí para el script de Google).
- El dominio debe servir en HTTPS (ya cumplido: `api.somostrabajoya.cl` y `somostrabajoya.cl` tienen certificado).

## 4. Trabajo de implementación estimado

| Parte | Qué implica | Complejidad vs. lo que ya se hizo con Google |
|---|---|---|
| Backend: nuevo endpoint de callback | Recibir el POST de Apple (`form_post`), no un JSON simple como `/auth/social` hoy. Probablemente conviene un endpoint dedicado `POST /auth/apple/callback` en vez de forzarlo dentro de `/auth/social`. | Mayor — Apple no tiene un endpoint tipo `tokeninfo` como Google; hay que **verificar la firma del JWT vos mismo** contra las claves públicas de Apple (`https://appleid.apple.com/auth/keys`), usando `python-jose` (ya instalado). |
| Backend: mapeo a `Usuario` | Igual que Google: buscar por `apple_id` (habría que agregar esa columna, análoga a `google_id`) → si no existe, buscar por email → si no existe, crear cuenta con `rol` elegido. | Igual de complejidad que el flujo de Google ya implementado — se puede copiar el patrón de `social_login()`. |
| Frontend web | Sign in with Apple en web **no tiene un paquete Flutter tan directo como `google_sign_in_web`** para el flujo completo; suele resolverse llamando al JS SDK (`AppleID.auth.init()` / `signIn()`) desde Dart via `dart:js_interop`, o con el paquete `sign_in_with_apple` (que sí sirve para iOS/macOS nativo, su soporte web es más limitado). Hay que evaluar cuál camino conviene al momento de implementar. | Mayor incertidumbre que Google — necesita una investigación de spike antes de comprometer un estimado de tiempo. |
| Selector de rol | Reusa exactamente el mismo trabajo de [plan-roles-auth.md §2](plan-roles-auth.md#2-arreglo-inmediato-bajo-riesgo-recomendado-hacer-ya) — si ese selector ya está construido para Google, Apple lo hereda gratis. | — |

## 5. Recomendación

No es un "agregar un botón más" — es una integración completa nueva con un costo fijo anual y un flujo backend distinto al de Google (verificación de JWT propia en vez de un endpoint de Google que hace el trabajo). Antes de estimar tiempos de desarrollo, se necesita:

1. Confirmar si hay presupuesto/cuenta de Apple Developer.
2. Decidir si vale la pena priorizarlo ahora frente a otras mejoras del roadmap (ver [provider-ui-roadmap.md](provider-ui-roadmap.md) y [ui-audit-master.md](ui-audit-master.md) para comparar contra el resto del backlog).

Si la respuesta a (1) es sí, el trabajo técnico es viable con las piezas que ya existen en el proyecto (`python-jose`, patrón de `social_login()`, el propio botón placeholder ya en la UI).
