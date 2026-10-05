# Plan de Aplicación — Consultoría de Pagos y Modelo de Negocio → TrabajoYa

> Convierte las recomendaciones de [ESTRATEGIA_PAGOS_Y_MODELO_NEGOCIO.md](ESTRATEGIA_PAGOS_Y_MODELO_NEGOCIO.md)
> en un plan concreto, aterrizado al **estado real del código** (app Flutter `trabajoya-app/` + backend
> FastAPI `trabajoya-api/`). No es un resumen: es un plan de implementación con archivos, riesgos y orden.

---

## ⚠️ Hallazgo que cambia todo el plan

**El proyecto ya fue MÁS LEJOS de lo que el consultor recomienda — en la dirección equivocada.**

El código actual:
- Cobra con **Webpay directo** (`trabajoya-api/app/services/webpay_service.py`) **y** Mercado Pago.
- En ambos casos **el 100% del dinero cae a la cuenta de la plataforma**.
- Calcula un `FEE_PLATAFORMA = 0.10` (10%) **solo como número de display** — `_build_estado()` en
  `routes_pagos.py:23`. **No existe split ni payout al proveedor.**
- Tiene `liberar_pago()` / `reembolsar_pago()` (`payment_service.py:203-236`) atados al ciclo de la
  contratación → comportamiento **escrow de facto**.

Traducción: **la plataforma hoy custodia fondos de terceros** (justo lo que el consultor dijo NO hacer)
**y además está incompleto** (el proveedor nunca recibe su plata por el sistema; solo existe reembolso).

> Por eso este plan **no es "construir pagos"** — los pagos ya existen. Es **replegarse del riesgo de
> custodia** y reorientar la monetización a lo que ya está medio construido y es legalmente limpio:
> **suscripciones + destacados**.

---

# 1. Resumen ejecutivo

### Qué propone el consultor
- **Pasarela:** agregador (Flow/Mercado Pago), **no** Webpay directo, **no** custodiar fondos.
- **Modelo v1:** **suscripción a profesionales + destacados** (pago directo, sin custodia, sin arbitraje).
- **Comisión por transacción:** solo Fase 2 y **vía split del agregador** (sin tocar la plata del proveedor).
- **Escrow de servicios:** **NO** en esta etapa (regulado, requiere capital + abogados + arbitraje inviable).
- **Cumplimiento:** checkout hospedado (PCI SAQ-A), Ley 21.719 (datos), KYC con proveedor externo.

### Qué tan alineado está el proyecto
| Dimensión | Alineación | Comentario |
|---|---|---|
| Agregador (MP) | 🟡 Parcial | MP existe, pero **sin split** → la plata se pooléa en la plataforma |
| Webpay directo | 🔴 Desalineado | Implementado; añade custodia que el consultor desaconseja |
| Suscripciones | 🟢 Alineado | Ya existe (`Plan`, `Suscripcion`, `/suscripciones`, `planes_screen`) |
| Destacados | 🟡 Parcial | `servicio.es_destacado` existe pero **no se vende** (lo setea admin) |
| Comisión por transacción | 🔴 Riesgoso | Existe pero como **custodia del 100%**, no como split |
| Escrow | 🔴 Desalineado | `liberar_pago`/reembolso atan el pago al ciclo de contratación |
| KYC / identidad | 🔴 Falta | Solo `telefono_verificado`; sin verificación de identidad |
| PCI / checkout hospedado | 🟢 Alineado | MP y Webpay usan redirect hospedado |

### Bloques de trabajo que salen de la comparación
1. **B-RIESGO — Replegar la custodia de fondos** (lo más urgente: legal + funcional).
2. **B-REVENUE — Reorientar a suscripción + destacados** (modelo v1 limpio, mayoría ya existe).
3. **B-SPLIT — Si se mantiene comisión por transacción, migrar a MP split** (Fase 2).
4. **B-COMPLIANCE — Datos (Ley 21.719) + KYC liviano externo**.
5. **B-DESINTERMEDIACIÓN — Valor pegajoso** para que no se vayan por fuera.

---

# 2. Hallazgos de mapeo (recomendación vs realidad)

### H1 — Webpay directo implementado (consultor: usar agregador)
- **Estado actual:** `webpay_service.py` con `WEBPAY_COMMERCE_CODE`/`WEBPAY_API_KEY`; endpoints
  `/pagos/webpay/crear|confirmar|estado` en `routes_pagos.py:107-175`. La plata cae a la plataforma.
