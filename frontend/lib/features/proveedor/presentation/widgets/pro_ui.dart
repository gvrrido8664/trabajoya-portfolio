import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/shared/theme/pro_palette.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';
import 'package:trabajoya_app/utils/colors.dart';
export 'package:trabajoya_app/shared/theme/pro_palette.dart';

/// Scaffold con el fondo claro ("orden de trabajo") y un AppBar coherente (opcional).
class ProScaffold extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? appBarBottom;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showAppBar;

  const ProScaffold({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.appBarBottom,
    required this.body,
    this.floatingActionButton,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.bg,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: ProColors.bg,
              surfaceTintColor: Colors.transparent,
              foregroundColor: ProColors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: leading,
              titleSpacing: leading == null ? 20 : null,
              title: title == null
                  ? null
                  : Text(
                      title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ProColors.textPrimary,
                        
                        letterSpacing: -0.4,
                      ),
                    ),
              actions: actions,
              bottom: appBarBottom,
            )
          : null,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

/// Header con saludo personalizado y fondo claro coherente.
class ProHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final Widget? trailing;

  const ProHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: ProColors.bg,
        border: Border(bottom: BorderSide(color: ProColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    
                    fontWeight: FontWeight.w700,
                    color: ProColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    
                    color: ProColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Tarjeta de métrica (valor grande + etiqueta + icono con halo de acento).
class ProMetricTile extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? accent;

  const ProMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  @override
  State<ProMetricTile> createState() => _ProMetricTileState();
}

class _ProMetricTileState extends State<ProMetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.accent ?? ProColors.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: ProColors.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              color: _isHovered ? c.withValues(alpha: 0.35) : ProColors.border,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: c.withValues(alpha: 0.06),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_isHovered ? 9 : 7),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: _isHovered ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(widget.icon, size: 16, color: c),
              ),
              const SizedBox(height: 12),
              Text(
                widget.value,
                style: const TextStyle(
                  
                  fontWeight: FontWeight.w700,
                  color: ProColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  
                  color: ProColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección con título y acción opcional ("Ver todas").
class ProSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: ProColors.accent,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            
            fontWeight: FontWeight.w700,
            color: ProColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const Spacer(),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: ProColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle( fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta base del proveedor con el motivo compartido de orden de trabajo.
class ProCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final Color? glowColor;

  const ProCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      onTap: onTap,
      padding: padding,
      color: ProColors.surface,
      child: child,
    );
  }
}

/// Pastilla de estado coloreada.
class ProStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const ProStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Etiqueta pequeña (icono + texto) sobre fondo tenue. Para precio, ubicación…
class ProTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const ProTag({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? ProColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: ProColors.elevated,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: ProColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              
              fontWeight: FontWeight.w600,
              color: c == ProColors.textSecondary ? ProColors.textPrimary : c,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar con iniciales y halo de acento.
class ProAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double radius;
  final Color? accent;

  const ProAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.radius = 22,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? ProColors.accent;
    final letter = (name != null && name!.isNotEmpty)
        ? name![0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.4), width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: c.withValues(alpha: 0.14),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Text(
                letter,
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w700,
                  fontSize: radius * 0.7,
                ),
              )
            : null,
      ),
    );
  }
}

/// Estado vacío oscuro y elegante.
class ProEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: ProColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: ProColors.border),
              ),
              child: Icon(icon, size: 44, color: ProColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                
                fontWeight: FontWeight.w700,
                color: ProColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                
                color: ProColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ProButton(label: actionLabel!, onPressed: onAction, width: 200),
            ],
          ],
        ),
      ),
    );
  }
}

/// Spinner centrado con el acento.
class ProLoading extends StatelessWidget {
  final bool dark;
  const ProLoading({super.key, this.dark = true});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: dark ? ProColors.accent : AppTheme.primary,
        strokeWidth: 2.6,
      ),
    );
  }
}

/// Paleta adaptable por rol: oscura ("premium") para el proveedor, clara para
/// el resto. Fuente única para todas las pantallas compartidas
/// (perfil, contrataciones, detalle de solicitud/contratación, chat).
@Deprecated('Usar AppColors y Theme.of(context) directamente')
class RolePalette {
  @Deprecated('El tema por rol fue retirado')
  final bool dark;
  final Color scaffold;
  final Color bg;
  final Color surface;
  final Color surfaceHi;
  final Color elevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color secondary;
  final Color success;
  final Color danger;
  final Color field;

  /// Color para el contraste sobre un botón de acento.
  final Color onAccent;

  /// Sombra de tarjeta (solo en claro; en oscuro se usa borde).
  final List<BoxShadow>? cardShadow;

