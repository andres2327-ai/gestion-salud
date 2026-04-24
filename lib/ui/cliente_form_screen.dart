// ui/forms/cliente_form_screen.dart
// Formulario de cliente del forms, adaptado al tema dark del proyecto

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

import 'custom_text_field.dart';

class ClienteFormScreen extends StatefulWidget {
  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _empresaCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _ciudadCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _SectionHeader(
              icon: Icons.person_rounded,
              title: 'Datos Personales',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'NOMBRE',
              hint: 'Ej: Carlos',
              controller: _nombreCtrl,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'APELLIDO',
              hint: 'Ej: Muñoz',
              controller: _apellidoCtrl,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'EMAIL',
              hint: 'ejemplo@correo.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'TELÉFONO',
              hint: 'Ej: 3001234567',
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.business_rounded,
              title: 'Información Adicional',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'EMPRESA (opcional)',
              hint: 'Nombre de la empresa',
              controller: _empresaCtrl,
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'DIRECCIÓN (opcional)',
              hint: 'Calle, número, apartamento',
              controller: _direccionCtrl,
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'CIUDAD (opcional)',
              hint: 'Ej: Bogotá',
              controller: _ciudadCtrl,
              prefixIcon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _empresaCtrl.dispose();
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }
}

// ── Widgets locales ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: AppColors.divider)),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isLoading ? AppColors.card : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.accentGlow,
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
