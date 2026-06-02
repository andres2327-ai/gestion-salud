// lib/ui/prestamo_solicitud_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/prestamo_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';

class PrestamoSolicitudScreen extends ConsumerStatefulWidget {
  const PrestamoSolicitudScreen({super.key});

  @override
  ConsumerState<PrestamoSolicitudScreen> createState() =>
      _PrestamoSolicitudScreenState();
}

class _PrestamoSolicitudScreenState
    extends ConsumerState<PrestamoSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final perfil = ref.read(usuarioActualProvider);
      if (perfil != null) {
        ref
            .read(prestamoControllerProvider.notifier)
            .escucharMisPrestamos(perfil.uid);
      }
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    if (!_formKey.currentState!.validate()) return;

    final perfil = ref.read(usuarioActualProvider);
    if (perfil == null) return;

    final ok = await ref.read(prestamoControllerProvider.notifier).solicitar(
          usuarioUid: perfil.uid,
          nombreUsuario: perfil.nombre,
          rol: perfil.rol.name,
          monto: double.parse(_montoCtrl.text.trim()),
          motivo: _motivoCtrl.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      appSnackbar(context, 'Solicitud enviada. El admin la revisará pronto.');
      _montoCtrl.clear();
      _motivoCtrl.clear();
    } else {
      final error = ref.read(prestamoControllerProvider).error;
      appSnackbar(
        context,
        error ?? 'No se pudo enviar la solicitud',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(prestamoControllerProvider);
    final fmt = NumberFormat('#,###', 'es_CO');
    final amberColor = isDark ? AppColors.darkAmber : AppColors.amber;
    final amberBg = isDark ? AppColors.darkAmber50 : AppColors.amber50;

    final pendientes = state.prestamos
        .where((p) => p.estado == EstadoPrestamo.pendiente)
        .toList();
    final aprobados = state.prestamos
        .where((p) =>
            p.estado == EstadoPrestamo.aprobado && p.saldoPendiente > 0)
        .toList();
    final tieneActivos = pendientes.isNotEmpty || aprobados.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Préstamo'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ── Info banner ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: amberBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: amberColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Los préstamos aprobados se descuentan automáticamente de tu próximo pago de quincena.',
                    style: TextStyle(
                      fontSize: 13,
                      color: amberColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Préstamos activos ────────────────────────────────────
          if (tieneActivos) ...[
            const SizedBox(height: 20),
            Text(
              'PRÉSTAMOS ACTIVOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            ...pendientes.map(
              (p) => _PrestamoCard(p: p, fmt: fmt, isDark: isDark, cs: cs),
            ),
            ...aprobados.map(
              (p) => _PrestamoCard(p: p, fmt: fmt, isDark: isDark, cs: cs),
            ),
          ],

          const SizedBox(height: 24),

          // ── Formulario ────────────────────────────────────────────
          Text(
            'NUEVA SOLICITUD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto del préstamo',
                    prefixText: '\$ ',
                    hintText: '100000',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Ingresa un monto válido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _motivoCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Motivo o descripción',
                    hintText:
                        'Explica brevemente para qué necesitas el préstamo',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 10)
                          ? 'Escribe al menos 10 caracteres'
                          : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: state.cargando ? null : _solicitar,
                    icon: state.cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Enviar Solicitud'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de préstamo existente ─────────────────────────────────────────────

class _PrestamoCard extends StatelessWidget {
  final PrestamoModel p;
  final NumberFormat fmt;
  final bool isDark;
  final ColorScheme cs;

  const _PrestamoCard({
    required this.p,
    required this.fmt,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon, label) = switch (p.estado) {
      EstadoPrestamo.pendiente => (
          isDark ? AppColors.darkAmber : AppColors.amber,
          isDark ? AppColors.darkAmber50 : AppColors.amber50,
          Icons.hourglass_empty_rounded,
          'Pendiente',
        ),
      EstadoPrestamo.aprobado => (
          isDark ? AppColors.darkJade : AppColors.brandJade,
          isDark ? AppColors.darkJade50 : AppColors.lightJade50,
          Icons.check_circle_outline_rounded,
          'Aprobado',
        ),
      EstadoPrestamo.rechazado => (
          isDark ? AppColors.darkCoral : AppColors.coral,
          isDark ? AppColors.darkCoral50 : AppColors.coral50,
          Icons.cancel_outlined,
          'Rechazado',
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${fmt.format(p.monto)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  p.motivo,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (p.estado == EstadoPrestamo.aprobado && p.saldoPendiente > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Saldo: \$${fmt.format(p.saldoPendiente)}',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