- **Gap:** Webpay directo te hace comercio de registro y recaudador por cuenta de terceros.
- **Impacto:** 🔴 Alto (riesgo regulatorio + mantenimiento de dos pasarelas).

### H2 — Comisión = custodia del 100%, no split (consultor: split, sin tocar plata ajena)
- **Estado actual:** `FEE_PLATAFORMA=0.10`, `_calcular_fee/_calcular_neto` (`payment_service.py:31-35`),
  `_build_estado` (`routes_pagos.py:23-32`). **No hay `marketplace_fee`/`collector_id`/payout.**
- **Gap:** el "neto del proveedor" es un número de pantalla; el proveedor **no recibe nada** por el sistema.
- **Impacto:** 🔴 Alto (custodia de fondos + flujo incompleto).

### H3 — Escrow de facto (consultor: NO escrow de servicios)
- **Estado actual:** `liberar_pago()`/`reembolsar_pago()` (`payment_service.py:203-236`); el pago se valida
  contra `EstadoContratacion.ACEPTADO` (`routes_pagos.py:43`).
- **Gap:** retención + liberación atadas al ciclo del servicio = escrow, sin marco legal ni arbitraje.
- **Impacto:** 🔴 Alto (regulatorio + operacional).

### H4 — Suscripciones ya construidas (consultor: modelo v1) 🟢
- **Estado actual:** `Plan`/`Suscripcion` models, `/suscripciones/planes|crear|cancelar|me`,
  [planes_screen.dart](lib/features/suscripciones/presentation/pages/planes_screen.dart),
  [suscripciones_provider.dart](lib/features/suscripciones/presentation/providers/suscripciones_provider.dart).
- **Gap menor:** cobra vía MP `crear_preferencia` con `external_reference="suscripcion_PLAN_USER"`;
  **no hay renovación automática** (la suscripción se crea a 30 días fijos, `payment_service.py:138-139`),
  ni manejo de vencimiento/recordatorio.
- **Impacto:** 🟢 Bajo — es la base correcta; solo falta madurar el ciclo de vida.

### H5 — Destacados existe pero no se monetiza (consultor: destacados pagados)
- **Estado actual:** `servicio.es_destacado` (bool), seteado desde admin/servicios. No hay compra.
- **Gap:** falta el flujo "pagar para destacar" (pago directo → activa `es_destacado` con vigencia).
- **Impacto:** 🟡 Medio — **quick win de revenue** sin custodia.

### H6 — KYC inexistente (consultor: KYC con proveedor externo)
- **Estado actual:** solo `usuario.telefono_verificado`. Sin RUT, sin documento, sin verificación de
  identidad. (Memoria del proyecto: verificación/MFA fase 1 = plan aprobado, **código sin empezar**.)
- **Gap:** sin KYC no hay badge de confianza ni base para features pro de verificación.
- **Impacto:** 🟡 Medio (habilitador de confianza y de revenue; **no** bloqueante de v1).

### H7 — Cumplimiento de datos Ley 21.719 (consultor: obligatorio)
- **Estado actual:** existen [privacidad_screen.dart](lib/features/public/presentation/pages/privacidad_screen.dart)
  y [terminos_screen.dart](lib/features/public/presentation/pages/terminos_screen.dart) con texto genérico;
  headers de seguridad en `vercel.json`. Sin flujo formal de consentimiento ni derechos ARCO+.
- **Gap:** textos no validados legalmente; sin gestión de consentimiento/eliminación de datos.
- **Impacto:** 🟡 Medio (sube a Alto cerca de la vigencia ~2026).

### H8 — Desintermediación (consultor: riesgo #1 de la comisión)
- **Estado actual:** hay chat con historial, reseñas, contrataciones — buena base pegajosa.
- **Gap:** nada **fuerza** ni **incentiva** explícitamente a transar dentro (la comisión pura se evade).
- **Impacto:** 🟡 Medio (define si la comisión por transacción vale la pena).

---

# 3. Plan de aplicación

### B-RIESGO — Replegar custodia de fondos (PRIORIDAD MÁXIMA)
- **Acción concreta:** decidir y ejecutar **una** de dos rutas (ver comparación abajo):
  - **Ruta A (recomendada):** **desactivar el cobro por transacción** en v1. Dejar pagos solo para
    **suscripción y destacados** (pago directo del profesional, sin custodia). Webpay directo: **apagar**
    (feature flag), no borrar.
  - **Ruta B:** mantener comisión por transacción **pero migrando a MP split** (la plata del proveedor
    nunca cae a la plataforma) — esto es trabajo de Fase 2, no de v1.
