import 'dart:math';

String _now() => DateTime.now().toIso8601String();
String _ago(int days) =>
    DateTime.now().subtract(Duration(days: days)).toIso8601String();

const _token = 'mock-token-trabajoya-2024';

final _random = Random();

int _nextId(String prefix) => _random.nextInt(99999);

// --- Usuarios de mock ---
final _cliente = {
  'id': 'mock-cliente-1',
  'email': 'maria@correo.com',
  'nombre': 'Maria',
  'apellido': 'Gonzalez',
  'rol': 'cliente',
  'telefono': '+56912345678',
  'avatar_url': null,
  'bio': 'Busco servicios de calidad para mi hogar',
  'habilidades': null,
  'is_active': true,
  'is_verified': true,
  'email_verificado': true,
  'avg_rating': 4.5,
  'codigo_referido': 'MARIA01',
  'referidos_count': 2,
  'created_at': _ago(30),
  'updated_at': _ago(30),
};

final _proveedor = {
  'id': 'mock-proveedor-1',
  'email': 'carlos@correo.com',
  'nombre': 'Carlos',
  'apellido': 'Perez',
  'rol': 'proveedor',
  'telefono': '+56987654321',
  'avatar_url': null,
  'bio': 'Plomero profesional con 10 anos de experiencia',
  'habilidades': 'plomeria, calentador de agua, alcantarillado',
  'is_active': true,
  'is_verified': true,
  'email_verificado': true,
  'avg_rating': 4.8,
  'codigo_referido': 'CARLOS01',
  'referidos_count': 5,
  'created_at': _ago(60),
  'updated_at': _ago(60),
};

final _admin = {
  'id': 'mock-admin-1',
  'email': 'admin@trabajoya.cl',
  'nombre': 'Admin',
  'apellido': 'TrabajoYa',
  'rol': 'admin',
  'telefono': null,
  'avatar_url': null,
  'bio': null,
  'habilidades': null,
  'is_active': true,
  'is_verified': true,
  'email_verificado': true,
  'avg_rating': 0.0,
  'codigo_referido': null,
  'referidos_count': 0,
  'created_at': _ago(90),
  'updated_at': _ago(90),
};

final _otroProveedor = {
  'id': 'mock-proveedor-2',
  'email': 'ana@correo.com',
  'nombre': 'Ana',
  'apellido': 'Martinez',
  'rol': 'proveedor',
  'telefono': '+56911223344',
  'avatar_url': null,
  'bio': 'Electricista certificada SEC',
  'habilidades': 'electricidad, tableros, iluminacion',
  'is_active': true,
  'is_verified': true,
  'email_verificado': true,
  'avg_rating': 4.2,
  'codigo_referido': 'ANA001',
  'referidos_count': 1,
  'created_at': _ago(45),
  'updated_at': _ago(45),
};

Map<String, dynamic>? _usuarioActual;

void _setCurrentUser(Map<String, dynamic> u) {
  _usuarioActual = u;
}

String get _currentUserId =>
    _usuarioActual?['id'] as String? ?? _cliente['id'] as String;

