Plan de trabajo — basado en auditoría funcional (Resumen y checklist)
Fecha: 2026-06-19

Nota: Este plan se actualizará DESPUÉS de cada cambio realizado. Por favor, mantener plan.md sincronizado con commits y cambios importantes (regla: "Actualizar el plan siempre que hagas algo").


PARTE 1 – Limpieza (Fase 1)
- [x] Eliminar carpeta features/perfil/ (3 archivos)
- [x] Eliminar admin_dashboard_screen.dart legacy
- [x] Eliminar resena_screen.dart duplicada (mantener la de contrataciones)
- [x] Eliminar solicitar_servicio_screen.dart duplicada
- [x] Eliminar welcome_page.dart huérfana
- [x] Mover HomeScreen a shared/layout/ y actualizar router + imports
- [x] Eliminar widgets de dashboard cliente no usados (action_card, stat_card, recent_activity)

PARTE 2 – Completar features core (Fase 1)
Auth:
- [x] Crear ResetPasswordScreen (/reset-password)
- [x] Crear ChangePassword
- [x] Corregir re-send verification (usar endpoint correcto)
- [x] Avatar upload en perfil
Servicios:
- [x] Paginación en listados (datasource + provider + screen)
- [x] Upload fotos multipart en crear/editar servicio
- [x] Paginación propuestas (datasource + screen)
- [x] Paginación solicitudes (datasource + screen)
- [x] Centralizar provider pattern (Service -> Provider -> UI) (servicios: done)
Contrataciones:
- [x] Paginación (datasource + provider + screen)
- [x] Cancelar contratación endpoint + UI
- [x] Conectar UI de disputa desde detalle de contratación
Chat:
- [x] Polling cada 10s para nuevos mensajes
- [x] Corregir analyzer warnings (mounted checks, final, rethrow)
- [x] Corregir errores del analyzer (errores blocking) — resuelto
- [x] Paginación al hacer scroll (historico) (implementada básica)
Pagos:
- [ ] Crear modelo Payment y pantalla historial
Suscripciones:
- [x] Crear SuscripcionesProvider
- [x] Implementar cancelar suscripción
- [ ] Modelo de precios configurable

PARTE 3 – Sistema de diseño + AppShell (Fase 1/2)
- [x] Actualizar app/theme.dart con nueva paleta y TextTheme
- [x] Crear shared/layout/app_shell.dart (responsive)
- [x] Crear shared/presentation/widgets/stat_card.dart
- [x] Crear shared/presentation/widgets/status_badge.dart
- [x] Rediseñar shared/presentation/widgets/servicio_card.dart (shared)
- [x] Integrar ServicioCard en landing/listados públicos
- [x] Reemplazar listados públicos para usar ServicioCard en landing, cliente, servicios list


PARTE 4 – Aplicar diseño a pantallas principales (Fase 2)
- [x] Landing pública: hero + busqueda + categorias desde API
- [x] Home Cliente: hero, categorias scrollables, grid responsivo
- [x] Listado Servicios: filtros funcionales, paginación, grid
- [x] Detalle Servicio: galería, info proveedor, reseñas (completo; reseñas: paginación básica implementada; CTA para dejar reseña agregado)
- [ ] Dashboard Proveedor: KPIs, tabla servicios, solicitudes
- [ ] Dashboard Admin: gráficas, tablas paginadas, acciones

PARTE 5 – Features avanzados (Fase 3)
- [x] WebSocket/streaming para chat (cliente + ChatProvider integration)
- [ ] Notificaciones in-app y push
- [x] Sistema completo de reseñas (ver reseñas en perfil público + creación/paginación)
- [x] Resena POST endpoint used by ResenaScreen (crearResena) — UI notifica y cierra con resultado true
- [x] Protección por rol: ResenaScreen accesible sólo a clientes; ocultar/redirigir según rol
- [x] Tests: agregar test de flujo para ResenaScreen (post + pop) — OK (flutter test passed)
- [ ] Disputas: seguimiento y UI avanzada
- [ ] Historial de transacciones y webhooks de pago

Notas: WebSocket implementado en lib/core/ws_client.dart; ChatProvider usa WS with HTTP fallback; polling removed from ChatScreen.

PRIORIDAD - Qué falta por implementar (resumen rápido)
1. Funciones críticas: reset-password, change-password, re-send verification fix, avatar upload.
2. Paginación completa: servicios, contrataciones, propuestas, solicitudes. (Hecho)
3. Upload fotos en servicios (multipart) y centralizar providers (servicios: Hecho; otras features pending).
4. Cancelar contratación + UI de disputa. (Hecho)
5. Chat: WebSocket streaming implementado; paginación historial pending
6. Suscripciones: provider y cancelación. (Hecho)
7. Consolidar/eliminar código huérfano (perfil, dashboards legacy, screens duplicadas). (In progress)

Notas:
- Mantener el repo compilando tras cada fase (flutter analyze clean).  
- Priorizar Fase 1 (Limpieza + Core) antes de diseño general.

---
Últimos cambios (2026-06-19):
- Arreglos de linter y análisis estático: eliminados imports no usados, corregido DropdownButtonFormField, ajustado uso de BuildContext en puntos críticos y arreglada implementación web storage.
- Tests: se añadió y pasó test de flujo de reseñas.
- Commits realizados con mensajes descriptivos y trailer Co-authored-by.

Guardado por: Equipo / Auditoría interna

- Added BACKEND_ENDPOINTS.md: listado de endpoints necesarios para el backend (ruta: BACKEND_ENDPOINTS.md)