- **Dónde:** `routes_pagos.py` (gate de `/pagos/crear` y `/pagos/webpay/*`), `payment_service.py`,
  `webpay_service.py`, [pago_screen.dart](lib/features/pagos/presentation/pages/pago_screen.dart),
  router/links en la app.
- **Orden:** **primero**. Todo lo demás depende de no seguir acumulando riesgo.
- **Riesgos:** romper un flujo que hoy "funciona" en demo. Mitigar con **feature flag** (`PAGOS_CONTRATACION_ENABLED`)
  en `config.py`, no con borrado.
- **Dependencias:** decisión de negocio (¿v1 cobra comisión o no?) + confirmación legal.

#### Comparación de rutas (custodia)
| | Ruta A — Sin comisión en v1 | Ruta B — Comisión con MP split |
|---|---|---|
| Custodia de fondos | ❌ Ninguna (limpio) | ❌ Ninguna (MP libera al proveedor) |
| Esfuerzo | Bajo (apagar flujo) | Alto (integrar split, onboarding de proveedores en MP) |
| Revenue inmediato | Suscripción + destacados | + comisión |
| Riesgo legal | Mínimo | Bajo (MP es el regulado) **si** se hace bien |
| Recomendación | ✅ **v1** | Fase 2 |

### B-REVENUE — Suscripción + destacados como modelo v1
- **Acción concreta:**
  1. **Madurar suscripciones:** manejar vencimiento real, estado `VENCIDA`, recordatorio antes de expirar,
     y gating de features por plan. Hoy la sub se crea a 30 días fijos sin renovación (`payment_service.py:138`).
  2. **Monetizar destacados:** endpoint "comprar destacado" → pago directo (MP preference) →
     al aprobarse, set `es_destacado=true` + `destacado_hasta` (nuevo campo con vigencia).
- **Dónde:** `routes_suscripciones.py`, `models/suscripcion.py`, `models/servicio.py` (+ migración para
  `destacado_hasta`), `routes_servicios.py`,
  [planes_screen.dart](lib/features/suscripciones/presentation/pages/planes_screen.dart),
  [mis_servicios_screen.dart](lib/features/servicios/presentation/pages/mis_servicios_screen.dart).
- **Orden:** segundo (es el revenue limpio que reemplaza al riesgoso).
- **Riesgos:** sub sin renovación automática → churn manual; mitigar con recordatorios y re-compra simple.
- **Dependencias:** B-RIESGO definido (saber si la comisión sigue o no).

### B-SPLIT — Comisión por transacción vía MP split (solo si se elige Ruta B / Fase 2)
- **Acción concreta:** integrar **MP modo marketplace**: cada proveedor conecta su cuenta MP (OAuth),
  y la preference usa `marketplace_fee` para que MP separe tu comisión y pague al proveedor directo.
- **Dónde:** `payment_service.crear_preferencia` (agregar `marketplace_fee`/collector del proveedor),
  nuevo flujo OAuth de vinculación de cuenta MP del proveedor, modelo `usuario.mp_account_id`.
- **Orden:** Fase 2 (no v1).
- **Riesgos:** fricción de onboarding (proveedor debe tener/crear cuenta MP); desintermediación persiste.
- **Dependencias:** B-DESINTERMEDIACIÓN (sin valor pegajoso, la comisión se evade igual).

### B-COMPLIANCE — Datos + KYC liviano
- **Acción concreta:**
  1. **Datos:** revisión legal de privacidad/términos para Ley 21.719; flujo de **consentimiento explícito**
     en registro; endpoint de **eliminación de cuenta/datos** (derecho ARCO+).
  2. **KYC:** integrar **proveedor externo** de verificación de identidad; guardar **resultado** (verificado
     sí/no + fecha), no el documento crudo; badge "Identidad verificada".
- **Dónde:** screens públicas de privacidad/términos, [register_screen.dart](lib/features/auth/presentation/pages/register_screen.dart),
  `routes_usuarios.py`, `models/usuario.py` (campos `identidad_verificada`, `identidad_verificada_at`).
- **Orden:** datos en Fase 1 (texto + consentimiento), KYC en Fase 2.
- **Riesgos:** costo por verificación del proveedor externo; elegir uno con cobertura Chile.
- **Dependencias:** decisión de negocio sobre proveedor KYC (investigación pendiente).

