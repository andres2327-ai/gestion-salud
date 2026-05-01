import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _apellidoCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _empresaCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _ciudadCtrl = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(color: colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
