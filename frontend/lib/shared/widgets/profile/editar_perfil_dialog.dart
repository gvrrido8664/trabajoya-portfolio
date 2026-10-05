import 'package:trabajoya_app/core/constants/comunas.dart';
import 'package:trabajoya_app/shared/utils/unsaved_changes.dart';
import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class EditarPerfilDialog extends StatefulWidget {
  final AuthProvider auth;

  const EditarPerfilDialog({super.key, required this.auth});

  @override
  State<EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<EditarPerfilDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _comunaCtrl;
  final _actualPassCtrl = TextEditingController();
  final _nuevaPassCtrl = TextEditingController();
  final _actualPassFocus = FocusNode();
  final _nuevaPassFocus = FocusNode();
  bool _saving = false;
  bool _showPasswordSection = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;
  String? _regionSeleccionada;
  bool _dirty = false;
  void _markDirty() => _dirty = true;

  String _codigoPais = '+56';
  static const _paises = [
    {'code': '+56', 'flag': '🇨🇱', 'name': 'Chile'},
    {'code': '+54', 'flag': '🇦🇷', 'name': 'Argentina'},
    {'code': '+51', 'flag': '🇵🇪', 'name': 'Perú'},
    {'code': '+57', 'flag': '🇨🇴', 'name': 'Colombia'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'México'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brasil'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'EE.UU.'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'España'},
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.auth.usuario?.nombre);
    _apellidoCtrl = TextEditingController(text: widget.auth.usuario?.apellido);
    _comunaCtrl = TextEditingController(text: widget.auth.usuario?.comuna);

    if (widget.auth.usuario?.comuna != null) {
      for (final entry in ComunasChile.regionesYComunas.entries) {
        if (entry.value.contains(widget.auth.usuario!.comuna!)) {
          _regionSeleccionada = entry.key;
          break;
        }
      }
    }

    // Separar código de país del número guardado
    final telefonoRaw = widget.auth.usuario?.telefono ?? '';
    final codigoMatch = _paises.firstWhere(
      (p) => telefonoRaw.startsWith(p['code']!),
      orElse: () => _paises.first,
    );
    _codigoPais = codigoMatch['code']!;
    final soloNumero = telefonoRaw.startsWith(_codigoPais)
        ? telefonoRaw.substring(_codigoPais.length)
        : telefonoRaw;
    _telefonoCtrl = TextEditingController(text: soloNumero);

    for (final c in [_nombreCtrl, _apellidoCtrl, _telefonoCtrl, _comunaCtrl, _nuevaPassCtrl]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _comunaCtrl.dispose();
    _telefonoCtrl.dispose();
    _actualPassCtrl.dispose();
    _nuevaPassCtrl.dispose();
    _actualPassFocus.dispose();
    _nuevaPassFocus.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_saving) return;
    // Ni el backend ni este diálogo (usa TextField suelto, no Form) exigían
    // nombre/apellido no vacíos -- se podía guardar un perfil en blanco.
    if (_nombreCtrl.text.trim().isEmpty || _apellidoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y apellido son obligatorios')),
      );
      return;
    }
    setState(() => _saving = true);

    // 1. Guardar perfil
    final telefonoCompleto = _telefonoCtrl.text.trim().isEmpty
        ? ''
        : '$_codigoPais${_telefonoCtrl.text.trim()}';
    final okPerfil = await widget.auth.actualizarPerfil(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      telefono: telefonoCompleto,
      comuna: _comunaCtrl.text.trim(),
    );

    // 2. Cambiar contraseña si se llenaron los campos
    bool okPass = true;
    String? passError;
    if (_actualPassCtrl.text.isNotEmpty && _nuevaPassCtrl.text.isNotEmpty) {
      okPass = await widget.auth.changePassword(
        _actualPassCtrl.text,
        _nuevaPassCtrl.text,
      );
      if (!okPass) passError = widget.auth.error;
    }

    if (!mounted) return;
    Navigator.pop(context);

    String msg;
    bool success;
    if (okPerfil && okPass) {
      msg = _actualPassCtrl.text.isNotEmpty
          ? 'Perfil y contraseña actualizados.'
          : 'Perfil actualizado.';
      success = true;
    } else if (!okPerfil) {
      msg = widget.auth.error ?? 'Error al actualizar perfil.';
      success = false;
    } else {
      msg = passError ?? 'Error al cambiar contraseña.';
      success = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 400 fijo desbordaba en pantallas angostas (<400+64 de insetPadding) --
    // el campo Teléfono quedaba cortado a la mitad del último dígito.
    final maxDialogWidth = MediaQuery.sizeOf(context).width - 64;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmDiscardChanges(context, hasChanges: _dirty) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      title: const Text(
        'Editar perfil',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: maxDialogWidth < 400 ? maxDialogWidth : 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apellidoCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final codigoPaisField = SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_codigoPais),
                      initialValue: _codigoPais,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _paises
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p['code'],
                              child: Text(
                                '${p['flag']} ${p['code']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _codigoPais = v);
                      },
                    ),
                  );
                  final telefonoField = TextField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  );
                  // Con el selector de código de país (110px) al lado, el
                  // campo Teléfono se quedaba sin ancho suficiente para 9
                  // dígitos en diálogos angostos (<340px) y el último dígito
                  // se veía cortado. Se apila en vez de ir lado a lado.
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 340) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            codigoPaisField,
                            const SizedBox(height: 12),
                            telefonoField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          codigoPaisField,
                          const SizedBox(width: 10),
                          Expanded(child: telefonoField),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _regionSeleccionada,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Región'),
                items: ComunasChile.todasLasRegiones.map((region) {
                  return DropdownMenuItem(value: region, child: Text(region, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _regionSeleccionada = val;
                    _comunaCtrl.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: (_regionSeleccionada != null &&
                        ComunasChile.regionesYComunas[_regionSeleccionada!]!
                            .contains(_comunaCtrl.text))
                    ? _comunaCtrl.text
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Comuna o Ciudad'),
                items: (_regionSeleccionada != null
                        ? ComunasChile.regionesYComunas[_regionSeleccionada!]!
                        : <String>[])
                    .map((comuna) {
                  return DropdownMenuItem(
                    value: comuna,
                    child: Text(comuna, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: _regionSeleccionada == null
                    ? null
                    : (val) {
                        setState(() {
                          _comunaCtrl.text = val ?? '';
                        });
                      },
              ),

              // ── Sección de cambiar contraseña (expandible) ──
              const SizedBox(height: 8),
              const Divider(),
              InkWell(
                onTap: () => setState(
                  () => _showPasswordSection = !_showPasswordSection,
                ),
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cambiar contraseña',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        _showPasswordSection
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _showPasswordSection
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: _actualPassCtrl,
                      focusNode: _actualPassFocus,
                      obscureText: _obscureActual,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureActual
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          tooltip: _obscureActual
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () {
                            setState(() => _obscureActual = !_obscureActual);
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _actualPassFocus.requestFocus(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nuevaPassCtrl,
                      focusNode: _nuevaPassFocus,
                      obscureText: _obscureNueva,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNueva
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          tooltip: _obscureNueva
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () {
                            setState(() => _obscureNueva = !_obscureNueva);
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _nuevaPassFocus.requestFocus(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  if (await confirmDiscardChanges(context, hasChanges: _dirty) && context.mounted) {
                    Navigator.pop(context);
                  }
                },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    ),
    );
  }
}