### B-DESINTERMEDIACIÓN — Valor pegajoso
- **Acción concreta:** reseñas verificadas atadas a la plataforma, agenda/recordatorios, badge de identidad,
  historial de chat como respaldo de disputas. Comunicar "pagar dentro = respaldo".
- **Dónde:** features de reseñas, chat, perfil; copy en pantallas de contratación/pago.
- **Orden:** transversal, refuerza Fase 2 antes de activar comisión.
- **Riesgos:** bajo; es construcción de producto incremental.
- **Dependencias:** ninguna dura.

---

# 4. Tabla de priorización

| Recomendación | Área | Estado actual | Acción | Impacto | Esfuerzo | Prioridad | Tipo |
|---|---|---|---|---|---|---|---|
| Replegar custodia de fondos | Backend pagos | Custodia 100% (MP+Webpay) | Feature-flag + apagar comisión/Webpay en v1 | 🔴 Alto | Bajo | **Alta** | Cambio estructural |
| Apagar Webpay directo | Backend pagos | Implementado | Flag off, no borrar | 🔴 Alto | Bajo | **Alta** | Quick win |
| Madurar ciclo de suscripción | Backend + app | Existe, sin vencimiento real | Estados + recordatorio + gating por plan | 🟢 Medio | Medio | **Alta** | Refactor medio |
| Monetizar destacados | Backend + app | `es_destacado` sin venta | Endpoint compra + `destacado_hasta` | 🟡 Medio | Medio | **Alta** | Refactor medio |
| Consentimiento datos (21.719) | App + legal | Texto genérico | Consentimiento + eliminación de datos | 🟡 Medio | Medio | **Media** | Refactor medio |
| KYC externo | Backend + app | Solo teléfono | Integrar proveedor + badge | 🟡 Medio | Alto | **Media** | Investigación + estructural |
| Valor anti-desintermediación | Producto | Base existe | Reseñas verif., agenda, copy | 🟡 Medio | Medio | **Media** | Refactor medio |
| Comisión vía MP split | Backend pagos | Sin split | OAuth MP proveedor + `marketplace_fee` | 🟡 Medio | Alto | **Baja** (Fase 2) | Cambio estructural |
| Quitar `geocoding`/limpieza pagos muertos | Backend | Dos pasarelas | Consolidar a MP | 🟢 Bajo | Bajo | **Baja** | Quick win |

---

# 5. Roadmap por fases

### Fase 1 — Repliegue de riesgo + revenue limpio (quick wins + base)
- **Objetivo:** salir de la custodia de fondos y dejar el modelo v1 (suscripción + destacados) operativo.
- **Tareas:**
  - Feature flag `PAGOS_CONTRATACION_ENABLED=false` + `WEBPAY_ENABLED=false` en `config.py`; gatear endpoints.
  - Ocultar/condicionar [pago_screen.dart](lib/features/pagos/presentation/pages/pago_screen.dart) para
    contrataciones; mantenerlo para suscripción/destacados.
  - Monetizar destacados (endpoint + `destacado_hasta` + UI en mis-servicios).
  - Madurar suscripción (vencimiento, recordatorio, gating por plan).
  - Revisión de privacidad/términos + consentimiento explícito en registro.
- **Riesgos:** romper demo de pago; mitigado con flags reversibles.
- **Dependencias:** decisión negocio (¿comisión en v1?) + ok legal a textos.
- **Resultado esperado:** plataforma sin custodia, cobrando suscripción y destacados, legalmente más limpia.

### Fase 2 — Comisión segura + confianza
- **Objetivo:** reintroducir comisión por transacción **sin custodia** y subir la confianza.
- **Tareas:** MP split (OAuth proveedor, `marketplace_fee`, `usuario.mp_account_id`); KYC externo + badge;
  features anti-desintermediación (reseñas verificadas, agenda).
- **Riesgos:** fricción onboarding MP; costo KYC.
- **Dependencias:** Fase 1 cerrada; proveedor KYC elegido (investigación).
- **Resultado esperado:** take-rate sin tocar plata ajena + sello de confianza.

### Fase 3 — Refactor técnico y consolidación
- **Objetivo:** simplificar la capa de pagos.
- **Tareas:** consolidar a un solo agregador (deprecando Webpay directo), unificar `payment_service`,
  tests de integración de webhooks, observabilidad de pagos.
- **Riesgos:** regresiones en webhooks; mitigar con tests + sandbox.
- **Dependencias:** Fase 2 estable.
- **Resultado esperado:** una sola pasarela, código de pagos mantenible.

