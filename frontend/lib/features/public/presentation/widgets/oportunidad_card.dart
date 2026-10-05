import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/solicitudes/data/models/solicitud_model.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class OportunidadItem {
  final String titulo;
  final String categoria;
  final String ubicacion;
  final String presupuesto;
  final String urgencia;
  final String clienteInicial;

  const OportunidadItem({
    required this.titulo,
    required this.categoria,
    required this.ubicacion,
    required this.presupuesto,
    required this.urgencia,
    required this.clienteInicial,
  });
}

const _oportunidadesHardcoded = [
  OportunidadItem(
    titulo: 'Instalación de termosifón',
    categoria: 'Plomería',
    ubicacion: 'Providencia, Santiago',
    presupuesto: '\$45.000 - \$80.000',
    urgencia: 'Urgente',
    clienteInicial: 'C',
  ),
  OportunidadItem(
    titulo: 'Cableado para隔 ampli',
    categoria: 'Electricidad',
    ubicacion: 'Las Condes, Santiago',
    presupuesto: '\$60.000 - \$120.000',
    urgencia: 'Esta semana',
    clienteInicial: 'R',
  ),
  OportunidadItem(
    titulo: 'Pintura de departamento',
    categoria: 'Pintura',
    ubicacion: 'Ñuñoa, Santiago',
    presupuesto: '\$200.000 - \$350.000',
    urgencia: ' Flexible',
    clienteInicial: 'M',
  ),
  OportunidadItem(
    titulo: 'Desatoro de alcantarillado',
    categoria: 'Plomería',
    ubicacion: 'La Florida, Santiago',
    presupuesto: '\$30.000 - \$55.000',
    urgencia: 'Urgente',
    clienteInicial: 'P',
  ),
  OportunidadItem(
    titulo: 'Instalación de aire Split',
    categoria: 'Aire Acondicionado',
    ubicacion: 'Vitacura, Santiago',
    presupuesto: '\$80.000 - \$150.000',
    urgencia: 'Esta semana',
    clienteInicial: 'A',
  ),
];

class OportunidadCard extends StatelessWidget {
  final OportunidadItem oportunidad;
  final VoidCallback? onPostular;

  const OportunidadCard({
    super.key,
    required this.oportunidad,
    this.onPostular,
  });

  Color get _urgenciaColor {
    if (oportunidad.urgencia.contains('Urgente')) return AppTheme.danger;
    if (oportunidad.urgencia.contains('Esta')) return AppTheme.secondary;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                  child: Text(
                    oportunidad.clienteInicial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oportunidad.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Solicitado por cliente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _urgenciaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    oportunidad.urgencia,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _urgenciaColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    oportunidad.categoria,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.location_on, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    oportunidad.ubicacion,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 16,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Presupuesto: ${oportunidad.presupuesto}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
                const Spacer(),
                if (onPostular != null)
                  TextButton(
                    onPressed: onPostular,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Text('Ver más'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OportunidadList extends StatefulWidget {
  final bool isHorizontal;
  final void Function(OportunidadItem)? onPostular;
  final List<Solicitud>? solicitudes;

  const OportunidadList({
    super.key,
    this.isHorizontal = false,
    this.onPostular,
    this.solicitudes,
  });

  @override
  State<OportunidadList> createState() => _OportunidadListState();
}

class _OportunidadListState extends State<OportunidadList> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  List<OportunidadItem> get _items {
    if (widget.solicitudes != null && widget.solicitudes!.isNotEmpty) {
      return widget.solicitudes!.map((s) {
        final clienteInicial = (s.clienteNombre?.isNotEmpty == true)
            ? s.clienteNombre![0].toUpperCase()
            : '?';
        return OportunidadItem(
          titulo: s.titulo,
          categoria: s.categoriaNombre ?? '',
          ubicacion: s.ubicacionTexto ?? '',
          presupuesto: s.presupuestoMax != null
              ? '\$${s.presupuestoMax!.toStringAsFixed(0)}'
              : 'A convenir',
          urgencia: 'Abierta',
          clienteInicial: clienteInicial,
        );
      }).toList();
    }
    return _oportunidadesHardcoded;
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHorizontal) {
      return _buildCarousel();
    }
    return Column(
      children: _items
          .map(
            (o) => OportunidadCard(
              oportunidad: o,
              onPostular: () => widget.onPostular?.call(o),
            ),
          )
          .toList(),
    );
  }

  Color _urgenciaColor(String urgencia) {
    if (urgencia.contains('Urgente')) return AppTheme.danger;
    if (urgencia.contains('Esta')) return AppTheme.secondary;
    return AppTheme.textSecondary;
  }

  Widget _buildCarousel() {
    final items = _items;
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = 260;
        const gap = 12;
        final cardsPerPage = ((constraints.maxWidth + gap) / (cardWidth + gap))
            .floor()
            .clamp(1, items.length);
        final totalPages = (items.length / cardsPerPage).ceil();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  if (totalPages > 1)
                    _arrowButton(
                      icon: Icons.chevron_left,
                      onPressed: _currentPage > 0
                          ? () => _pageCtrl.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                          : null,
                    ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: totalPages,
                      itemBuilder: (context, pageIndex) {
                        final start = pageIndex * cardsPerPage;
                        final end = (start + cardsPerPage).clamp(
                          0,
                          items.length,
                        );
                        final pageItems = items.sublist(start, end);

                        return Row(
                          children: [
                            for (final item in pageItems)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: gap / 2,
                                    right: gap / 2,
                                  ),
                                  child: _buildCard(item),
                                ),
                              ),
                            if (pageItems.length < cardsPerPage)
                              for (
                                int i = 0;
                                i < cardsPerPage - pageItems.length;
                                i++
                              )
                                const Spacer(),
                          ],
                        );
                      },
                    ),
                  ),
                  if (totalPages > 1)
                    _arrowButton(
                      icon: Icons.chevron_right,
                      onPressed: _currentPage < totalPages - 1
                          ? () => _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                          : null,
                    ),
                ],
              ),
            ),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 20 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        color: _currentPage == i
                            ? AppTheme.primary
                            : AppTheme.border,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _arrowButton({required IconData icon, VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Icon(icon),
        tooltip: icon == Icons.chevron_left ? 'Anterior' : 'Siguiente',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.surface,
          side: BorderSide(color: AppTheme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        ),
      ),
    );
  }

  Widget _buildCard(OportunidadItem oportunidad) {
    final urgColor = _urgenciaColor(oportunidad.urgencia);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  oportunidad.clienteInicial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  oportunidad.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  oportunidad.categoria,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: urgColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  oportunidad.urgencia.trim(),
                  style: TextStyle(
                    fontSize: 10,
                    color: urgColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            oportunidad.presupuesto,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 11,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  oportunidad.ubicacion,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