// --- Servicios de mock ---
final List<Map<String, dynamic>> _servicios = [
  {
    'id': 'mock-serv-1',
    'proveedor_id': _proveedor['id'],
    'categoria_id': 'plomeria',
    'titulo': 'Reparacion de fugas de agua',
    'descripcion':
        'Reparacion de fugas en tuberias, llaves y conexiones. Servicio rapido y garantizado.',
    'status': 'ACTIVO',
    'precio_min': 15000,
    'precio_max': 50000,
    'radio_cobertura_km': 15,
    'direccion_texto': 'Santiago Centro',
    'fotos': null,
    'distancia': 2.3,
    'proveedor_nombre': 'Carlos Perez',
    'proveedor_rating': 4.8,
    'categoria_nombre': 'Plomeria',
    'created_at': _ago(25),
  },
  {
    'id': 'mock-serv-2',
    'proveedor_id': _proveedor['id'],
    'categoria_id': 'plomeria',
    'titulo': 'Instalacion de calentador de agua',
    'descripcion':
        'Instalacion y mantencion de calentadores de agua de todas las marcas. Presupuesto sin costo.',
    'status': 'ACTIVO',
    'precio_min': 30000,
    'precio_max': 80000,
    'radio_cobertura_km': 10,
    'direccion_texto': 'Providencia',
    'fotos': null,
    'distancia': 3.1,
    'proveedor_nombre': 'Carlos Perez',
    'proveedor_rating': 4.8,
    'categoria_nombre': 'Plomeria',
    'created_at': _ago(20),
  },
  {
    'id': 'mock-serv-3',
    'proveedor_id': _proveedor['id'],
    'categoria_id': 'plomeria',
    'titulo': 'Destape de alcantarillado',
    'descripcion':
        'Destape de alcantarillado con maquinaria especializada. Atencion 24/7.',
    'status': 'PAUSADO',
    'precio_min': 25000,
    'precio_max': 60000,
    'radio_cobertura_km': 20,
    'direccion_texto': 'Las Condes',
    'fotos': null,
    'distancia': 5.0,
    'proveedor_nombre': 'Carlos Perez',
    'proveedor_rating': 4.8,
    'categoria_nombre': 'Plomeria',
    'created_at': _ago(15),
  },
  {
    'id': 'mock-serv-4',
    'proveedor_id': _otroProveedor['id'],
    'categoria_id': 'electricidad',
    'titulo': 'Instalacion electrica domiciliaria',
    'descripcion':
        'Instalaciones electricas nuevas, recableado y normalizacion. Certificacion SEC.',
    'status': 'ACTIVO',
    'precio_min': 20000,
    'precio_max': 150000,
    'radio_cobertura_km': 12,
    'direccion_texto': 'Nunoa',
    'fotos': null,
    'distancia': 4.2,
    'proveedor_nombre': 'Ana Martinez',
    'proveedor_rating': 4.2,
    'categoria_nombre': 'Electricidad',
    'created_at': _ago(18),
  },
  {
    'id': 'mock-serv-5',
    'proveedor_id': _otroProveedor['id'],
    'categoria_id': 'electricidad',
    'titulo': 'Reparacion de tableros electricos',
    'descripcion':
        'Diagnostico y reparacion de tableros electricos. Emergencias 24/7.',
    'status': 'ACTIVO',
    'precio_min': 18000,
    'precio_max': 70000,
    'radio_cobertura_km': 10,
    'direccion_texto': 'Macul',
    'fotos': null,
    'distancia': 6.1,
    'proveedor_nombre': 'Ana Martinez',
    'proveedor_rating': 4.2,
    'categoria_nombre': 'Electricidad',
    'created_at': _ago(12),
  },
  {
    'id': 'mock-serv-6',
    'proveedor_id': _otroProveedor['id'],
    'categoria_id': 'electricidad',
    'titulo': 'Instalacion de iluminacion LED',
    'descripcion':
        'Cambio e instalacion de bombillas, paneles y tiras LED. Ahorro energetico garantizado.',
    'status': 'ACTIVO',
    'precio_min': 10000,
    'precio_max': 40000,
    'radio_cobertura_km': 8,
    'direccion_texto': 'La Florida',
    'fotos': null,
    'distancia': 8.3,
    'proveedor_nombre': 'Ana Martinez',
    'proveedor_rating': 4.2,
    'categoria_nombre': 'Electricidad',
    'created_at': _ago(8),
  },
  {
    'id': 'mock-serv-7',
    'proveedor_id': _proveedor['id'],
    'categoria_id': 'plomeria',
    'titulo': 'Cambio de llaves y griferia',
    'descripcion':
        'Cambio e instalacion de llaves de agua, griferia de bano y cocina.',
    'status': 'ACTIVO',
    'precio_min': 12000,
    'precio_max': 35000,
    'radio_cobertura_km': 15,
    'direccion_texto': 'Santiago Centro',
    'fotos': null,
    'distancia': 2.3,
    'proveedor_nombre': 'Carlos Perez',
    'proveedor_rating': 4.8,
    'categoria_nombre': 'Plomeria',
    'created_at': _ago(10),
  },
  {
    'id': 'mock-serv-8',
    'proveedor_id': _otroProveedor['id'],
    'categoria_id': 'electricidad',
    'titulo': 'Mantencion electrica preventiva',
    'descripcion':
        'Revision periodica de instalaciones electricas para prevenir fallas.',
    'status': 'ACTIVO',
    'precio_min': 15000,
    'precio_max': 45000,
    'radio_cobertura_km': 10,
    'direccion_texto': 'Providencia',
    'fotos': null,
    'distancia': 3.5,
    'proveedor_nombre': 'Ana Martinez',
    'proveedor_rating': 4.2,
    'categoria_nombre': 'Electricidad',
    'created_at': _ago(5),
  },
];

// --- Contrataciones de mock ---
final List<Map<String, dynamic>> _contrataciones = [
  {
    'id': 'mock-contr-1',
    'cliente_id': _cliente['id'],
    'proveedor_id': _proveedor['id'],
    'servicio_id': 'mock-serv-1',
    'status': 'COMPLETADO',
    'monto_acordado': 25000,
    'mensaje_solicitud': 'Hola, tengo una fuga en el bano principal',
    'fecha_programada': _ago(3),
    'created_at': _ago(5),
    'updated_at': _ago(3),
    'servicio_titulo': 'Reparacion de fugas de agua',
    'cliente_nombre': 'Maria Gonzalez',
    'proveedor_nombre': 'Carlos Perez',
  },
  {
    'id': 'mock-contr-2',
    'cliente_id': _cliente['id'],
    'proveedor_id': _otroProveedor['id'],
    'servicio_id': 'mock-serv-4',
    'status': 'ACEPTADO',
    'monto_acordado': 45000,
    'mensaje_solicitud':
        'Necesito instalar enchufes nuevos en el living y dormitorio',
    'fecha_programada': DateTime.now()
        .add(const Duration(days: 2))
        .toIso8601String(),
    'created_at': _ago(1),
    'updated_at': _ago(1),
    'servicio_titulo': 'Instalacion electrica domiciliaria',
    'cliente_nombre': 'Maria Gonzalez',
    'proveedor_nombre': 'Ana Martinez',
  },
  {
    'id': 'mock-contr-3',
    'cliente_id': _cliente['id'],
    'proveedor_id': _proveedor['id'],
    'servicio_id': 'mock-serv-7',
    'status': 'PENDIENTE',
    'monto_acordado': null,
    'mensaje_solicitud': 'Quiero cambiar la griferia de la cocina',
    'fecha_programada': DateTime.now()
        .add(const Duration(days: 5))
        .toIso8601String(),
    'created_at': _now(),
    'updated_at': _now(),
    'servicio_titulo': 'Cambio de llaves y griferia',
    'cliente_nombre': 'Maria Gonzalez',
    'proveedor_nombre': 'Carlos Perez',
  },
];

