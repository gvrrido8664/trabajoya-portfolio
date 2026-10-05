import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class BankInfoCard extends StatefulWidget {
  const BankInfoCard({super.key});

  @override
  State<BankInfoCard> createState() => _BankInfoCardState();
}

class _BankInfoCardState extends State<BankInfoCard> {
  bool _working = false;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountTypeController = TextEditingController();

  Future<void> _saveBankInfo() async {
    if (_working) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _working = true);

    try {
      String apiAccountType = 'vista';
      if (_accountTypeController.text == 'Cuenta Corriente') apiAccountType = 'corriente';
      if (_accountTypeController.text == 'Cuenta Vista' || _accountTypeController.text == 'Cuenta RUT') apiAccountType = 'vista';
      if (_accountTypeController.text == 'Cuenta de Ahorro') apiAccountType = 'ahorro';

      final apiClient = ApiClient();
      await apiClient.put(
        '/proveedores/me/banco',
        body: {
          'rut': _rutController.text,
          'bank_name': _bankNameController.text,
          'account_number': _accountNumberController.text,
          'account_type': apiAccountType,
        },
      );

      // Refrescar usuario
      if (!mounted) return;
      await context.read<AuthProvider>().checkAuth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos bancarios actualizados correctamente'),
        ),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar datos: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  @override
  void dispose() {
    _rutController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().usuario;
    if (user == null || !user.isProveedor) return const SizedBox.shrink();

    final isConfigured = user.mpConfigured;

    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: isConfigured && !_isEditing
          ? AppColors.success.withValues(alpha: 0.12)
          : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: isConfigured && !_isEditing
              ? AppColors.success.withValues(alpha: 0.3)
              : cs.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConfigured && !_isEditing
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.blueprintTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: isConfigured && !_isEditing
                        ? AppColors.success
                        : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuenta Bancaria',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConfigured && !_isEditing
                            ? 'Los pagos de tus clientes llegarán a tu cuenta bancaria al finalizar el trabajo.'
                            : 'Configura tu cuenta bancaria para recibir los pagos de tus clientes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isConfigured && !_isEditing) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Actualizar Datos'),
                ),
              ),
            ],
            if (!isConfigured || _isEditing) ...[
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _rutController,
                      decoration: const InputDecoration(
                        labelText: 'RUT',
                        hintText: '12345678-9',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
                      decoration: const InputDecoration(
                        labelText: 'Banco',
                        hintText: 'Ej. Banco Estado',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Banco Estado', child: Text('Banco Estado')),
                        DropdownMenuItem(value: 'Banco Santander', child: Text('Banco Santander')),
                        DropdownMenuItem(value: 'Banco de Chile', child: Text('Banco de Chile')),
                        DropdownMenuItem(value: 'BCI', child: Text('BCI')),
                        DropdownMenuItem(value: 'Scotiabank', child: Text('Scotiabank')),
                        DropdownMenuItem(value: 'Itaú', child: Text('Itaú')),
                        DropdownMenuItem(value: 'Banco Falabella', child: Text('Banco Falabella')),
                        DropdownMenuItem(value: 'Banco Ripley', child: Text('Banco Ripley')),
                        DropdownMenuItem(value: 'Tenpo', child: Text('Tenpo')),
                        DropdownMenuItem(value: 'Mach', child: Text('Mach')),
                        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                      ],
                      onChanged: (v) => _bankNameController.text = v ?? '',
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _accountTypeController.text.isNotEmpty ? _accountTypeController.text : null,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Cuenta',
                        hintText: 'Ej. Cuenta Corriente',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cuenta Corriente', child: Text('Cuenta Corriente')),
                        DropdownMenuItem(value: 'Cuenta Vista', child: Text('Cuenta Vista')),
                        DropdownMenuItem(value: 'Cuenta RUT', child: Text('Cuenta RUT')),
                        DropdownMenuItem(value: 'Cuenta de Ahorro', child: Text('Cuenta de Ahorro')),
                      ],
                      onChanged: (v) => _accountTypeController.text = v ?? '',
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Cuenta',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_isEditing && isConfigured)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _isEditing = false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                        if (_isEditing && isConfigured)
                          const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _working ? null : _saveBankInfo,
                            child: _working
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Guardar Datos Bancarios'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
