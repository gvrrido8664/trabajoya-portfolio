# Roadmap UI — Frente Proveedor

> **Fecha:** 2026-07-08 · Derivado de [ui-audit-master.md](ui-audit-master.md). Regido por [design-system-rules.md](design-system-rules.md).
> **Objetivo:** abrir el frente Proveedor sin heredar la deuda del lado Cliente, aprovechando lo que ya existe (`pro_ui.dart`, `ProveedorShell`, pantallas Pro parciales).

---

## 1. Estado de partida (lo que ya hay)

El frente Proveedor **no parte de cero** — y eso es riesgo además de ventaja, porque lo existente tiene los mismos vicios detectados en Cliente:

| Pieza | Estado | Acción |
|---|---|---|
| `pro_ui.dart` (ProColors, ProScaffold, ProCard, ProHeader…) | Kit funcional, dirección correcta (workspace oscuro estilo Linear: bg #0B1016, jerarquía surface/surfaceHi/elevated, bordes sutiles) | Conservar como semilla; sanear (§2) |
| `ProveedorShell` + rutas `/proveedor/*` en router | 6 branches operativos | Conservar; alinear sidebar (§3.4) |
| Pantallas: oportunidades, proveedor_profile, mis_propuestas, mis_servicios, crear_editar_servicio | Existen pero con 39+17+7 hex fuera de tokens, estilos inline | Refactor al kit saneado antes de crecer |
| `ProColors.status()` | Mapa de estados **distinto** al de `AppTheme.statusColor()` (ej.: `completado` verde vs azul) | Reemplazar por el enum Status unificado (crítico C6 del audit) |

## 2. Prerrequisitos (bloqueantes — Fases 1-2 del plan maestro)

No abrir pantallas Pro nuevas hasta que:

1. **Enum Status unificado** exista y `ProColors.status()` sea un mapeo de él (mismo estado = mismo significado en ambos lados del marketplace; el proveedor y el cliente miran la misma contratación).
2. **`ProColors` entre a la arquitectura de tokens** — hoy son 39 hex sueltos en un widget file. Mover a `lib/shared/theme/` (p.ej. `pro_palette.dart`) junto a AppColors, documentados en DESIGN.md. `ProColors.accent` #4FA9EC queda documentado como *derivado por contraste* del azul de marca (regla ya escrita en DESIGN.md §2 — hacerla realidad).
3. **Glow del `ProHeader` eliminado** — DESIGN.md §2.b es explícito: "sin glows ni gradientes decorativos" en el tier Pro. El comentario del propio código ([pro_ui.dart:113](../lib/features/proveedor/presentation/widgets/pro_ui.dart#L113)) admite el glow.
4. **Loader/EmptyState/Badge consolidados** (críticos C4-C6) — para que el kit Pro los consuma, no los duplique.
5. **Decisión D1 (dark mode)** tomada — aunque el tier Pro es oscuro por identidad e independiente de `ThemeMode` (regla R8.2), sus diálogos, snackbars y pickers heredan del tema global y hoy quedarían blancos/rotos.

## 3. Diseño del frente Proveedor

### 3.1 Identidad del tier (ya decidida en DESIGN.md — ejecutarla fielmente)
SaaS operativo oscuro, plano, denso. El proveedor está *trabajando*: gestiona propuestas, agenda, cobros. Densidad de información es virtud aquí (a diferencia del lado Cliente, que respira). Sin decoración: la única saturación de color es el azul activo y los estados.

### 3.2 Kit Pro a completar ANTES de las pantallas
Paridad de API 1:1 con el lado Cliente (misma forma de props, distinta piel):

| Componente | Base | Nota |
|---|---|---|
| `ProButton` (filled/outline/cta) | FilledButton tematizado | 52px, `Radii.md`; CTA verde solo para cobros |
| `ProInput` | `inputDecorationTheme` variante oscura | fill `surfaceHi`, borde `border`, focus accent — **una** definición |
| `ProStatusBadge` | enum Status + píldora tintada | mismo componente lógico que el del Cliente |
| `ProSkeleton` | módulo de loading unificado | colores de `ProColors`, reduced-motion |
| `ProEmptyState` | EmptyStateWidget saneado | los empty states Pro venden el siguiente paso del negocio ("Publica tu primer servicio → recibe oportunidades") |
| `ProTable`/`ProListRow` | lista densa con colapso <600 | el proveedor gestiona volumen: filas densas, no cards infladas |
| `ProMetricTile` | nuevo | KPIs (ingresos, propuestas activas, rating) — dato real siempre, nunca placeholder |

### 3.3 Pantallas del frente (orden de valor)
1. **Dashboard/Home Pro** — resumen operativo: oportunidades nuevas, propuestas pendientes, próximos trabajos, ingresos del mes. Es la pantalla-hábito.
2. **Oportunidades** (refactor de la existente) — lista densa filtrable; distancia/comuna visible; CTA "Proponer".
3. **Mis propuestas** — pipeline por estado (usa el enum Status; el proveedor vive en esta vista).
4. **Mis servicios + crear/editar** (refactor) — el formulario reusa el patrón validado de crear_solicitud pero con el input Pro único.
5. **Agenda/trabajos activos** — continuidad de contratación → ejecución → cobro.
6. **Perfil Pro + verificación** — la verificación de identidad es el activo de confianza del marketplace: estado del documento siempre visible, con siguiente paso claro.
7. **Cobros/pagos** — misma advertencia que en Cliente: es la pantalla que más sistema necesita y la que hoy (lado cliente) menos tiene. Presupuestar diseño explícito.

### 3.4 Navegación
- Móvil: `NavigationBar` M3 oscura (mismo patrón que ClienteShell, con badge de no-leídos).
- Desktop: **un** componente de sidebar compartido con Cliente/Admin (regla DESIGN.md "mismo sidebar navy, mismo color activo"), parametrizado por tier — hoy hay tres sidebars artesanales; el frente Pro es la oportunidad de extraer el componente único en `lib/shared/layout/`.

## 4. Errores del lado Cliente que NO se repiten aquí

1. Colores/tamaños inline → todo vía tokens y textTheme (R1.1, R2.2).
2. Breakpoints ad-hoc → solo `Breakpoints` (R5.1).
3. Pantallas monolito de 40-48 KB → separar secciones en widgets privados por archivo de feature.
4. Re-implementar inputs/badges/loaders por pantalla → kit primero (R4.1).
5. Dark "a mano" con ternarios → el tier es oscuro por diseño, resuelto una vez en el kit (R8.1-R8.2).
6. Datos fake/placeholder (★★★★★, contadores inventados) → todo KPI Pro con dato real o estado vacío honesto.
7. Semantics como excepción → cada componente del kit Pro nace con Semantics correcto (R7.2).
8. `DataTable` sin variante móvil → `ProTable` nace con colapso (R4.9).

## 5. Secuencia y criterios de salida

| Fase | Contenido | Estado Actual | Detalle del Handoff |
|---|---|---|---|
| **P0** | Prerrequisitos §2 | **COMPLETADO** | Cero hex en pro_ui; enum Status único; glow fuera. |
| **P1** | Kit Pro completo (§3.2) | **COMPLETADO** | Todos los componentes con default/hover/focus/disabled/loading/error; checklist R9.1 verde. |
| **P2** | Dashboard + Oportunidades + Propuestas | **EN PROGRESO / PARCIAL** | **Completado:** Refactor de Oportunidades (`oportunidades_screen.dart`) y Propuestas (`mis_propuestas_screen.dart`, `enviar_propuesta_screen.dart`). <br>**Pendiente:** Crear pantalla dedicada de **Dashboard/Home Pro** (resumen de ingresos, rating, etc.). |
| **P3** | Servicios + Agenda + Perfil/verificación | **ADELANTADO / COMPLETO** | **Completado:** Refactor de Servicios (`mis_servicios_screen.dart`), Perfil/verificación (`proveedor_profile_screen.dart`) y Detalle de Contrato/Agenda (`contratacion_detail_screen.dart`). |
| **P4** | Cobros + polish (motion, a11y, contraste) | **EN PROGRESO** | **Contraste AA: auditado y corregido** (ver §7). **Cobros: bloqueado por decisión de producto** (ver §8) — la arquitectura real es MercadoPago Connect, no wallet/retiros. |

**Definición de "hecho" por pantalla:** estados loading/empty/error implementados · <600 y >1024 verificados · cero literales de estilo · Semantics en interactivos · contraste AA verificado sobre las superficies oscuras (los grises `textMuted` #5E6E7D sobre `surface` #121A22 están al límite — verificar antes de usarlos en texto informativo).

---

## 6. Estado Actual de Avance (Handoff)

En la iteración reciente, se ejecutó el barrido completo de diseño, remoción de colores hexadecimales duros y adaptación al **Kit Pro** en las pantallas del Proveedor. 

### 🌟 Avances P3 Adelantados en P2:
Para garantizar la coherencia visual del marketplace y limpiar la deuda técnica de forma homogénea, se decidió **adelantar el refactor de las pantallas de P3** en conjunto con las de P2:
- **`proveedor_profile_screen.dart`** (Perfil Pro / Verificación): Migrada a `ProScaffold` y `ProCard` con balanceo correcto de llaves, remoción de todos los `AppColors` de light-mode a favor de `ProColors`, y adaptación del selector de identidad.
- **`mis_servicios_screen.dart`** (Servicios): Estandarizada al Kit Pro con remoción de hexadecimales y compilación 100% limpia.
- **`contratacion_detail_screen.dart`** (Detalle de Contrato / Agenda): Adaptada con `RolePalette.of(context)` para ser visualmente oscura en el rol de proveedor, consumiendo estados unificados.

### 📌 Focos Pendientes Clave (Siguiente Sprint):
1. **Creación del Dashboard/Home Pro**: Diseñar y programar la pantalla de resumen que funcionará como entrada a `/proveedor`. Debe mostrar KPIs de ingresos, rating, propuestas pendientes y próximos trabajos.
2. **Agenda/Listado de Trabajos Activos**: Verificar e integrar si el listado general de agenda requiere ajustes adicionales respecto al nuevo Kit Pro.
3. **Cobros/Pagos**: Diseñar y estructurar los flujos de cobro en el tier oscuro del proveedor.
4. **Polish de Contraste, a11y y Motion**: Revisar el contraste AA sobre fondos grises oscuros y añadir transiciones interactivas.

*Nota: `admin_pagos_screen.dart` se mantiene bloqueado.*

---

## 7. Auditoría de contraste WCAG AA (P4 — hecha 2026-07-08)

Medición real (fórmula WCAG) de cada texto de `ProColors` sobre las 4 superficies oscuras (bg #0B1016 / surface #121A22 / surfaceHi #17212B / elevated #1B2733):

| Texto | Ratio mín | Veredicto |
|---|---|---|
| textPrimary #E7EDF3 | 12.86 | ✔ AA holgado |
| textSecondary #93A1B0 | 5.75 | ✔ AA |
| accent #4FA9EC | 5.94 | ✔ AA |
| amber / success / danger | 8.76 / 7.89 / 5.48 | ✔ AA |
| **textMuted #5E6E7D (antes)** | **2.89** | **✘ fallaba AA en las 4** |

**Correcciones aplicadas (a nivel de token, propagan a todas las pantallas):**
1. `ProColors.textMuted` #5E6E7D → **#828F9C** (min 4.59:1, sigue por debajo de textSecondary para conservar jerarquía). `RolePalette.textMuted` lo hereda.
2. Nuevo token **`ProColors.onAccent` #06283B** (texto oscuro sobre accent, 7.5:1). Se corrigieron **7 botones primarios** con `foregroundColor: Colors.white` sobre `ProColors.accent` (2.56:1, fallaba) en `proveedor_profile` (4) y `mis_servicios` (3).
3. `proveedor_profile`: grises light-theme crudos usados como texto sobre fondo oscuro → tokens Pro: `#334155` (1.5:1, casi invisible) → `textPrimary`; `#64748B` ×3 (3.2–4.0) → `textMuted`; icono `#7C8AA0` → `textSecondary`.

**Pendiente de decisión (no corregido):** botones destructivos con `foregroundColor: Colors.white` sobre `ProColors.danger` #F87171 (~2.3:1) en `proveedor_profile` y `mis_servicios` — blanco-sobre-rojo es convención de destructivo; decidir si se oscurece el rojo o el texto.

**Pendiente (no crítico):** `ContratacionesProveedorScreen` usa `DataTable` con scroll horizontal en móvil (R4.9 pide colapso a cards <600). Funciona, pero es polish. Los botones primarios crudos (`FilledButton` con bg accent) deberían migrar a `ProButton` del kit (que ya resuelve `onAccent` solo).

## 8. Cobros/Pagos — CONSTRUIDO (config de cuenta bancaria vía Fintoc)

> **Corrección importante:** una iteración previa asumió que el cobro era por **MercadoPago Connect** (el `pagos_remote_datasource.dart` del frontend aún expone `getMpConnectStatus/startMpConnect/disconnectMp`). **Eso es falso: MP Connect fue ELIMINADO del backend** — el modelo `Usuario` lo dice textual: `# --- Cuenta conectada del agregador (MP Connect) eliminada ---`. Esos endpoints ya no existen (darían 404).

**Arquitectura real (verificada en `trabajoya-api`):**
- Cliente paga (escrow, `Pago.status=APROBADO`). Al **completarse** el trabajo (`contratacion.status=COMPLETADO`), `routes_contrataciones._ejecutar_payout` dispara en background `payout_service.dispersar(...)` vía **Fintoc**, que transfiere a la **cuenta bancaria** del proveedor y setea `Pago.payout_status` (SENT/COMPLETADO/FAILED — casing inconsistente entre paths del back).
- Para recibir, el proveedor DEBE tener su cuenta configurada. `routes_pagos.py` bloquea el pago si `not proveedor.bank_configured`.
- Endpoints reales (`routes_banco.py`, requieren rol proveedor):
  - `GET /proveedores/me/banco` → `{bank_configured, bank_name, account_type, account_last4, bank_rut}`
  - `PUT /proveedores/me/banco` `{rut, bank_name, account_number, account_type}` → setea y marca `bank_configured=true`.
- `bank_name` debe ser uno de los 8 bancos soportados por Fintoc (mapa en `payout_service`). `account_type` ∈ `corriente|vista|ahorro`.

**Construido:** `banco_remote_datasource.dart` (`BancoService`: `getBanco`/`updateBanco` + listas de bancos y tipos) + `proveedor_cobros_screen.dart` reescrito como **config de cuenta bancaria** (form: RUT, banco, tipo, número → PUT; vista resumen con ····last4 + editar) **+ resumen** "Pagado" (`COMPLETADO`) vs "En curso" (`ACEPTADO`) de contrataciones reales. Ruteado en `/proveedor/cobros` (mantiene el shell); botón "Cobros" del dashboard navega ahí. No hay retiro manual (el payout es automático al completar).

**Corrección de drift front↔back (hecha 2026-07-08):**
- Borrado el dead code de MP Connect: `getMpConnectStatus/startMpConnect/disconnectMp` en `pagos_remote_datasource.dart` y la sección MP Connect (`_mpConnected`, `cargarMpConnectStatus`, `iniciarMpConnect`, `desconectarMp`) en `pagos_provider.dart`. Se conservan `crearPagoMP` y `getEstadoPago` (pegan a endpoints reales `/pagos/crear` y `/pagos/{id}/estado`). Cero consumidores rotos.
- Corregidos los estados muertos del dashboard: `LIBERADO` (no existe en `EstadoContratacion`) eliminado del cálculo de ingresos; `ACEPTADA`/`EN_PROGRESO` (tampoco existen) → `ACEPTADO` en trabajos activos y próximos. `analyze` limpio, 34 tests ok.

⚠️ **Verificar en runtime:** que `GET/PUT /proveedores/me/banco` respondan con el shape esperado y que el guardado marque `bank_configured`. El resumen de cobros usa `COMPLETADO`/`ACEPTADO` (enum real `EstadoContratacion`).
