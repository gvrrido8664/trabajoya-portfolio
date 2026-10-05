import 'package:flutter/material.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';
import 'package:trabajoya_app/shared/widgets/skeleton_loader.dart';
import 'package:trabajoya_app/shared/widgets/servicio_card.dart';

/// Home del cliente: buscar y descubrir servicios.
///
/// Aplica varias heurísticas de Nielsen:
///  - #1 Visibilidad del estado: skeletons durante la carga, estados de error.
///  - #6 Reconocer antes que recordar: búsquedas recientes + chips de categoría.
///  - #8 Diseño minimalista: barra de búsqueda anclada, espacios en blanco.
///  - #9 Recuperación de errores: EmptyStateWidget con "Reintentar".
class ServiciosListScreen extends StatefulWidget {
  const ServiciosListScreen({super.key});

  @override
  State<ServiciosListScreen> createState() => _ServiciosListScreenState();
}

class _ServiciosListScreenState extends State<ServiciosListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Búsquedas recientes (en memoria de sesión) — heurística #6.
  final List<String> _busquedasRecientes = [];

  String _query = '';
  String? _categoriaSeleccionada; // id de categoría activa
  bool _buscandoCercanos = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ServiciosProvider>();
      provider.cargarServicios();
      provider.cargarCategorias();
    });
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;
    if (pos >= max - 200) {
      final provider = context.read<ServiciosProvider>();
      if (provider.hasMore && !provider.loadingMore) {
        provider.cargarMas(categoriaPadreId: _categoriaSeleccionada);
      }
    }
  }

  Future<void> _recargar() async {
    await context.read<ServiciosProvider>().cargarServicios(
      categoriaPadreId: _categoriaSeleccionada,
    );
  }

  void _registrarBusqueda(String texto) {
    final q = texto.trim();
    if (q.isEmpty) return;
    setState(() {
      _query = q;
      _busquedasRecientes.remove(q);
      _busquedasRecientes.insert(0, q);
      if (_busquedasRecientes.length > 5) {
        _busquedasRecientes.removeLast();
      }
    });
    _searchFocus.unfocus();
  }

  void _seleccionarCategoria(String? id) {
    setState(() => _categoriaSeleccionada = id);
    context.read<ServiciosProvider>().cargarServicios(categoriaPadreId: id);
  }

  /// "Cerca de ti": pide ubicación y busca servicios cercanos.
  /// Heurística #9: ante un fallo de permisos/GPS, informamos con claridad.
  Future<void> _buscarCercanos() async {
    setState(() => _buscandoCercanos = true);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ServiciosProvider>();
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado');
      }
      final pos = await Geolocator.getCurrentPosition();
      await provider.buscarCercanos(
        pos.latitude,
        pos.longitude,
        categoriaPadreId: _categoriaSeleccionada,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos obtener tu ubicación. Revisa los permisos del GPS.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _buscandoCercanos = false);
    }
  }

  /// Filtrado en cliente para feedback instantáneo (sin esperar a la red).
  List<Servicio> _filtrar(List<Servicio> servicios) {
    if (_query.isEmpty) return servicios;
    final q = _query.toLowerCase();
    return servicios
        .where(
          (s) =>
              s.titulo.toLowerCase().contains(q) ||
              s.descripcion.toLowerCase().contains(q) ||
              (s.categoriaNombre?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiciosProvider>();
    final servicios = _filtrar(provider.servicios);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildChips(provider.categoriasRaiz),
            Expanded(child: _buildBody(provider, servicios)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barra de búsqueda + búsquedas recientes (heurística #6, #8)
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    final mostrarRecientes =
        _searchFocus.hasFocus &&
        _searchCtrl.text.isEmpty &&
        _busquedasRecientes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onSubmitted: _registrarBusqueda,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'Buscar gasfíter, electricista, jardinero…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Limpiar',
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          if (mostrarRecientes)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final q in _busquedasRecientes)
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(q),
                        onPressed: () {
                          _searchCtrl.text = q;
                          _registrarBusqueda(q);
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chips de categorías + "Cerca de ti" (heurística #2, #6)
  // ---------------------------------------------------------------------------
  Widget _buildChips(List<Categoria> categorias) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ActionChip(
            avatar: _buscandoCercanos
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: const Text('Cerca de ti'),
            onPressed: _buscandoCercanos ? null : _buscarCercanos,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Todas'),
            selected: _categoriaSeleccionada == null,
            onSelected: (_) => _seleccionarCategoria(null),
          ),
          for (final c in categorias) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(c.nombre),
              selected: _categoriaSeleccionada == c.id,
              onSelected: (_) => _seleccionarCategoria(
                _categoriaSeleccionada == c.id ? null : c.id,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Cuerpo: skeleton / error / vacío / lista (heurística #1, #9)
  // ---------------------------------------------------------------------------
  Widget _buildBody(ServiciosProvider provider, List<Servicio> servicios) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final cross = isDesktop ? (width ~/ 320).clamp(2, 5) : 1;

    return DelayedLoader(
      loading: provider.loading,
      loader: isDesktop
          ? SkeletonServicioGrid(crossAxisCount: cross)
          : const SkeletonServicioList(),
      child: _buildContent(provider, servicios, isDesktop, cross),
    );
  }

  Widget _buildContent(
    ServiciosProvider provider,
    List<Servicio> servicios,
    bool isDesktop,
    int cross,
  ) {

    if (provider.error != null) {
      return EmptyStateWidget(
        icon: Icons.cloud_off,
        title: 'No pudimos cargar los servicios',
        message: provider.error,
        actionLabel: 'Reintentar',
        onAction: _recargar,
        variant: EmptyStateVariant.error,
      );
    }

    if (servicios.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: _query.isEmpty
            ? 'No hay servicios disponibles'
            : 'Sin resultados para "$_query"',
        message: _query.isEmpty
            ? 'Vuelve a intentarlo más tarde.'
            : 'Prueba con otra palabra o categoría.',
      );
    }

    if (isDesktop) {
      return RefreshIndicator(
        onRefresh: _recargar,
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: servicios.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == servicios.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: provider.loadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                ),
              );
            }
            return ServicioCardShared(
              servicio: servicios[index],
              onTap: () => context.push('/servicio/${servicios[index].id}'),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _recargar,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: servicios.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == servicios.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: provider.loadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }
          return ServicioCardShared(
            servicio: servicios[index],
            onTap: () => context.push('/servicio/${servicios[index].id}'),
          );
        },
      ),
    );
  }
}

/// Tarjeta de servicio (M3) — heurística #4 consistencia.
