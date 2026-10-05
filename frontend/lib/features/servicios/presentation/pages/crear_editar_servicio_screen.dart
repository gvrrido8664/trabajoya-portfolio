import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/shared/widgets/success_dialog.dart';
import 'package:trabajoya_app/shared/data/upload_service.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/utils/unsaved_changes.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';
import 'package:trabajoya_app/utils/colors.dart';

class NuevaSolicitudFormScreen extends StatefulWidget {
  final String? servicioId; // Si viene ID, funciona como modo edición
  const NuevaSolicitudFormScreen({super.key, this.servicioId});

  @override
  State<NuevaSolicitudFormScreen> createState() =>
      _NuevaSolicitudFormScreenState();
}

class _NuevaSolicitudFormScreenState extends State<NuevaSolicitudFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _presupuestoCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();

  String? _categoriaPadreId;
  String? _categoriaIdSeleccionada;
  bool _isSubmitting = false;
  bool _gettingLocation = false;
  bool _loadingServicio = false;
  XFile? _fotoSeleccionada;
  Uint8List? _fotoBytes;
  // 'hora' | 'servicio' | 'convenir'
  String _modalidadPrecio = 'servicio';

  double? _latitud;
  double? _longitud;
  double _radioSeleccionado = 10;
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _sugerencias = [];
  Timer? _debounce;
  bool _progSetting = false;
  bool _dirty = false;

  bool get _isEditing => widget.servicioId != null;

  @override
  void initState() {
    super.initState();
    _ubicacionCtrl.addListener(_onUbicacionChanged);
    _tituloCtrl.addListener(_updateProgressState);
    _descripcionCtrl.addListener(_updateProgressState);
    _ubicacionCtrl.addListener(_updateProgressState);
    _presupuestoCtrl.addListener(_updateProgressState);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<ServiciosProvider>();
      await prov.cargarCategorias();
      if (_isEditing) _cargarServicio(prov);
    });
  }

  void _updateProgressState() {
    // _cargarServicio() también pasa por acá al precargar los campos en modo
    // edición -- no cuenta como "cambio del usuario" (FUN-32).
    if (!_loadingServicio) _dirty = true;
    if (mounted) setState(() {});
  }

  Future<void> _volver() async {
    if (await confirmDiscardChanges(context, hasChanges: _dirty) && mounted) {
      context.pop();
    }
  }

  double _calculateProgress() {
    double p = 0.0;
    if (_categoriaPadreId != null) p += 0.2;
    if (_tituloCtrl.text.trim().isNotEmpty) p += 0.2;
    if (_descripcionCtrl.text.trim().isNotEmpty) p += 0.2;
    if (_fotoBytes != null || _fotoSeleccionada != null) p += 0.2;
    if (_ubicacionCtrl.text.trim().isNotEmpty) p += 0.2;
    return p;
  }

  String _getProgressText() {
    if (_categoriaPadreId == null || _tituloCtrl.text.isEmpty) {
      return "Paso 1 de 3: Completa los detalles principales";
    }
    if (_fotoBytes == null && _fotoSeleccionada == null) {
      return "Paso 2 de 3: Sube una foto para destacar tu servicio";
    }
    return "Paso 3 de 3: Configura tarifas y ubicación";
  }

  Future<void> _cargarServicio(ServiciosProvider prov) async {
    setState(() => _loadingServicio = true);
    try {
      final s = await prov.getServicioById(widget.servicioId!);
      if (!mounted) return;
      setState(() {
        _tituloCtrl.text = s.titulo;
        _descripcionCtrl.text = s.descripcion;
        _ubicacionCtrl.text = s.direccionTexto ?? '';
        _categoriaPadreId = s.categoriaId;
        _categoriaIdSeleccionada = s.subcategoriaId;
        _latitud = s.latitud;
        _longitud = s.longitud;
        _radioSeleccionado = s.radioCoberturaKm.toDouble();
        if (s.precioMin != null) {
          _presupuestoCtrl.text = s.precioMin!.toStringAsFixed(0);
          _modalidadPrecio = s.precioMax == 1.0
              ? 'hora'
              : s.precioMax == 2.0
              ? 'servicio'
              : 'servicio';
        } else {
          _modalidadPrecio = 'convenir';
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el servicio')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingServicio = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ubicacionCtrl.removeListener(_onUbicacionChanged);
    _tituloCtrl.removeListener(_updateProgressState);
    _descripcionCtrl.removeListener(_updateProgressState);
    _ubicacionCtrl.removeListener(_updateProgressState);
    _presupuestoCtrl.removeListener(_updateProgressState);
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _presupuestoCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _gettingLocation = true;
      _sugerencias = [];
    });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      setState(() {
        _latitud = pos.latitude;
        _longitud = pos.longitude;
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 12);

      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': pos.latitude.toString(),
        'lon': pos.longitude.toString(),
        'format': 'json',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'TrabajoYa/1.0'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final suburb =
            address['suburb'] as String? ??
            address['neighbourhood'] as String? ??
            address['city_district'] as String?;
        final city =
            address['city'] as String? ??
            address['town'] as String? ??
            address['municipality'] as String? ??
            address['county'] as String?;
        final parts = [
          suburb,
          city,
        ].whereType<String>().where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          _progSetting = true;
          _ubicacionCtrl.text = parts.join(', ');
          _progSetting = false;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación: ${formatError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  void _onUbicacionChanged() {
    if (_progSetting) return;
    final q = _ubicacionCtrl.text.trim();
    _debounce?.cancel();
    if (q.length < 3) {
      setState(() => _sugerencias = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _buscarDirecciones(q),
    );
  }

  Future<void> _buscarDirecciones(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'countrycodes': 'cl',
        'format': 'json',
        'limit': '5',
        'addressdetails': '1',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'TrabajoYa/1.0'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() => _sugerencias = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  void _seleccionarDireccion(Map<String, dynamic> d) {
    final lat = double.tryParse(d['lat']?.toString() ?? '');
    final lng = double.tryParse(d['lon']?.toString() ?? '');
    final address = d['address'] as Map<String, dynamic>? ?? {};
    final road =
        address['road'] as String? ?? address['pedestrian'] as String? ?? '';
    final suburb =
        address['suburb'] as String? ??
        address['neighbourhood'] as String? ??
        '';
    final city =
        address['city'] as String? ??
        address['town'] as String? ??
        address['municipality'] as String? ??
        address['county'] as String? ??
        '';
    final parts = [road, suburb, city].where((s) => s.isNotEmpty).toList();
    _progSetting = true;
    setState(() {
      _ubicacionCtrl.text = parts.isNotEmpty
          ? parts.join(', ')
          : (d['display_name'] as String? ?? '');
      _ubicacionCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ubicacionCtrl.text.length),
      );
      _sugerencias = [];
      if (lat != null && lng != null) {
        _latitud = lat;
        _longitud = lng;
        _mapController.move(LatLng(lat, lng), 14);
      }
    });
    _progSetting = false;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _dirty = true;
        _fotoSeleccionada = picked;
        _fotoBytes = bytes;
      });
    }
  }

  void _mostrarDialogoPremium(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('¡Mejora a Premium!'),
          ],
        ),
        content: Text(
          '$message\n\n'
          'Con el plan Premium podrás publicar servicios ilimitados, destacar tus servicios en los resultados de búsqueda y lucir el sello Premium en tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/planes');
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    if (_categoriaPadreId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una categoría')));
      setState(() => _isSubmitting = false);
      return;
    }
    try {
      final prov = context.read<ServiciosProvider>();
      final monto = _modalidadPrecio != 'convenir'
          ? double.tryParse(_presupuestoCtrl.text.trim())
          : null;
      // precio_max encodes unit: 1.0 = por hora, 2.0 = por servicio, null = a convenir
      final precioMaxSentinel = _modalidadPrecio == 'hora'
          ? 1.0
          : _modalidadPrecio == 'servicio'
          ? 2.0
          : null;
      String servicioId;
      if (_isEditing) {
        final data = <String, dynamic>{
          'categoria_id': _categoriaPadreId,
          if (_categoriaIdSeleccionada != null)
            'subcategoria_id': _categoriaIdSeleccionada,
          'titulo': _tituloCtrl.text.trim(),
          'descripcion': _descripcionCtrl.text.trim(),
          'precio_min': monto,
          'precio_max': precioMaxSentinel,
          'direccion_texto': _ubicacionCtrl.text.trim().isEmpty
              ? null
              : _ubicacionCtrl.text.trim(),
          'radio_cobertura_km': _radioSeleccionado.round(),
          if (_latitud != null) 'latitud': _latitud,
          if (_longitud != null) 'longitud': _longitud,
        };
        final actualizado = await prov.actualizarServicio(
          widget.servicioId!,
          data,
        );
        servicioId = actualizado.id;
      } else {
        final nuevo = await prov.crearServicio(
          _categoriaPadreId!,
          _tituloCtrl.text.trim(),
          _descripcionCtrl.text.trim(),
          subcategoriaId: _categoriaIdSeleccionada,
          precioMin: monto,
          precioMax: precioMaxSentinel,
          radioKm: _radioSeleccionado.round(),
          direccion: _ubicacionCtrl.text.trim().isEmpty
              ? null
              : _ubicacionCtrl.text.trim(),
          latitud: _latitud,
          longitud: _longitud,
        );
        servicioId = nuevo.id;
      }
      if (_fotoBytes != null && _fotoSeleccionada != null) {
        try {
          await UploadService().uploadFotoServicioBytes(
            servicioId,
            _fotoBytes!,
            _fotoSeleccionada!.name,
            _fotoSeleccionada!.mimeType,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Servicio guardado, pero no se pudo subir la foto: ${formatError(e)}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      if (!mounted) return;
      await SuccessDialog.show(
        context: context,
        title: '¡Excelente!',
        message: _isEditing
            ? 'Servicio actualizado'
            : 'Servicio publicado exitosamente',
        onPressed: () {
          context.pop(); // Cierra el dialogo
          context.pop(); // Cierra la pantalla
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 && e.message.contains('Límite alcanzado')) {
        _mostrarDialogoPremium(e.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar servicio: ${formatError(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<LatLng> _buildCirclePoints() {
    const kmPerDegree = 111.32;
    final latRad = (_latitud ?? 0) * pi / 180;
    final lngKmPerDegree = kmPerDegree * cos(latRad);
    final pts = <LatLng>[];
    for (int i = 0; i < 360; i += 10) {
      final a = i * pi / 180;
      pts.add(
        LatLng(
          (_latitud ?? 0) + (_radioSeleccionado / kmPerDegree) * cos(a),
          (_longitud ?? 0) + (_radioSeleccionado / lngKmPerDegree) * sin(a),
        ),
      );
    }
    return pts;
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    final isDesktop = width > 1100;
    final isMobileHead = width < 780;

    final provCat = context.watch<ServiciosProvider>();
    final raices = provCat.categoriasRaiz;
    final hijas = provCat.subcategoriasDe(_categoriaPadreId);

    if (_loadingServicio) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          bodyMedium: theme.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          bodySmall: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          titleMedium: theme.textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          titleSmall: theme.textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      child: PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _volver();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl2),
          child: _centered(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flex(
                  direction: isMobileHead ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isMobileHead ? 0 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'Editar servicio'
                                : 'Crear nuevo servicio',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isEditing
                                ? 'Modificá los datos de tu servicio.'
                                : 'Publicá lo que ofrecés para que los clientes te encuentren.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMobileHead)
                      const SizedBox(height: Spacing.md)
                    else
                      const SizedBox(width: Spacing.xl),
                    ProButton(
                      label: '← Volver a mis servicios',
                      isOutline: true,
                      compact: true,
                      onPressed: _volver,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xl2),

                Form(
                  key: _formKey,
                  child: Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isDesktop ? 1 : 0,
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(26.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.blueprint.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(Radii.pill),
                                  ),
                                  child: Text(
                                    _isEditing
                                        ? 'Editar servicio'
                                        : 'Publicar servicio',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Publicá tu servicio',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    
                                  ),
                                ),
                                const SizedBox(height: Spacing.xl2),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.blueprint.withValues(
                                      alpha: 0.04,
                                    ),
                                    borderRadius: BorderRadius.circular(Radii.md),
                                    border: Border.all(
                                      color: AppColors.blueprint.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _getProgressText(),
                                              style: const TextStyle(
                                                
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${(_calculateProgress() * 100).toInt()}%',
                                            style: const TextStyle(
                                              
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          Radii.pill,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: _calculateProgress(),
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(AppColors.primary),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: Spacing.xl2),
                                _GroupBox(
                                  title: 'Información principal',
                                  children: [
                                    DropdownButtonFormField<String>(
                                      key: ValueKey(
                                        _categoriaPadreId ?? '__none__',
                                      ),
                                      initialValue: _categoriaPadreId,
                                      isExpanded: true,
                                      hint: const Text('Categoría'),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      decoration: _inputDecoration(
                                        Icons.folder_open_outlined,
                                      ),
                                      items: raices
                                          .map(
                                            (c) => DropdownMenuItem<String>(
                                              value: c.id,
                                              child: Text(
                                                '${c.icono ?? ''} ${c.nombre}'
                                                    .trim(),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(() {
                                        _dirty = true;
                                        _categoriaPadreId = v;
                                        _categoriaIdSeleccionada = null;
                                      }),
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      key: ValueKey('sub_$_categoriaPadreId'),
                                      initialValue: _categoriaIdSeleccionada,
                                      isExpanded: true,
                                      hint: Text(
                                        _categoriaPadreId == null
                                            ? 'Primero elige una categoría'
                                            : hijas.isEmpty
                                            ? 'Sin subcategorías disponibles'
                                            : 'Subcategoría',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      decoration: _inputDecoration(
                                        Icons.subdirectory_arrow_right_outlined,
                                      ),
                                      items: hijas
                                          .map(
                                            (c) => DropdownMenuItem<String>(
                                              value: c.id,
                                              child: Text(
                                                '${c.icono ?? ''} ${c.nombre}'
                                                    .trim(),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged:
                                          _categoriaPadreId == null ||
                                              hijas.isEmpty
                                          ? null
                                          : (v) => setState(
                                              () =>
                                                  _categoriaIdSeleccionada = v,
                                            ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _tituloCtrl,
                                      maxLength: 100,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration: _inputDecoration(
                                        Icons.text_fields_outlined,
                                        hint: 'Título de la solicitud',
                                      ),
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                          ? 'El título es obligatorio'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _descripcionCtrl,
                                      maxLines: 5,
                                      minLines: 4,
                                      maxLength: 2000,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration: _inputDecoration(
                                        Icons.description_outlined,
                                        hint: 'Descripción detallada',
                                      ),
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                          ? 'La descripción es obligatoria'
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Spacing.lg),

                                _GroupBox(
                                  title: 'Foto del servicio',
                                  children: [
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        height: 140,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            Radii.md,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outline,
                                            width: 1.5,
                                          ),
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        ),
                                        child: _fotoBytes != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(Radii.md),
                                                child: Image.memory(
                                                  _fotoBytes!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                              )
                                            : _photoPlaceholder(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Spacing.lg),

                                _GroupBox(
                                  title: 'Precio y ubicación',
                                  children: [
                                    Row(
                                      children: [
                                        for (final op in [
                                          ('servicio', 'Por servicio'),
                                          ('hora', 'Por hora'),
                                          ('convenir', 'A convenir'),
                                        ]) ...[
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() {
                                                _dirty = true;
                                                _modalidadPrecio = op.$1;
                                              }),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 150,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      _modalidadPrecio == op.$1
                                                      ? AppColors.primary
                                                      : Theme.of(context).colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(Radii.md),
                                                  border: Border.all(
                                                    color:
                                                        _modalidadPrecio ==
                                                            op.$1
                                                        ? AppColors.primary
                                                        : Theme.of(context).colorScheme.outline,
                                                  ),
                                                ),
                                                child: Text(
                                                  op.$2,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        _modalidadPrecio ==
                                                            op.$1
                                                        ? Colors.white
                                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (op.$1 != 'convenir')
                                            const SizedBox(width: 8),
                                        ],
                                      ],
                                    ),
                                    if (_modalidadPrecio != 'convenir') ...[
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _presupuestoCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration(
                                          Icons.attach_money_outlined,
                                          hint: _modalidadPrecio == 'hora'
                                              ? 'Precio por hora (\$)'
                                              : 'Precio por servicio (\$)',
                                        ),
                                        // Sin esto se podía elegir "por hora"
                                        // / "por servicio" y dejar el monto
                                        // vacío o negativo -- se publicaba
                                        // igual con precio_min null.
                                        validator: (v) {
                                          if (_modalidadPrecio == 'convenir') {
                                            return null;
                                          }
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Ingresa un precio';
                                          }
                                          final p = double.tryParse(v.trim());
                                          if (p == null || p <= 0) {
                                            return 'Monto inválido (debe ser mayor a 0)';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _ubicacionCtrl,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration:
                                          _inputDecoration(
                                            Icons.location_on_outlined,
                                            hint: 'Ubicación o comuna',
                                          ).copyWith(
                                            suffixIcon: _gettingLocation
                                                ? const Padding(
                                                    padding: EdgeInsets.all(14),
                                                    child: SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  )
                                                : IconButton(
                                                    icon: const Icon(
                                                      Icons.my_location,
                                                      size: 20,
                                                      color: AppColors.primary,
                                                    ),
                                                    tooltip:
                                                        'Usar mi ubicación',
                                                    onPressed: _getLocation,
                                                  ),
                                          ),
                                    ),
                                    if (_sugerencias.isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                        ),
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            Radii.md,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: _sugerencias.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(
                                                height: 1,
                                                indent: 12,
                                                endIndent: 12,
                                              ),
                                          itemBuilder: (_, i) {
                                            final d = _sugerencias[i];
                                            return InkWell(
                                              onTap: () =>
                                                  _seleccionarDireccion(d),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12,
                                                    ),
                                                child: Text(
                                                  d['display_name']
                                                          as String? ??
                                                      '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 16),

                                    // Mapa de cobertura
                                    Container(
                                      height: 280,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Radii.md),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: FlutterMap(
                                        options: MapOptions(
                                          initialCenter: LatLng(
                                            _latitud ?? -33.456,
                                            _longitud ?? -70.648,
                                          ),
                                          initialZoom: 12,
                                          onTap: (_, point) => setState(() {
                                            _latitud = point.latitude;
                                            _longitud = point.longitude;
                                          }),
                                        ),
                                        mapController: _mapController,
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.trabajoya.app',
                                          ),
                                          if (_latitud != null &&
                                              _longitud != null) ...[
                                            PolygonLayer(
                                              polygons: [
                                                Polygon(
                                                  points: _buildCirclePoints(),
                                                  color: AppColors.primary
                                                      .withOpacity(0.2),
                                                  borderColor:
                                                      AppColors.primary,
                                                  borderStrokeWidth: 2,
                                                ),
                                              ],
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(
                                                    _latitud!,
                                                    _longitud!,
                                                  ),
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: AppColors.primary,
                                                    size: 36,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.radio_button_checked,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                                  activeTrackColor:
                                                      AppColors.primary,
                                                  inactiveTrackColor: AppColors
                                                      .primary
                                                      .withValues(alpha: 0.15),
                                                  thumbColor: AppColors.primary,
                                                  overlayColor: AppColors
                                                      .primary
                                                      .withValues(alpha: 0.1),
                                                  valueIndicatorColor:
                                                      AppColors.primary,
                                                  valueIndicatorTextStyle:
                                                      const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                            child: Slider(
                                              value: _radioSeleccionado,
                                              min: 1,
                                              max: 100,
                                              divisions: 99,
                                              label:
                                                  '${_radioSeleccionado.round()} km',
                                              onChanged: (v) => setState(
                                                () => _radioSeleccionado = v,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 48,
                                          child: Text(
                                            '${_radioSeleccionado.round()} km',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: Spacing.xl),

                                ProButton(
                                  label: _isEditing
                                      ? 'Guardar cambios'
                                      : 'Publicar servicio',
                                  loading: _isSubmitting,
                                  onPressed: _submitForm,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isDesktop)
                        const SizedBox(width: Spacing.xl)
                      else
                        const SizedBox(height: Spacing.xl2),

                      SizedBox(
                        width: isDesktop ? 340 : double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              margin: EdgeInsets.zero,
                              color: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Radii.md),
                                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(22.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Antes de publicar',
                                      style: TextStyle(
                                        
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Mientras más completo sea tu perfil de servicio, más clientes vas a atraer.',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        
                                        height: 1.55,
                                      ),
                                    ),
                                    SizedBox(height: 18),
                                    _GuideStepItem(
                                      number: '1',
                                      title: 'Elige la categoría correcta',
                                      subtitle:
                                          'Ayuda a que aparezcan proveedores del rubro adecuado.',
                                    ),
                                    SizedBox(height: 12),
                                    _GuideStepItem(
                                      number: '2',
                                      title: 'Describe bien tu servicio',
                                      subtitle:
                                          'Explicá qué ofrecés, tu experiencia y qué te diferencia.',
                                    ),
                                    SizedBox(height: 12),
                                    _GuideStepItem(
                                      number: '3',
                                      title: 'Agrega precio y ubicación',
                                      subtitle:
                                          'Eso ayuda a los clientes a encontrarte y contactarte.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: ProColors.textSecondary,
        ),
        SizedBox(height: 8),
        Text(
          'Toca para agregar una foto',
          style: TextStyle(color: ProColors.textSecondary, ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData prefixIcon, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: cs.onSurfaceVariant, size: 20),
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}

// --- WIDGETS COMPONENTIZADOS PRIVADOS AL FINAL ---

class _GroupBox extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GroupBox({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _GuideStepItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _GuideStepItem({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.blueprint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