// --- Resenas de mock ---
final List<Map<String, dynamic>> _resenas = [
  {
    'id': 'mock-res-1',
    'contratacion_id': 'mock-contr-1',
    'calificador_id': _cliente['id'],
    'calificado_id': _proveedor['id'],
    'puntuacion': 5,
    'comentario':
        'Excelente trabajo, muy profesional y puntual. Lo recomiendo.',
    'created_at': _ago(3),
  },
];

// --- Mensajes de mock ---
Map<String, List<Map<String, dynamic>>> _mensajesPorContratacion = {
  'mock-contr-1': [
    {
      'id': 'mock-msg-1',
      'contratacion_id': 'mock-contr-1',
      'emisor_id': _cliente['id'],
      'contenido': 'Hola, necesito ayuda con una fuga urgente',
      'leido': true,
      'created_at': _ago(5),
    },
    {
      'id': 'mock-msg-2',
      'contratacion_id': 'mock-contr-1',
      'emisor_id': _proveedor['id'],
      'contenido': 'Claro, puedo ir manana en la tarde. Envie fotos si puede.',
      'leido': true,
      'created_at': _ago(5),
    },
    {
      'id': 'mock-msg-3',
      'contratacion_id': 'mock-contr-1',
      'emisor_id': _cliente['id'],
      'contenido': 'Si, ahi le envio. Gracias!',
      'leido': true,
      'created_at': _ago(4),
    },
  ],
  'mock-contr-2': [
    {
      'id': 'mock-msg-4',
      'contratacion_id': 'mock-contr-2',
      'emisor_id': _cliente['id'],
      'contenido': 'Hola Ana, vi tu perfil y necesito cotizar una instalacion',
      'leido': true,
      'created_at': _ago(1),
    },
    {
      'id': 'mock-msg-5',
      'contratacion_id': 'mock-contr-2',
      'emisor_id': _otroProveedor['id'],
      'contenido':
          'Hola Maria! Claro, dime cuantos enchufes necesitas y te hago el presupuesto',
      'leido': false,
      'created_at': _ago(1),
    },
  ],
  'mock-contr-3': [],
};

// --- Categorías de mock ---
final List<Map<String, dynamic>> _categorias = [
  {
    'id': 'raiz-rep',
    'nombre': 'Reparaciones del Hogar',
    'slug': 'reparaciones-hogar',
    'icono': '🔧',
    'descripcion': 'Reparación y mantenimiento del hogar',
    'parent_id': null,
  },
  {
    'id': 'raiz-tech',
    'nombre': 'Tecnología',
    'slug': 'tecnologia',
    'icono': '💻',
    'descripcion': 'Servicios tecnológicos',
    'parent_id': null,
  },
  {
    'id': 'raiz-salud',
    'nombre': 'Salud y Bienestar',
    'slug': 'salud-bienestar',
    'icono': '🏥',
    'descripcion': 'Cuidado de la salud',
    'parent_id': null,
  },
  {
    'id': 'plomeria',
    'nombre': 'Plomería',
    'slug': 'plomeria',
    'icono': '🔧',
    'descripcion': 'Reparaciones de tuberías y grifería',
    'parent_id': 'raiz-rep',
  },
  {
    'id': 'electricidad',
    'nombre': 'Electricidad',
    'slug': 'electricidad',
    'icono': '⚡',
    'descripcion': 'Instalaciones y reparaciones eléctricas',
    'parent_id': 'raiz-rep',
  },
  {
    'id': 'pintura',
    'nombre': 'Pintura',
    'slug': 'pintura',
    'icono': '🎨',
    'descripcion': 'Pintura interior y exterior',
    'parent_id': 'raiz-rep',
  },
  {
    'id': 'limpieza',
    'nombre': 'Limpieza',
    'slug': 'limpieza',
    'icono': '🧹',
    'descripcion': 'Limpieza del hogar y oficina',
    'parent_id': 'raiz-rep',
  },
  {
    'id': 'carpinteria',
    'nombre': 'Carpintería',
    'slug': 'carpinteria',
    'icono': '🪚',
    'descripcion': 'Trabajos en madera',
    'parent_id': 'raiz-rep',
  },
  {
    'id': 'jardineria',
    'nombre': 'Jardinería',
    'slug': 'jardineria',
    'icono': '🌿',
    'descripcion': 'Diseño y mantenimiento de jardines',
    'parent_id': 'raiz-rep',
  },
  {
    'id': 'cerrajeria',
    'nombre': 'Cerrajería',
    'slug': 'cerrajeria',
    'icono': '🔐',
    'descripcion': 'Apertura y reparación de cerraduras',
    'parent_id': 'raiz-rep',
  },
];

