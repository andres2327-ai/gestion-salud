// lib/ui/admin_prestamos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/prestamo_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';

class AdminPrestamosScreen extends ConsumerStatefulWidget {
  const AdminPrestamosScreen({super.key});

  @override
  ConsumerState<AdminPrestamosScreen> createState() =>
      _AdminPrestamosScreenState();
}

class _AdminPrestamosScreenState extends ConsumerState<AdminPrestamosScreen> {
  String? _procesandoId;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(prestamoControllerProvider.notifier).escucharPendientes(),
    );
  }

  Future<void> _resolver(PrestamoModel p, bool aprobado) async {
    final admin = ref.read(usuarioActualProvider);
    if (admin == null) return;

    setState(() => _procesandoId = p.prestamoId);

    final ok = await ref.read(prestamoControllerProvider.notifier).resolver(
          prestamoId: p.prestamoId,
          aprobado: aprobado,
          adminUid: admin.uid,
        );

    if (!mounted) return;
    setState(() => _procesandoId = null);

    appSnackbar(
      context,
      ok
          ? (aprobado ? 'Préstamo aprobado' : 'Préstamo rechazado')
          : (ref.read(prestamoControllerProvider).error ?? 'Error'),
      error: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(prestamoControllerProvider);
    final fmt = NumberFormat('#,###', 'es_CO');
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    final cargandoInicial = state.cargando && state.prestamos.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Préstamos'),
            if (state.prestamos.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: jadeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.prestamos.length}',
                  style: TextStyle(
                    color: jadeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: cargandoInicial
          ? Center(child: CircularProgressIndicator(color: jadeColor))
          : state.prestamos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkInk100
                              : AppColors.lightInk100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: cs.onSurfaceVariant,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sin solicitudes pendientes',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.prestamos.length,
                  itemBuilder: (_, i) {
                    final p = state.prestamos[i];
                    final isAsesora = p.rol == 'asesora';
                    final accentColor = isAsesora
                        ? (isDark ? AppColors.darkViolet : AppColors.violet)
                        : jadeColor;
                    final accentBg = isAsesora
                        ? (isDark ? AppColors.darkViolet50 : AppColors.violet50)
                        : jadeBg;
                    final procesando = _procesandoId == p.prestamoId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accentColor.withAlpha(60),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 40 : 6),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──────────────────────────────────
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: accentBg,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  isAsesora
                                      ? Icons.storefront_outlined
                                      : Icons.payments_outlined,
                                  color: accentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nombreUsuario,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    Text(
                                      isAsesora ? 'Asesora' : 'Cobrador',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${fmt.format(p.monto)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Motivo ──────────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkInk100
                                  : AppColors.lightInk100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.format_quote_rounded,
                                  size: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    p.motivo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Botones ─────────────────────────────────
                          procesando
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _procesandoId != null
                                            ? null
                                            : () => _resolver(p, false),
                                        icon: const Icon(
                                            Icons.close_rounded,
                                            size: 16),
                                        label: const Text('Rechazar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDark
                                              ? AppColors.darkCoral
                                              : AppColors.coral,
                                          side: BorderSide(
                                            color: isDark
                                                ? AppColors.darkCoral
                                                : AppColors.coral,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _procesandoId != null
                                            ? null
                                            : () => _resolver(p, true),
                                        icon: const Icon(
                                            Icons.check_rounded,
                                            size: 16),
                                        label: const Text('Aprobar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: jadeColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