### Fase 4 — Avanzado (solo si despega, con abogados)
- **Objetivo:** evaluar features que requieren marco legal/capital.
- **Tareas:** **escrow SOLO** vía cuenta de tercero regulado y categorías verificables; cobros
  internacionales (Stripe); analítica/financiamiento.
- **Riesgos:** regulatorio alto.
- **Dependencias:** tracción + márgenes + asesoría CMF.
- **Resultado esperado:** decisión informada, no impulsiva, sobre modelos avanzados.

---

# 6. Backlog accionable

> Formato: `[ID]` tarea — **área** · impacto · esfuerzo · prioridad · archivos · criterio de aceptación.

- `[PAY-1]` **Feature flags de pago** — Backend · Alto · Bajo · **Alta** ·
  `trabajoya-api/app/core/config.py`, `routes_pagos.py` ·
  *AC:* con `PAGOS_CONTRATACION_ENABLED=false`, `/pagos/crear` y `/pagos/webpay/*` responden 404/403; suscripción y destacados siguen funcionando.
- `[PAY-2]` **Apagar Webpay directo** — Backend · Alto · Bajo · **Alta** · `config.py`, `routes_pagos.py`, `webpay_service.py` ·
  *AC:* `WEBPAY_ENABLED=false` deshabilita endpoints Webpay sin borrar código; tests verdes.
- `[PAY-3]` **Ocultar pago de contratación en app** — App · Medio · Bajo · **Alta** ·
  [pago_screen.dart](lib/features/pagos/presentation/pages/pago_screen.dart),
  [contratacion_detail_screen.dart](lib/features/contrataciones/presentation/pages/contratacion_detail_screen.dart) ·
  *AC:* el CTA de pagar contratación no aparece cuando el flag está off; no rompe navegación.
- `[REV-1]` **Campo `destacado_hasta`** — Backend · Medio · Bajo · **Alta** · `models/servicio.py` + migración ·
  *AC:* nuevo campo nullable `destacado_hasta: datetime`; `es_destacado` se deriva de vigencia.
- `[REV-2]` **Endpoint comprar destacado** — Backend · Medio · Medio · **Alta** · `routes_servicios.py`, `payment_service.py` ·
  *AC:* POST crea preference MP; al aprobar webhook, set `es_destacado=true` + `destacado_hasta=+N días`.
- `[REV-3]` **UI comprar destacado** — App · Medio · Medio · **Alta** · [mis_servicios_screen.dart](lib/features/servicios/presentation/pages/mis_servicios_screen.dart) ·
  *AC:* botón "Destacar" en cada servicio propio → checkout → estado destacado visible con vigencia.
- `[SUB-1]` **Vencimiento real de suscripción** — Backend · Medio · Medio · **Alta** · `models/suscripcion.py`, `routes_suscripciones.py` ·
  *AC:* estado `VENCIDA` cuando `fecha_vencimiento < now`; `/me` lo refleja.
- `[SUB-2]` **Gating de features por plan** — Backend + App · Medio · Medio · **Alta** · `dependencies.py`, screens pro ·
  *AC:* features pro (p.ej. nº de postulaciones, badge) bloqueadas sin suscripción activa.
- `[SUB-3]` **Recordatorio de renovación** — Backend · Bajo · Bajo · **Media** · job/cron + Resend ·
  *AC:* email N días antes de vencer; idempotente.
- `[CMP-1]` **Consentimiento explícito en registro** — App · Medio · Bajo · **Media** · [register_screen.dart](lib/features/auth/presentation/pages/register_screen.dart) ·
  *AC:* checkbox obligatorio con links a términos/privacidad; se registra consentimiento (fecha/versión).
- `[CMP-2]` **Eliminación de cuenta/datos** — Backend + App · Medio · Medio · **Media** · `routes_usuarios.py`, perfil ·
  *AC:* el usuario puede solicitar borrado; datos personales se anonimizan/eliminan.
- `[CMP-3]` **Revisión legal privacidad/términos (21.719)** — Legal · Medio · — · **Media** · privacidad/terminos screens ·
  *AC:* textos validados por abogado; versionados. **(Investigación/validación de negocio.)**
- `[KYC-1]` **Elegir proveedor KYC Chile** — Investigación · Medio · — · **Media** · — ·
  *AC:* comparativa de 2-3 proveedores (cobertura, precio, API) y decisión. **(Investigación pendiente.)**