// --- Solicitudes de mock ---
final List<Map<String, dynamic>> _solicitudes = [
  {
    'id': 'mock-sol-1',
    'cliente_id': _cliente['id'],
    'categoria_id': 'plomeria',
    'titulo': 'Tengo una fuga de agua en el baño',
    'descripcion':
        'Necesito un plomero urgente. Hay una fuga en la tubería del baño principal que está goteando.',
    'presupuesto_max': 50000,
    'ubicacion_texto': 'Santiago Centro',
    'status': 'ABIERTA',
    'cliente_nombre': 'Maria Gonzalez',
    'propuestas_count': 2,
    'created_at': _ago(2),
  },
  {
    'id': 'mock-sol-2',
    'cliente_id': _cliente['id'],
    'categoria_id': 'electricidad',
    'titulo': 'Instalar 5 enchufes nuevos',
    'descripcion':
        'Quiero instalar enchufes nuevos en el living y dormitorios de mi departamento.',
    'presupuesto_max': 80000,
    'ubicacion_texto': 'Providencia',
    'status': 'ABIERTA',
    'cliente_nombre': 'Maria Gonzalez',
    'propuestas_count': 1,
    'created_at': _ago(1),
  },
  {
    'id': 'mock-sol-3',
    'cliente_id': _cliente['id'],
    'categoria_id': 'pintura',
    'titulo': 'Pintar pieza de 12m2',
    'descripcion':
        'Necesito pintar una pieza pequeña. Color a definir con el proveedor.',
    'presupuesto_max': 120000,
    'ubicacion_texto': 'Las Condes',
    'status': 'CERRADA',
    'cliente_nombre': 'Maria Gonzalez',
    'propuestas_count': 3,
    'created_at': _ago(5),
  },
];

// --- Propuestas de mock ---
final List<Map<String, dynamic>> _propuestas = [
  {
    'id': 'mock-prop-1',
    'solicitud_id': 'mock-sol-1',
    'proveedor_id': _proveedor['id'],
    'descripcion':
        'Tengo 10 años de experiencia en plomería. Puedo ir mañana en la mañana y resolver la fuga rápidamente.',
    'precio': 35000,
    'tiempo_estimado': '2 horas',
    'status': 'PENDIENTE',
    'proveedor_nombre': 'Carlos Perez',
    'solicitud_titulo': 'Tengo una fuga de agua en el baño',
    'created_at': _ago(1),
  },
  {
    'id': 'mock-prop-2',
    'solicitud_id': 'mock-sol-1',
    'proveedor_id': _otroProveedor['id'],
    'descripcion':
        'Reviso la fuga y te doy presupuesto sin costo. Tengo disponibilidad mañana.',
    'precio': 25000,
    'tiempo_estimado': '1 hora',
    'status': 'PENDIENTE',
    'proveedor_nombre': 'Ana Martinez',
    'solicitud_titulo': 'Tengo una fuga de agua en el baño',
    'created_at': _ago(1),
  },
  {
    'id': 'mock-prop-3',
    'solicitud_id': 'mock-sol-2',
    'proveedor_id': _otroProveedor['id'],
    'descripcion':
        'Soy electricista certificada SEC. Puedo hacer la instalación completa en un día.',
    'precio': 60000,
    'tiempo_estimado': '1 día',
    'status': 'PENDIENTE',
    'proveedor_nombre': 'Ana Martinez',
    'solicitud_titulo': 'Instalar 5 enchufes nuevos',
    'created_at': _ago(0),
  },
  {
    'id': 'mock-prop-4',
    'solicitud_id': 'mock-sol-3',
    'proveedor_id': _proveedor['id'],
    'descripcion':
        'Pintura de alta calidad con acabado profesional. Incluye preparación de muros.',
    'precio': 95000,
    'tiempo_estimado': '2 días',
    'status': 'RECHAZADA',
    'proveedor_nombre': 'Carlos Perez',
    'solicitud_titulo': 'Pintar pieza de 12m2',
    'created_at': _ago(4),
  },
];

// --- Stats de admin ---
// La forma sigue el contrato real del backend que consume el dashboard:
// objetos anidados para usuarios/contrataciones y listas para los gráficos.
final _adminStats = {
  'usuarios': {'total': 4, 'clientes': 1, 'proveedores': 2, 'admins': 1},
  'servicios_activos': 7,
  'contrataciones': {'total': 24, 'este_mes': 12},
  'volumen_transaccionado_mes': 350000,
  'contrataciones_por_mes': [
    {'mes': '2026-01', 'total': 5},
    {'mes': '2026-02', 'total': 8},
    {'mes': '2026-03', 'total': 6},
    {'mes': '2026-04', 'total': 11},
    {'mes': '2026-05', 'total': 9},
    {'mes': '2026-06', 'total': 12},
  ],
  'top_proveedores': [
    {'nombre': 'Carlos Perez', 'rating': 4.8, 'total_contratos': 15},
    {'nombre': 'Ana Gonzalez', 'rating': 4.6, 'total_contratos': 9},
  ],
  'top_categorias': [
    {'nombre': 'Plomeria', 'total': 14},
    {'nombre': 'Electricidad', 'total': 8},
  ],
};

