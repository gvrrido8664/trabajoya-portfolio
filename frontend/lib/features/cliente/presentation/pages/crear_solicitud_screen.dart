import 'package:trabajoya_app/utils/colors.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/features/solicitudes/presentation/providers/solicitudes_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/utils/unsaved_changes.dart';

class CrearSolicitudScreen extends StatefulWidget {
  const CrearSolicitudScreen({super.key});

  @override
  State<CrearSolicitudScreen> createState() => _CrearSolicitudScreenState();
}

class _CrearSolicitudScreenState extends State<CrearSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _presupuestoCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  String? _categoriaPadreId;
  String? _categoriaIdSeleccionada;
  bool _isSubmitting = false;
  bool _gettingLocation = false;
  bool _dirty = false;
  String _modalidadPresupuesto = 'presupuesto'; // 'presupuesto' | 'convenir'
  List<Map<String, dynamic>> _sugerencias = [];
  Timer? _debounce;
  bool _progSetting = false;
  final _mapController = MapController();
  LatLng _selectedCoords = const LatLng(-33.4489, -70.6693);

  @override
  void initState() {
    super.initState();
    _ubicacionCtrl.addListener(_onUbicacionChanged);
    for (final c in [_tituloCtrl, _descripcionCtrl, _presupuestoCtrl]) {
      c.addListener(() => _dirty = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiciosProvider>().cargarCategorias();
      final auth = context.read<AuthProvider>();
      if (auth.usuario?.comuna != null && auth.usuario!.comuna!.isNotEmpty) {
        _progSetting = true;
        _ubicacionCtrl.text = auth.usuario!.comuna!;
        _progSetting = false;
        // Optionally trigger a geocode for the map
        _buscarComuna(auth.usuario!.comuna!);
      }
    });
  }

  Future<void> _buscarComuna(String comuna) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$comuna, Chile',
      'format': 'json',
      'limit': '1',
    });
    try {
      final response = await http.get(uri, headers: {'User-Agent': 'TrabajoYa/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'] as String? ?? '');
          final lon = double.tryParse(data[0]['lon'] as String? ?? '');
          if (lat != null && lon != null && mounted) {
            setState(() {
              _selectedCoords = LatLng(lat, lon);
            });
            _mapController.move(_selectedCoords, 14.0);
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ubicacionCtrl.removeListener(_onUbicacionChanged);
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

        setState(() {
          _selectedCoords = LatLng(pos.latitude, pos.longitude);
          _mapController.move(_selectedCoords, 15.0);
        });
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
    _dirty = true;
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

      final lat = double.tryParse(d['lat'] as String? ?? '');
      final lon = double.tryParse(d['lon'] as String? ?? '');
      if (lat != null && lon != null) {
        _selectedCoords = LatLng(lat, lon);
        _mapController.move(_selectedCoords, 15.0);
      }
    });
    _progSetting = false;
  }

  Future<void> _updateLocationFromCoordinates(LatLng coords) async {
    setState(() {
      _selectedCoords = coords;
    });
    _mapController.move(coords, _mapController.camera.zoom);

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': coords.latitude.toString(),
        'lon': coords.longitude.toString(),
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
        final road =
            address['road'] as String? ??
            address['pedestrian'] as String? ??
            '';
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
              : (data['display_name'] as String? ?? '');
        });
        _progSetting = false;
      }
    } catch (_) {}
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final prov = context.read<SolicitudesProvider>();
    final success = await prov.crearSolicitud(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      categoriaId: _categoriaIdSeleccionada ?? _categoriaPadreId,
      presupuestoMax: _modalidadPresupuesto == 'convenir'
          ? null
          : double.tryParse(_presupuestoCtrl.text.trim()),
      ubicacionTexto: _ubicacionCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Solicitud publicada exitosamente'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Error al crear solicitud'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _volver() async {
    if (await confirmDiscardChanges(context, hasChanges: _dirty) && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;
    final isMobileHead = width < 780;
    final provCat = context.watch<ServiciosProvider>();
    final raices = provCat.categoriasRaiz;
    final hijas = provCat.subcategoriasDe(_categoriaPadreId);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _volver();
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
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
                            'Crear nueva solicitud',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: CliColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Publica requerimientos claros para recibir propuestas de proveedores.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: CliColors.textSecondary(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMobileHead)
                      const SizedBox(height: Spacing.md)
                    else
                      const SizedBox(width: Spacing.xl),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _volver,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Volver a mis solicitudes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CliColors.textPrimary(context),
                        backgroundColor: CliColors.surface(context),
                        side: BorderSide(color: CliColors.border(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xl2),
                Form(
                  key: _formKey,
                  child: AbsorbPointer(
                    absorbing: _isSubmitting,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isSubmitting ? 0.6 : 1.0,
                      child: Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isDesktop ? 1 : 0,
                            child: CliCard(
                              padding: const EdgeInsets.all(Spacing.xl2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: CliColors.accent.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(Radii.pill),
                                ),
                                child: Text(
                                  'Publicar necesidad',
                                  style: TextStyle(
                                    color: CliColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cuéntanos qué necesitas',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Una buena descripción ayuda a que lleguen mejores propuestas.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: CliColors.textSecondary(context),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: Spacing.xl2),
                              _FormGroupContainer(
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
                                      color: CliColors.textSecondary(context),
                                    ),
                                    decoration: _inputDecoration(
                                      Icons.folder_open_outlined,
                                    ),
                                    validator: (v) => v == null ? 'La categoría es obligatoria' : null,
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
                                    onChanged: _isSubmitting ? null : (v) => setState(() {
                                      _categoriaPadreId = v;
                                      _categoriaIdSeleccionada = null;
                                    }),
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('sub_$_categoriaPadreId'),
                                    initialValue: _categoriaIdSeleccionada,
                                    // Sin isExpanded, el hint largo
                                    // ("Primero elige una categoría")
                                    // desbordaba fuera del borde del campo
                                    // en vez de truncarse con ellipsis.
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
                                      color: CliColors.textSecondary(context),
                                    ),
                                    decoration: _inputDecoration(
                                      Icons.subdirectory_arrow_right_outlined,
                                    ),
                                    validator: (v) {
                                      if (_categoriaPadreId != null && hijas.isNotEmpty && v == null) {
                                        return 'La subcategoría es obligatoria';
                                      }
                                      return null;
                                    },
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
                                        _isSubmitting || _categoriaPadreId == null ||
                                            hijas.isEmpty
                                        ? null
                                        : (v) => setState(
                                            () => _categoriaIdSeleccionada = v,
                                          ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _tituloCtrl,
                                    enabled: !_isSubmitting,
                                    maxLength: 100,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: _inputDecoration(
                                      Icons.title_outlined,
                                      hint: 'Título de la solicitud',
                                    ),
                                    validator: (v) => v!.trim().isEmpty
                                        ? 'El título es obligatorio'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _descripcionCtrl,
                                    enabled: !_isSubmitting,
                                    maxLines: 5,
                                    minLines: 4,
                                    maxLength: 2000,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: _inputDecoration(
                                      Icons.description_outlined,
                                      hint: 'Descripción detallada',
                                    ),
                                    validator: (v) => v!.trim().isEmpty
                                        ? 'La descripción es obligatoria'
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.lg),
                              _FormGroupContainer(
                                title: 'Presupuesto y ubicación',
                                children: [
                                  Row(
                                    children: [
                                      for (final op in [
                                        ('presupuesto', 'Tengo presupuesto'),
                                        ('convenir', 'A convenir'),
                                      ]) ...[
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _isSubmitting
                                                ? null
                                                : () => setState(
                                                      () => _modalidadPresupuesto = op.$1,
                                                    ),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _modalidadPresupuesto == op.$1
                                                    ? CliColors.accent
                                                    : CliColors.surface(context),
                                                borderRadius: BorderRadius.circular(Radii.md),
                                                border: Border.all(
                                                  color: _modalidadPresupuesto == op.$1
                                                      ? CliColors.accent
                                                      : CliColors.border(context),
                                                ),
                                              ),
                                              child: Text(
                                                op.$2,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: _modalidadPresupuesto == op.$1
                                                      ? Colors.white
                                                      : CliColors.textSecondary(context),
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
                                  if (_modalidadPresupuesto == 'presupuesto') ...[
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _presupuestoCtrl,
                                      enabled: !_isSubmitting,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration(
                                        Icons.attach_money_outlined,
                                        hint: 'Presupuesto máximo (\$)',
                                      ),
                                      validator: (v) {
                                        if (_modalidadPresupuesto != 'presupuesto') return null;
                                        if (v == null || v.trim().isEmpty) {
                                          return 'El presupuesto es obligatorio';
                                        }
                                        final p = double.tryParse(v.trim());
                                        if (p == null || p <= 0) {
                                          return 'Monto inválido (debe ser mayor a 0)';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  if (_modalidadPresupuesto == 'convenir') ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CliColors.accent.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(Radii.md),
                                        border: Border.all(
                                          color: CliColors.accent.withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: CliColors.accent, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'El presupuesto se acordará directamente con el proveedor durante la negociación.',
                                              style: TextStyle(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white70
                                                    : CliColors.textSecondary(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _ubicacionCtrl,
                                    enabled: !_isSubmitting,
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
                                                  icon: Icon(
                                                    Icons.my_location,
                                                    size: 20,
                                                    color: CliColors.accent,
                                                  ),
                                                  tooltip: 'Usar mi ubicación',
                                                  onPressed: _isSubmitting ? null : _getLocation,
                                                ),
                                        ),
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'La ubicación es obligatoria'
                                        : null,
                                  ),
                                  if (_sugerencias.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                      ),
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: CliColors.surface(context),
                                        borderRadius: BorderRadius.circular(Radii.md),
                                        border: Border.all(
                                          color: CliColors.border(context),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
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
                                                d['display_name'] as String? ??
                                                    '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: CliColors.textPrimary(context),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(Radii.md),
                                    child: Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: CliColors.border(context),
                                        ),
                                        borderRadius: BorderRadius.circular(Radii.md),
                                      ),
                                      child: FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: _selectedCoords,
                                          initialZoom: 14.0,
                                          onTap: _isSubmitting
                                              ? null
                                              : (_, point) {
                                                  _updateLocationFromCoordinates(
                                                    point,
                                                  );
                                                },
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.trabajoya.app',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: _selectedCoords,
                                                width: 40,
                                                height: 40,
                                                child: const Icon(
                                                  Icons.location_on,
                                                  size: 40,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.xl),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CliColors.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Radii.md),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Publicar solicitud',
                                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isDesktop)
                        const SizedBox(width: Spacing.xl)
                      else
                        const SizedBox(height: Spacing.xl2),
                      SizedBox(
                        width: isDesktop ? 340 : double.infinity,
                        child: CliCard(
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CliSectionHeader(title: 'Antes de publicar'),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                'Mientras más específica sea tu solicitud, mejores propuestas vas a recibir.',
                                style: TextStyle(
                                  color: CliColors.textSecondary(context),
                                  height: 1.45,
                                ),
                              ),
                              SizedBox(height: Spacing.lg),
                              _StepItem(
                                step: '1',
                                title: 'Elige la categoría correcta',
                                body:
                                    'Ayuda a que aparezcan proveedores del rubro adecuado.',
                              ),
                              SizedBox(height: Spacing.md),
                              _StepItem(
                                step: '2',
                                title: 'Describe el trabajo con detalle',
                                body:
                                    'Explica qué necesitas, si hay urgencia y si tienes materiales.',
                              ),
                              SizedBox(height: Spacing.md),
                              _StepItem(
                                step: '3',
                                title: 'Agrega presupuesto y comuna',
                                body:
                                    'Eso filtra mejor las propuestas y facilita la coordinación.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  InputDecoration _inputDecoration(IconData prefixIcon, {String? hint}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: CliColors.textSecondary(context), size: 20),
      filled: true,
      fillColor: CliColors.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // Mensajes de error largos ("El título es obligatorio" es corto,
      // pero por consistencia con otros formularios) no deben truncarse.
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: CliColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: CliColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: CliColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }
}

class _FormGroupContainer extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormGroupContainer({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CliSectionHeader(title: title),
        const SizedBox(height: Spacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: CliColors.surface(context),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              color: CliColors.border(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final String title;
  final String body;
  const _StepItem({
    required this.step,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CliColors.surface(context),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: CliColors.border(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CliColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Center(
              child: Text(
                step,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: CliColors.accent,
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
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: CliColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: CliColors.textSecondary(context),
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