- `[KYC-2]` **Integrar verificación de identidad** — Backend + App · Medio · Alto · **Media** · `models/usuario.py` (`identidad_verificada[_at]`), `routes_usuarios.py`, perfil ·
  *AC:* flujo de verificación; se guarda resultado (no documento crudo); badge "Identidad verificada".
- `[SPLIT-1]` **OAuth cuenta MP del proveedor** — Backend + App · Medio · Alto · **Baja (F2)** · nuevo flujo, `usuario.mp_account_id` ·
  *AC:* el proveedor vincula su MP; se persiste su collector id.
- `[SPLIT-2]` **`marketplace_fee` en preference** — Backend · Medio · Medio · **Baja (F2)** · `payment_service.crear_preferencia` ·
  *AC:* la comisión se separa vía MP; el proveedor recibe su neto directo; la plataforma no custodia.
- `[STK-1]` **Reseñas verificadas + copy anti-fuga** — Producto · Medio · Medio · **Media** · reseñas, contratación/pago ·
  *AC:* reseña solo si hubo interacción registrada; copy "pagar dentro = respaldo".
- `[TECH-1]` **Consolidar a un agregador** — Backend · Bajo · Medio · **Baja (F3)** · `payment_service.py`, `webpay_service.py` ·
  *AC:* Webpay directo deprecado; una sola ruta de pago mantenida + tests.

---

# 7. Checklist de validación y rollout

### Validación por fase
- **Fase 1**
  - [ ] Con flags off: pagar contratación está deshabilitado en API y app (manual + test).
  - [ ] Comprar destacado: pago sandbox MP → webhook → `es_destacado=true` con vigencia (manual + test).
  - [ ] Suscripción: compra sandbox → `/me` activa; al pasar `fecha_vencimiento` → `VENCIDA`.
  - [ ] Registro exige consentimiento; sin él no avanza.
- **Fase 2**
  - [ ] Split MP en sandbox: proveedor recibe su neto, plataforma su fee; **nada queda en custodia**.
  - [ ] KYC sandbox: verificación marca badge; documento crudo no se almacena.
- **Fase 3**
  - [ ] Webhooks con tests de integración (aprobado/rechazado/idempotencia/firma inválida).

### Qué probar manualmente
- Flujo completo cliente→profesional de suscripción y destacado en **sandbox** (MP integration).
- Webhook con **firma inválida** → 401 (`routes_pagos.py:89`).
- Doble webhook (idempotencia) → no duplica (`payment_service._aprobar_pago:148`).

### Qué automatizar con tests
- Backend: gating por feature flag, compra de destacado (mock MP), transición de estado de suscripción,
  validación de webhook (HMAC + idempotencia).
- App: `flutter test` para gating de UI (CTA de pago oculto con flag off), planes/destacados.

### Antes de producción
- [ ] `WEBPAY_ENVIRONMENT`/MP en **producción** solo tras pruebas sandbox completas.
- [ ] Secrets fuera del repo (ya en env); rotación de `MP_WEBHOOK_SECRET`.
- [ ] Privacidad/términos validados legalmente (no liberar sin esto).
- [ ] Confirmación legal de que **no se custodian fondos** en el flujo activo.

### Rollout, fallback y rollback
- **Rollout:** activar por **feature flags**, no por deploy de código nuevo → reversible al instante.
- **Fallback:** si falla destacado/suscripción en prod, flag off deja la app usable (sin esa monetización).
- **Rollback:** como nada se borra (Webpay/comisión quedan tras flags), revertir = volver a poner el flag.
  **No** reactivar el flujo de custodia sin revisión legal previa.

---

## Cuestionamientos al consultor (donde la realidad del proyecto manda)

1. **El consultor asume que partes de cero en pagos. No es así.** El plan real no es "elegir pasarela"
   sino **desarmar la custodia ya construida**. La recomendación sigue siendo válida, pero el trabajo #1
   es de **repliegue**, no de construcción.
2. **MP ya está integrado** — la recomendación "usa agregador" ya está medio cumplida; lo que falta es el
   **split**, no la pasarela. Webpay directo es el que sobra.
3. **Destacados y suscripción ya existen en el modelo de datos** → el "modelo v1" del consultor es
   mayormente **activación**, no desarrollo desde cero (buena noticia: menos esfuerzo del estimado).
4. **KYC con Registro Civil:** confirmado, **no** consumir directo; el código no lo intenta, así que aquí
   no hay deuda — solo falta elegir proveedor externo (investigación pendiente, `[KYC-1]`).
