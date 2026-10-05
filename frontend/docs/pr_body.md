# PR: Rediseño Visual 2.0 y Adaptabilidad Responsiva (Desktop/Mobile)

## 🎯 Objetivo
Esta PR trae la segunda gran iteración de diseño para TrabajoYa (`feature/design2.0`). El objetivo principal ha sido elevar significativamente la calidad estética de la aplicación (incluyendo colores vibrantes, animaciones y mejores jerarquías) y adaptar todos los flujos de navegación (Cliente, Proveedor y Admin) para que funcionen como una aplicación de escritorio fluida, sin perder la usabilidad en dispositivos móviles. Además, se limpió y reestructuró por completo la documentación técnica.

## 🛠️ Cambios Principales

### 1. Landings Personalizadas y Rediseño Visual
- **Landing Pública:** Transformación completa del diseño, con Hero animado, bloques de propuesta de valor y un flujo visual mucho más profesional y llamativo.
- **Landing de Cliente (`/cliente/buscar`):** Diseño de un carrusel dinámico en la parte superior, secciones de categorías y "Proveedores destacados" con bordes y fondos coloridos (Verde Agua), y diseño de reseñas optimizado.
- **Landing de Proveedor (`/proveedor/oportunidades`):** Se integró un mapa estilo "Google Maps" con estadísticas (ganancias y vistas de perfil) en el panel principal, se rediseñó la tarjeta de servicio con la etiqueta animada ✨ "OPORTUNIDAD ÚNICA" / "OFERTA IRRESISTIBLE", y se mejoró la integración gráfica de la sección "Tips".

### 2. Navegación Responsiva (Desktop / Mobile)
- **Modo Escritorio:** Eliminación del `BottomNavigationBar` (doble menú) para Cliente y Proveedor, sustituido por un Header moderno e integrado. 
- **Modo Móvil:** Mantenimiento del menú inferior clásico de Flutter para uso fácil con una mano.
- Limitación inteligente del ancho de las vistas (`ConstrainedBox` en 800px-1000px) para formularios, perfiles, chats y listados (mis contrataciones, propuestas, etc.), previniendo que la UI se estire de forma antiestética en pantallas anchas.

### 3. Rediseño del Panel de Administración (`AdminShell`)
- **Navegación Admin:** Integración de un Sidebar oscuro persistente a la izquierda para escritorio ($\ge$ 900px) y un Menú Hamburguesa (Drawer) en modo móvil, reemplazando la navegación antigua de pantallas sueltas.
- **Integración profunda del Menú:** El sidebar del Admin ahora expone directamente accesos a los distintos estados (Clientes, Proveedores, Transacciones, Realizados, Cancelados, Cobrados, Fallidos, Feedback).
- **Vistas optimizadas:** Eliminación de los `AppBar` redundantes dentro de las vistas administrativas (`usuarios`, `servicios`, `pagos`, `disputas`) y contención del contenido a `1200px` de ancho máximo.

### 4. Limpieza y Reestructuración de Documentación
- Reorganización total de los archivos Markdown del proyecto.
- Adición de prefijos numéricos (`1_`, `2_`, `3_`, `4_`) para un orden lógico y lectura secuencial del equipo.
- Limpieza de documentos obsoletos.
- Actualización de `A_TAREAS.md` con el porcentaje real de avance, los flujos cubiertos, las integraciones del API pendientes y los bugs del backend identificados.

## 📋 Tareas de Verificación
- [x] Las 3 landings principales (Pública, Cliente, Proveedor) muestran el nuevo diseño sin errores de overflow.
- [x] Al cambiar el tamaño de la ventana (`chrome` desktop), la navegación cambia dinámicamente entre BottomNav y Header.
- [x] El sidebar del Administrador navega correctamente y filtra por estado.
- [x] Toda la documentación obsoleta fue limpiada exitosamente.

## 📝 Notas para el Revisor
*Esta PR abarca la transformación visual y responsiva más grande de la etapa actual. Es muy importante revisar interactuando con la ventana web en distintos tamaños para ver cómo reaccionan las grillas, los anchos de los listados y los sistemas de navegación lateral y superior.*
