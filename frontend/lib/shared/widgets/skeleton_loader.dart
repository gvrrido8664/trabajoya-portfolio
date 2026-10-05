import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

/// Bloque base con efecto shimmer, adaptado a light/dark.
///
/// Respeta la accesibilidad de "Reduced Motion" deteniendo la animación
/// si el sistema lo solicita (se renderiza estático con el color base).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final baseColor = dark ? Colors.white.withValues(alpha: 0.08) : AppColors.paper;
    final highlightColor = dark ? Colors.white.withValues(alpha: 0.16) : AppColors.card;

    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(Radii.md),
    );

    if (disableAnimations) {
      return Container(
        width: width,
        height: height,
        decoration: boxDecoration.copyWith(color: baseColor),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: boxDecoration,
      ),
    );
  }
}

/// Contenedor de compatibilidad legacy que delega a [SkeletonBox].
class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height ?? 16,
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    );
  }
}

/// Evita el parpadeo (flicker) retrasando la aparición del loader.
/// Si la operación asíncrona termina antes de [delay], el loader nunca se muestra.
class DelayedLoader extends StatefulWidget {
  final bool loading;
  final Widget child;
  final Widget loader;
  final Duration delay;

  const DelayedLoader({
    super.key,
    required this.loading,
    required this.child,
    required this.loader,
    this.delay = const Duration(milliseconds: 250),
  });

  @override
  State<DelayedLoader> createState() => _DelayedLoaderState();
}

class _DelayedLoaderState extends State<DelayedLoader> {
  bool _shouldShowLoader = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkLoading();
  }

  @override
  void didUpdateWidget(covariant DelayedLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading != widget.loading) {
      _checkLoading();
    }
  }

  void _checkLoading() {
    _timer?.cancel();
    if (widget.loading) {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          setState(() {
            _shouldShowLoader = true;
          });
        }
      });
    } else {
      setState(() {
        _shouldShowLoader = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: widget.loading
          ? (_shouldShowLoader
              ? KeyedSubtree(key: const ValueKey('loader'), child: widget.loader)
              : const SizedBox.shrink(key: ValueKey('empty')))
          : KeyedSubtree(key: const ValueKey('content'), child: widget.child),
    );
  }
}

/// Lista de tarjetas-esqueleto para un listado genérico.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  const SkeletonList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: itemCount,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(height: 18, width: 200),
            SizedBox(height: Spacing.md),
            SkeletonBox(height: 14, width: 140),
            SizedBox(height: Spacing.sm),
            SkeletonBox(height: 14, width: 90),
            SizedBox(height: Spacing.md),
            Row(
              children: [
                SkeletonBox(height: 24, width: 60, borderRadius: BorderRadius.all(Radius.circular(Radii.sm))),
                SizedBox(width: Spacing.sm),
                SkeletonBox(height: 24, width: 80, borderRadius: BorderRadius.all(Radius.circular(Radii.sm))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Esqueleto detallado para pantallas de detalle (servicio o solicitud).
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 100, height: 48, borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
              SizedBox(height: Spacing.xl2),
              SkeletonBox(height: 260, borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
              SizedBox(height: Spacing.xl2),
              SkeletonBox(height: 200, borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Esqueleto para tarjeta de Servicio.
class SkeletonServicioCard extends StatelessWidget {
  const SkeletonServicioCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SkeletonBox(width: 120, height: 80, borderRadius: BorderRadius.all(Radius.circular(Radii.sm))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 160, height: 18),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 100, height: 14),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SkeletonBox(width: 80, height: 16),
                      const Spacer(),
                      SkeletonBox(width: 60, height: 24, borderRadius: BorderRadius.all(Radius.circular(Radii.pill))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listado de skeletons de Servicio.
class SkeletonServicioList extends StatelessWidget {
  final int itemCount;

  const SkeletonServicioList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const SkeletonServicioCard(),
    );
  }
}

/// Grid de skeletons de Servicio.
class SkeletonServicioGrid extends StatelessWidget {
  final int crossAxisCount;
  final double mainAxisExtent;
  final int itemCount;

  const SkeletonServicioGrid({
    super.key,
    int? crossCount,
    int? crossAxisCount,
    this.mainAxisExtent = 320,
    this.itemCount = 9,
  }) : crossAxisCount = crossAxisCount ?? crossCount ?? 3;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const SkeletonServicioCard(),
    );
  }
}

/// Esqueleto para card general.
class SkeletonCardLoader extends StatelessWidget {
  const SkeletonCardLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 100, height: 12),
          SizedBox(height: 4),
          SkeletonBox(width: 180, height: 18),
          SizedBox(height: Spacing.lg),
          Column(
            children: [
              Row(
                children: [
                  SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
                  SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120, height: 14),
                        SizedBox(height: 6),
                        SkeletonBox(width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: Spacing.md),
              Row(
                children: [
                  SkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
                  SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 140, height: 14),
                        SizedBox(height: 6),
                        SkeletonBox(width: 60, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Esqueleto para listas detalladas (usado en mis solicitudes).
class SkeletonListLoader extends StatelessWidget {
  final int itemCount;

  const SkeletonListLoader({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: Spacing.lg),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 140, height: 18),
                  SkeletonBox(
                    width: 70,
                    height: 24,
                    borderRadius: BorderRadius.all(Radius.circular(Radii.pill)),
                  ),
                ],
              ),
              SizedBox(height: Spacing.md),
              SkeletonBox(width: 80, height: 14),
              SizedBox(height: Spacing.lg),
              Divider(height: 1),
              SizedBox(height: Spacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 90, height: 16),
                  SkeletonBox(width: 80, height: 36, borderRadius: BorderRadius.all(Radius.circular(Radii.md))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