  /// Tema único claro para ambos roles ("orden de trabajo"). El campo [dark]
  /// se conserva solo por compatibilidad de firma con los call sites
  /// existentes (contratacion_detail_screen.dart, mis_contrataciones_screen.dart).
  RolePalette(this.dark, BuildContext context)
    : scaffold = AppColors.paper,
      bg = AppColors.paper,
      surface = Theme.of(context).colorScheme.surface,
      surfaceHi = Theme.of(context).colorScheme.surface,
      elevated = Theme.of(context).colorScheme.surfaceContainerHighest,
      border = Theme.of(context).colorScheme.outline,
      textPrimary = Theme.of(context).colorScheme.onSurface,
      textSecondary = Theme.of(context).colorScheme.onSurfaceVariant,
      textMuted = Theme.of(context).colorScheme.onSurfaceVariant,
      accent = AppColors.blueprint,
      secondary = AppTheme.secondary,
      success = AppTheme.success,
      danger = AppTheme.danger,
      field = Theme.of(context).colorScheme.surface,
      onAccent = Colors.white,
      cardShadow = null;

  /// Construye la paleta según el rol del usuario.
  factory RolePalette.of(String? rol, BuildContext context) =>
      RolePalette(rol == 'proveedor', context);

  Color statusColor(String s) => AppTheme.statusColor(s);
}

/// Tarjeta de acceso rápido (icono + label) para la landing del proveedor.
class ProQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  const ProQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? ProColors.accent;
    return Material(
      color: ProColors.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: ProColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(icon, size: 20, color: c),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  
                  fontWeight: FontWeight.w600,
                  color: ProColors.textPrimary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón estandarizado del tier Proveedor con 52px de altura y bordes `Radii.md`.
class ProButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool isOutline;
  final bool isCta;
  final bool isDanger;
  final IconData? icon;
  final double? width;
  final bool compact;

  const ProButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.isOutline = false,
    this.isCta = false,
    this.isDanger = false,
    this.icon,
    this.width,
    this.compact = false,
  });

  @override
  State<ProButton> createState() => _ProButtonState();
}

class _ProButtonState extends State<ProButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.loading;

    double scale = 1.0;
    if (isEnabled) {
      if (_isPressed) {
        scale = 0.96;
      } else if (_isHovered) {
        scale = 1.02;
      }
    }

    final Color fg = widget.isOutline
        ? (widget.isDanger ? ProColors.danger : ProColors.accent)
        : (widget.isDanger ? ProColors.onDanger : ProColors.onAccent);

    final Size minSize = widget.compact
        ? const Size(0, 44)
        : Size(widget.width ?? double.infinity, 52);

    final buttonStyle = widget.isOutline
        ? OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(
              color: widget.isDanger
                  ? ProColors.danger.withValues(alpha: 0.3)
                  : ProColors.border,
            ),
            minimumSize: minSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          )
        : FilledButton.styleFrom(
            backgroundColor: widget.isDanger
                ? ProColors.danger
                : AppColors.rust,
            foregroundColor: fg,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          );

    final Widget content;
    if (widget.loading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (widget.icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
        ],
      );
    } else {
      content = Text(widget.label);
    }

    Widget button = widget.isOutline
        ? OutlinedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            style: buttonStyle,
            child: content,
          )
        : FilledButton(
            onPressed: widget.loading ? null : widget.onPressed,
            style: buttonStyle,
            child: content,
          );

    if (isEnabled) {
      button = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: button,
          ),
        ),
      );
    }

    return button;
  }
}

/// Helper para estandarizar campos de texto con el look oscuro SaaS.
class ProInput {
  ProInput._();

  static InputDecoration decoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? labelText,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: ProColors.surfaceHi,
      hintStyle: const TextStyle(color: ProColors.textSecondary, ),
      labelStyle: const TextStyle(color: ProColors.textSecondary, ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: ProColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: ProColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: ProColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: ProColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: ProColors.danger, width: 2),
      ),
      errorStyle: const TextStyle(color: ProColors.danger),
    );
  }
}

/// Bloque de carga animada (skeleton) adaptado a los colores oscuros de Pro
/// y respetuoso con la opción de reduced-motion.
class ProSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const ProSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final baseColor = ProColors.surface;
    final highlightColor = ProColors.surfaceHi;

    final boxDecoration = BoxDecoration(
      color: ProColors.surface,
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
        decoration: boxDecoration.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Badge de estado adaptativo para el flujo del proveedor, hereda de StatusBadge.
class ProStatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final EdgeInsets? padding;

  const ProStatusBadge({
    super.key,
    required this.status,
    this.label,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge.forStatus(status, label: label, padding: padding);
  }
}