class MockApi {
  static dynamic handle(
    String method,
    String path,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  ) {
    final uri = Uri.parse('http://localhost$path');
    final cleanPath = uri.path;

    // --- AUTH ---
    if (method == 'POST' && cleanPath == '/auth/login') {
      final email = body?['email'] as String? ?? '';
      if (email.contains('admin')) {
        _setCurrentUser(_admin);
      } else if (email.contains('carlos') || email.contains('proveedor')) {
        _setCurrentUser(_proveedor);
      } else if (email.contains('ana')) {
        _setCurrentUser(_otroProveedor);
      } else {
        _setCurrentUser(_cliente);
      }
      // Backend solo devuelve token (sin user). El frontend debe llamar GET /auth/me después.
      return {'access_token': _token, 'token_type': 'bearer'};
    }

    if (method == 'POST' && cleanPath == '/auth/register') {
      _setCurrentUser({
        'id': 'mock-user-${_nextId("reg")}',
        'email': body?['email'] as String? ?? 'nuevo@correo.com',
        'nombre': body?['nombre'] as String? ?? 'Nuevo',
        'apellido': body?['apellido'] as String? ?? 'Usuario',
        'rol': body?['rol'] as String? ?? 'cliente',
        'telefono': body?['telefono'] as String?,
        'avatar_url': null,
        'bio': null,
        'habilidades': null,
        'is_active': true,
        'is_verified': false,
        'avg_rating': 0.0,
        'codigo_referido': 'REF${_nextId("ref").toString().padLeft(6, '0')}',
        'referidos_count': 0,
        'created_at': _now(),
        'updated_at': _now(),
      });
      return _usuarioActual;
    }

    if (method == 'GET' && cleanPath == '/auth/me') {
      if (_usuarioActual != null) return _usuarioActual;
      return _cliente;
    }

    if (method == 'GET' && cleanPath == '/auth/verify-email') {
      return {'message': 'Email verificado exitosamente'};
    }
    if (method == 'POST' && cleanPath == '/auth/forgot-password') {
      return {
        'message':
            'Si el email existe, recibirás un link para restablecer tu contraseña',
      };
    }
    if (method == 'POST' && cleanPath == '/auth/resend-verification') {
      return {'message': 'Email de verificación reenviado'};
    }
    if (method == 'POST' && cleanPath == '/auth/reset-password') {
      return {'message': 'Contraseña actualizada exitosamente'};
    }

    // --- SERVICIOS ---
    if (method == 'GET' && cleanPath == '/servicios') {
      return _servicios.where((s) => s['status'] == 'activo').toList();
    }

    if (method == 'GET' && cleanPath == '/servicios/buscar') {
      return _servicios.where((s) => s['status'] == 'activo').toList();
    }

    if (method == 'GET' && cleanPath.startsWith('/servicios/')) {
      final id = cleanPath.split('/').last;
      return _servicios.firstWhere(
        (s) => s['id'] == id,
        orElse: () => _servicios.first,
      );
    }

    if (method == 'POST' && cleanPath == '/servicios') {
      final nuevo = {
        'id': 'mock-serv-${_nextId("srv")}',
        'proveedor_id': _currentUserId,
        'categoria_id': body?['categoria_id'] as String? ?? 'gasfiteria',
        'titulo': body?['titulo'] as String? ?? 'Nuevo servicio',
        'descripcion': body?['descripcion'] as String? ?? '',
        'status': 'ACTIVO',
        'precio_min': body?['precio_min'] as double?,
        'precio_max': body?['precio_max'] as double?,
        'radio_cobertura_km': body?['radio_cobertura_km'] as int? ?? 10,
        'direccion_texto': body?['direccion_texto'] as String?,
        'fotos': null,
        'distancia': 1.0,
        'proveedor_nombre':
            _usuarioActual?['nombre']?.toString() ?? 'Proveedor',
        'proveedor_rating': 4.0,
        'categoria_nombre': 'Gasfiteria',
        'created_at': _now(),
      };
      _servicios.add(nuevo);
      return nuevo;
    }

    if (method == 'PUT' && cleanPath.startsWith('/servicios/')) {
      final id = cleanPath.split('/').last;
      final idx = _servicios.indexWhere((s) => s['id'] == id);
      if (idx >= 0 && body != null) {
        _servicios[idx] = {..._servicios[idx], ...body, 'id': id};
        return _servicios[idx];
      }
      return _servicios.first;
    }

    if (method == 'PATCH' &&
        cleanPath.startsWith('/servicios/') &&
        cleanPath.endsWith('/pausar')) {
      final id = cleanPath.split('/')[1];
      final idx = _servicios.indexWhere((s) => s['id'] == id);
      if (idx >= 0) {
        final actual = _servicios[idx]['status'] as String;
        _servicios[idx]['status'] = actual == 'PAUSADO' ? 'ACTIVO' : 'PAUSADO';
        return _servicios[idx]['status'];
      }
      return 'activo';
    }

    if (method == 'DELETE' && cleanPath.startsWith('/servicios/')) {
      final id = cleanPath.split('/').last;
      _servicios.removeWhere((s) => s['id'] == id);
      return null;
    }

    // --- CONTRATACIONES ---
    if (method == 'GET' && cleanPath == '/contrataciones') {
      return _contrataciones;
    }

    if (method == 'GET' && cleanPath.startsWith('/contrataciones/')) {
      final segments = cleanPath.split('/');
      if (segments.length == 2) {
        final id = segments[1];
        return _contrataciones.firstWhere(
          (c) => c['id'] == id,
          orElse: () => _contrataciones.first,
        );
      }
    }

    if (method == 'POST' && cleanPath == '/contrataciones') {
      final nueva = {
        'id': 'mock-contr-${_nextId("ctr")}',
        'cliente_id': _currentUserId,
        'proveedor_id': _proveedor['id'],
        'servicio_id': body?['servicio_id'] as String? ?? 'mock-serv-1',
        'status': 'PENDIENTE',
        'monto_acordado': body?['monto_acordado'] as double?,
        'mensaje_solicitud': body?['mensaje_solicitud'] as String?,
        'fecha_programada': body?['fecha_programada'] as String?,
        'created_at': _now(),
        'updated_at': _now(),
        'servicio_titulo': _servicios.firstWhere(
          (s) => s['id'] == body?['servicio_id'],
          orElse: () => _servicios.first,
        )['titulo'],
        'cliente_nombre': _usuarioActual?['nombre']?.toString() ?? 'Cliente',
        'proveedor_nombre': 'Carlos Perez',
      };
      _contrataciones.insert(0, nueva);
      return nueva;
    }

    if (method == 'PATCH' && cleanPath.startsWith('/contrataciones/')) {
      final segments = cleanPath.split('/');
      if (segments.length == 3 && segments[2] == 'aceptar') {
        final idx = _contrataciones.indexWhere((c) => c['id'] == segments[1]);
        if (idx >= 0) _contrataciones[idx]['status'] = 'ACEPTADO';
      } else if (segments.length == 3 && segments[2] == 'rechazar') {
        final idx = _contrataciones.indexWhere((c) => c['id'] == segments[1]);
        if (idx >= 0) _contrataciones[idx]['status'] = 'RECHAZADO';
      } else if (segments.length == 3 && segments[2] == 'finalizar') {
        final idx = _contrataciones.indexWhere((c) => c['id'] == segments[1]);
        if (idx >= 0) _contrataciones[idx]['status'] = 'COMPLETADO';
      } else if (segments.length == 3 && segments[2] == 'cancelar') {
        final idx = _contrataciones.indexWhere((c) => c['id'] == segments[1]);
        if (idx >= 0) _contrataciones[idx]['status'] = 'CANCELADO';
      }
      return null;
    }

    // Reseñas: POST /contrataciones/{id}/resena
    if (method == 'POST' &&
        RegExp(r'^/contrataciones/[^/]+/resena$').hasMatch(cleanPath)) {
      return {
        'id': 'mock-res-${_nextId("res")}',
        'contratacion_id': body?['contratacion_id'] as String? ?? '',
        'calificador_id': _currentUserId,
        'calificado_id': _proveedor['id'],
        'puntuacion': body?['puntuacion'] as int? ?? 5,
        'comentario': body?['comentario'] as String?,
        'created_at': _now(),
      };
    }

    // Reseñas: GET /contrataciones/usuario/{id}/resenas
    if (method == 'GET' &&
        RegExp(
          r'^/contrataciones/usuario/[^/]+/resenas$',
        ).hasMatch(cleanPath)) {
      return _resenas;
    }

    // Disputas: POST /disputas/contratacion/{contratacion_id}
    if (method == 'POST' &&
        RegExp(r'^/disputas/contratacion/[^/]+$').hasMatch(cleanPath)) {
      return {
        'id': 'mock-disp-${_nextId("dsp")}',
        'contratacion_id': cleanPath.split('/').last,
        'abridor_id': _currentUserId,
        'motivo': body?['motivo'] as String? ?? '',
        'evidencias': body?['evidencias'] as String?,
        'status': 'abierta',
        'resolucion': null,
        'created_at': _now(),
      };
    }

    // --- CHAT ---
    if (method == 'GET' && cleanPath == '/chat/conversaciones') {
      return _contrataciones.map((c) {
        final msgs = _mensajesPorContratacion[c['id']] ?? [];
        final lastMsg = msgs.isNotEmpty ? msgs.last : null;
        return {
          'contratacion_id': c['id'],
          'otro_usuario_id': c['proveedor_id'],
          'otro_usuario_nombre': c['proveedor_nombre'],
          'ultimo_mensaje': lastMsg?['contenido'] ?? 'Sin mensajes',
          'ultimo_mensaje_fecha': lastMsg?['created_at'] ?? _now(),
          'mensajes_no_leidos': 0,
          'status_contratacion': c['status'],
        };
      }).toList();
    }

    // GET /chat/{contratacion_id}/mensajes
    if (method == 'GET' &&
        RegExp(r'^/chat/[^/]+/mensajes$').hasMatch(cleanPath)) {
      final contratacionId = cleanPath.split('/')[2];
      return _mensajesPorContratacion[contratacionId] ?? [];
    }

    // POST /chat/{contratacion_id}/mensajes
    if (method == 'POST' &&
        RegExp(r'^/chat/[^/]+/mensajes$').hasMatch(cleanPath)) {
      final contratacionId = cleanPath.split('/')[2];
      final msg = {
        'id': 'mock-msg-${_nextId("msg")}',
        'contratacion_id': contratacionId,
        'emisor_id': _currentUserId,
        'contenido': body?['contenido'] as String? ?? '',
        'leido': false,
        'created_at': _now(),
      };
      _mensajesPorContratacion.putIfAbsent(contratacionId, () => []);
      _mensajesPorContratacion[contratacionId]!.add(msg);
      return msg;
    }

    // --- PAGOS ---
    // POST /pagos/crear?contratacion_id=... (query param, no body)
    if (method == 'POST' && cleanPath == '/pagos/crear') {
      return {
        'id': 'mock-pago-${_nextId("pag")}',
        'init_point': 'https://www.mercadopago.cl/mock-checkout',
        'sandbox_init_point': 'https://sandbox.mercadopago.cl/mock-checkout',
        'external_reference': queryParams?['contratacion_id'] ?? '',
        'status': 'pending',
      };
    }

    // GET /pagos/{contratacion_id}/estado
    if (method == 'GET' &&
        RegExp(r'^/pagos/[^/]+/estado$').hasMatch(cleanPath)) {
      return {
        'status': 'aprobado',
        'monto': 25000.0,
        'fee_plataforma': 2500.0,
        'monto_neto': 22500.0,
      };
    }

    // --- SUSCRIPCIONES ---
    // POST /suscripciones/crear → body: {plan_slug: string}
    if (method == 'POST' && cleanPath == '/suscripciones/crear') {
      return {
        'id': 'mock-sub-${_nextId("sub")}',
        'init_point': 'https://www.mercadopago.cl/mock-subscription',
        'status': 'pending',
      };
    }

    // GET /suscripciones/me
    if (method == 'GET' && cleanPath == '/suscripciones/me') {
      return {
        'tiene_suscripcion': true,
        'plan_slug': 'mock-plan-1',
        'status': 'activa',
        'fecha_inicio': _ago(15),
        'fecha_fin': _now(),
      };
    }

    // POST /suscripciones/cancelar
    if (method == 'POST' && cleanPath == '/suscripciones/cancelar') {
      return {'message': 'Suscripción cancelada'};
    }

    // --- ADMIN ---
    if (method == 'GET' && cleanPath == '/admin/stats') {
      return _adminStats;
    }

    if (method == 'GET' && cleanPath == '/admin/usuarios') {
      return {
        'data': [_cliente, _proveedor, _otroProveedor, _admin],
        'total': 4,
      };
    }

    if (method == 'POST' && cleanPath == '/admin/usuarios') {
      return {
        'id': 'mock-user-${_nextId("adm")}',
        'email': body?['email'] as String? ?? '',
        'nombre': body?['nombre'] as String? ?? '',
        'apellido': body?['apellido'] as String? ?? '',
        'rol': body?['rol'] as String? ?? 'cliente',
        'is_active': true,
      };
    }

    if (method == 'PUT' &&
        RegExp(r'^/admin/usuarios/[^/]+$').hasMatch(cleanPath)) {
      return {...body ?? {}, 'id': cleanPath.split('/').last};
    }

    if (method == 'PATCH' &&
        RegExp(r'^/admin/usuarios/[^/]+/toggle-active$').hasMatch(cleanPath)) {
      return {'id': cleanPath.split('/')[3], 'is_active': true};
    }

    if (method == 'GET' && cleanPath == '/admin/servicios') {
      return {'data': _servicios, 'total': _servicios.length};
    }

    if (method == 'GET' && cleanPath == '/admin/pagos') {
      return {
        'data': [
          {
            'id': 'mock-pago-1',
            'contratacion_id': 'mock-contr-1',
            'monto': 25000,
            'fee_plataforma': 2500,
            'monto_neto': 22500,
            'status': 'aprobado',
            'gateway': 'MercadoPago',
            'created_at': _ago(3),
          },
          {
            'id': 'mock-pago-2',
            'contratacion_id': 'mock-contr-2',
            'monto': 60000,
            'fee_plataforma': 6000,
            'monto_neto': 54000,
            'status': 'liberado',
            'gateway': 'MercadoPago',
            'created_at': _ago(8),
          },
          {
            'id': 'mock-pago-3',
            'contratacion_id': 'mock-contr-3',
            'monto': 18000,
            'fee_plataforma': 1800,
            'monto_neto': 16200,
            'status': 'pendiente',
            'gateway': 'MercadoPago',
            'created_at': _ago(1),
          },
        ],
        'total': 3,
      };
    }

    if (method == 'GET' && cleanPath == '/disputas/admin') {
      return {
        'data': [
          {
            'id': 'mock-disputa-1',
            'contratacion_id': 'mock-contr-1',
            'motivo': 'El trabajo no se completó en la fecha acordada',
            'status': 'pendiente',
            'created_at': _ago(2),
          },
        ],
        'total': 1,
      };
    }

    if (method == 'PATCH' &&
        RegExp(r'^/disputas/admin/[^/]+/resolver$').hasMatch(cleanPath)) {
      return {
        'id': cleanPath.split('/')[3],
        'status': 'resuelta',
        'accion': queryParams?['accion'] ?? 'liberar',
        'resolucion': body?['resolucion'] as String? ?? '',
      };
    }

    if (method == 'PATCH' &&
        cleanPath.contains('/disputas/admin/') &&
        cleanPath.contains('/resolver')) {
      return {'estado': 'resuelta'};
    }

    // --- CATEGORIAS ---
    if (method == 'GET' && cleanPath == '/categorias') {
      return _categorias;
    }

    // --- SOLICITUDES ---
    if (method == 'GET' && cleanPath == '/solicitudes') {
      return {'items': _solicitudes, 'total': _solicitudes.length};
    }

    if (method == 'GET' && cleanPath == '/solicitudes/mis-solicitudes') {
      return {
        'items': _solicitudes
            .where((s) => s['cliente_id'] == _currentUserId)
            .toList(),
        'total': _solicitudes
            .where((s) => s['cliente_id'] == _currentUserId)
            .length,
      };
    }

    if (method == 'GET' &&
        RegExp(r'^/solicitudes/[^/]+$').hasMatch(cleanPath)) {
      final id = cleanPath.split('/').last;
      return _solicitudes.firstWhere(
        (s) => s['id'] == id,
        orElse: () => _solicitudes.first,
      );
    }

    if (method == 'POST' && cleanPath == '/solicitudes') {
      final nueva = {
        'id': 'mock-sol-${_nextId("sol")}',
        'cliente_id': _currentUserId,
        'categoria_id': body?['categoria_id'] as String? ?? 'other',
        'titulo': body?['titulo'] as String? ?? 'Nueva solicitud',
        'descripcion': body?['descripcion'] as String? ?? '',
        'presupuesto_max': body?['presupuesto_max'] as double?,
        'ubicacion_texto': body?['ubicacion_texto'] as String?,
        'status': 'ABIERTA',
        'cliente_nombre': _usuarioActual?['nombre']?.toString() ?? 'Cliente',
        'propuestas_count': 0,
        'created_at': _now(),
      };
      _solicitudes.insert(0, nueva);
      return nueva;
    }

    if (method == 'PATCH' &&
        RegExp(r'^/solicitudes/[^/]+/cerrar$').hasMatch(cleanPath)) {
      final id = cleanPath.split('/')[2];
      final idx = _solicitudes.indexWhere((s) => s['id'] == id);
      if (idx >= 0) _solicitudes[idx]['status'] = 'CERRADA';
      return {'status': 'CERRADA'};
    }

    // --- PROPUESTAS ---
    if (method == 'GET' &&
        RegExp(r'^/solicitudes/[^/]+/propuestas$').hasMatch(cleanPath)) {
      final solicitudId = cleanPath.split('/')[2];
      return {
        'items': _propuestas
            .where((p) => p['solicitud_id'] == solicitudId)
            .toList(),
        'total': _propuestas
            .where((p) => p['solicitud_id'] == solicitudId)
            .length,
      };
    }

    if (method == 'POST' &&
        RegExp(r'^/solicitudes/[^/]+/propuestas$').hasMatch(cleanPath)) {
      final solicitudId = cleanPath.split('/')[2];
      final solicitud = _solicitudes.firstWhere(
        (s) => s['id'] == solicitudId,
        orElse: () => _solicitudes.first,
      );
      final nueva = {
        'id': 'mock-prop-${_nextId("prp")}',
        'solicitud_id': solicitudId,
        'proveedor_id': _currentUserId,
        'descripcion': body?['descripcion'] as String? ?? '',
        'precio': body?['precio'] as double? ?? 0,
        'tiempo_estimado': body?['tiempo_estimado'] as String? ?? '',
        'status': 'PENDIENTE',
        'proveedor_nombre':
            _usuarioActual?['nombre']?.toString() ?? 'Proveedor',
        'solicitud_titulo': solicitud['titulo'] as String,
        'created_at': _now(),
      };
      _propuestas.add(nueva);
      // Actualizar contador en solicitud
      final solIdx = _solicitudes.indexWhere((s) => s['id'] == solicitudId);
      if (solIdx >= 0) {
        _solicitudes[solIdx]['propuestas_count'] =
            (_solicitudes[solIdx]['propuestas_count'] as int) + 1;
      }
      return nueva;
    }

    if (method == 'GET' && cleanPath == '/propuestas/mis-propuestas') {
      return {
        'items': _propuestas
            .where((p) => p['proveedor_id'] == _currentUserId)
            .toList(),
        'total': _propuestas
            .where((p) => p['proveedor_id'] == _currentUserId)
            .length,
      };
    }

    if (method == 'PATCH' &&
        RegExp(
          r'^/solicitudes/[^/]+/propuestas/[^/]+/aceptar$',
        ).hasMatch(cleanPath)) {
      final segments = cleanPath.split('/');
      final propuestaId = segments[4];
      final idx = _propuestas.indexWhere((p) => p['id'] == propuestaId);
      if (idx >= 0) _propuestas[idx]['status'] = 'ACEPTADA';
      return _propuestas[idx];
    }

    if (method == 'PATCH' &&
        RegExp(
          r'^/solicitudes/[^/]+/propuestas/[^/]+/rechazar$',
        ).hasMatch(cleanPath)) {
      final segments = cleanPath.split('/');
      final propuestaId = segments[4];
      final idx = _propuestas.indexWhere((p) => p['id'] == propuestaId);
      if (idx >= 0) _propuestas[idx]['status'] = 'RECHAZADA';
      return _propuestas[idx];
    }

    // --- USUARIOS ME ---
    if (method == 'PUT' && cleanPath == '/usuarios/me') {
      if (_usuarioActual != null) {
        _usuarioActual = {..._usuarioActual!, ...?body};
      }
      return _usuarioActual ?? _cliente;
    }

    // --- UPLOAD ---
    if (method == 'POST' && cleanPath == '/upload/avatar') {
      return {'url': 'https://i.pravatar.cc/150?u=mock-avatar'};
    }

    if (method == 'POST' && cleanPath.startsWith('/upload/servicio/')) {
      return {'url': 'https://picsum.photos/400/300?random=mock'};
    }

    return null;
  }
}
