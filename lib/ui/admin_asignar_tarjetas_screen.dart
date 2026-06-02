import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/tarjeta_model.dart';
import '../models/usuario_model.dart';
import '../core/theme/app_theme.dart';

class AdminAsignarTarjetasScreen extends ConsumerStatefulWidget {
  final UsuarioModel cobrador;

  const AdminAsignarTarjetasScreen({super.key, required this.cobrador});

  @override
  ConsumerState<AdminAsignarTarjetasScreen> createState() =>
      _AdminAsignarTarjetasScreenState();
}

class _AdminAsignarTarjetasScreenState
    extends ConsumerState<AdminAsignarTarjetasScreen> {
  late final Stream<List<TarjetaModel>> _tarjetasStream;
  final Set<String> _expandedZones = {};
  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    _tarjetasStream =
        ref.read(tarjetaServiceProvider).streamTodasLasTarjetas();
    Future.microtask(() {
      ref
          .read(cobroControllerProvider.notifier)
          .escucharAsignacionesCobrador(widget.cobrador.uid);
    });
  }

  Future<void> _asignarZona(
    String zona,
    List<TarjetaModel> tarjetasDeZona,
    Set<String> yaAsignadasIds,
  ) async {
    final perfil = ref.read(usuarioActualProvider);
    final sinAsignar =
        tarjetasDeZona.where((t) => !yaAsignadasIds.contains(t.tarjetaId));

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Asignar zona $zona'),
        content: Text(
          'Se asignarán ${sinAsignar.length} tarjeta(s) de $zona '
          'al cobrador ${widget.cobrador.nombre}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await ref.read(cobroControllerProvider.notifier).asignarZona(
      cobradorUid: widget.cobrador.uid,
      nombreCobrador: widget.cobrador.nombre,
      tarjetas: tarjetasDeZona,
      yaAsignadasIds: yaAsignadasIds,
      adminUid: perfil?.uid ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Zona $zona asignada a ${widget.cobrador.nombre}'
                : ref.read(cobroControllerProvider).error ?? 'Error',
          ),
          backgroundColor: ok ? AppColors.brandJade : AppColors.coral,
        ),
      );
    }
  }

  Future<void> _desasignarZona(
    String zona,
    List<TarjetaModel> tarjetasDeZona,
    Set<String> yaAsignadasIds,
    List<AsignacionModel> todasAsignaciones,
  ) async {
    final asignadasDeZona = todasAsignaciones
        .where(
          (a) => tarjetasDeZona.any((t) => t.tarjetaId == a.tarjetaId) && a.activa,
        )
        .toList();

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Quitar zona $zona'),
        content: Text(
          'Se quitarán ${asignadasDeZona.length} asignación(es) '
          'de $zona al cobrador ${widget.cobrador.nombre}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ids = asignadasDeZona.map((a) => a.asignacionId).toList();
    final ok = await ref
        .read(cobroControllerProvider.notifier)
        .desactivarAsignacionesBatch(ids);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Zona $zona quitada de ${widget.cobrador.nombre}'
                : ref.read(cobroControllerProvider).error ?? 'Error',
          ),
          backgroundColor: ok ? AppColors.amber : AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cobroState = ref.watch(cobroControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;

    final asignadasIds = cobroState.asignaciones
        .where((a) => a.activa)
        .map((a) => a.tarjetaId)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cobros por Zona', style: TextStyle(fontSize: 16)),
            Text(
              widget.cobrador.nombre,
              style: TextStyle(
                color: jadeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<TarjetaModel>>(
        stream: _tarjetasStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: jadeColor),
            );
          }

          final tarjetasActivas = (snapshot.data ?? [])
              .where((t) => t.estado == EstadoTarjeta.activa)
              .toList();

          final Map<String, List<TarjetaModel>> porZona = {};
          for (final zona in kZonas) {
            final lista = tarjetasActivas.where((t) => t.zona == zona).toList();
            if (lista.isNotEmpty) porZona[zona] = lista;
          }

          final sinZona = tarjetasActivas.where((t) => t.zona.isEmpty).toList();

          if (porZona.isEmpty && sinZona.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.map_outlined,
                      size: 26,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay tarjetas activas con zona asignada',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumen de asignaciones
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      color: jadeColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${asignadasIds.length} tarjeta(s) asignada(s) en total',
                      style: TextStyle(
                        color: jadeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ...porZona.entries.map(
                (entry) => _ZonaCard(
                  zona: entry.key,
                  tarjetas: entry.value,
                  asignadasIds: asignadasIds,
                  todasAsignaciones: cobroState.asignaciones,
                  expanded: _expandedZones.contains(entry.key),
                  fmt: fmt,
                  isDark: isDark,
                  onToggleExpand: () => setState(() {
                    if (_expandedZones.contains(entry.key)) {
                      _expandedZones.remove(entry.key);
                    } else {
                      _expandedZones.add(entry.key);
                    }
                  }),
                  onAsignar: () => _asignarZona(
                    entry.key,
                    entry.value,
                    asignadasIds,
                  ),
                  onDesasignar: () => _desasignarZona(
                    entry.key,
                    entry.value,
                    asignadasIds,
                    cobroState.asignaciones,
                  ),
                ),
              ),

              if (sinZona.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
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
                      Icon(
                        Icons.help_outline,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${sinZona.length} tarjeta(s) sin zona',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Card de zona ─────────────────────────────────────────────────────────────
class _ZonaCard extends StatelessWidget {
  final String zona;
  final List<TarjetaModel> tarjetas;
  final Set<String> asignadasIds;
  final List<AsignacionModel> todasAsignaciones;
  final bool expanded;
  final NumberFormat fmt;
  final bool isDark;
  final VoidCallback onToggleExpand;
  final VoidCallback onAsignar;
  final VoidCallback onDesasignar;

  const _ZonaCard({
    required this.zona,
    required this.tarjetas,
    required this.asignadasIds,
    required this.todasAsignaciones,
    required this.expanded,
    required this.fmt,
    required this.isDark,
    required this.onToggleExpand,
    required this.onAsignar,
    required this.onDesasignar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    final asignadasEnZona =
        tarjetas.where((t) => asignadasIds.contains(t.tarjetaId)).length;
    final total = tarjetas.length;
    final todasAsignadas = asignadasEnZona == total;
    final algunaAsignada = asignadasEnZona > 0;
    final progress = total > 0 ? asignadasEnZona / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: todasAsignadas
              ? jadeColor.withAlpha(128)
              : algunaAsignada
              ? jadeColor.withAlpha(100)
              : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
          width: todasAsignadas ? 1.5 : 1,
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
        children: [
          // ── Cabecera de zona ────────────────────────────────────────────
          InkWell(
            onTap: onToggleExpand,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: jadeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.map_rounded,
                          color: jadeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zona,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '$asignadasEnZona / $total tarjeta(s) asignada(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),

                  // Barra de progreso
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                      color: jadeColor,
                      minHeight: 6,
                    ),
                  ),

                  // Botones acción
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!todasAsignadas)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onAsignar,
                            icon: const Icon(Icons.add_task, size: 16),
                            label: Text(
                              algunaAsignada
                                  ? 'Asignar restantes (${total - asignadasEnZona})'
                                  : 'Asignar zona ($total)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      if (todasAsignadas)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: jadeBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: jadeColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Zona completamente asignada',
                                  style: TextStyle(
                                    color: jadeColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (algunaAsignada) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onDesasignar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.error,
                            side: BorderSide(color: cs.error),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Quitar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de tarjetas de la zona ─────────────────────────────────
          if (expanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
              indent: 16,
              endIndent: 16,
            ),
            ...tarjetas.map(
              (t) => _TarjetaRow(
                tarjeta: t,
                asignada: asignadasIds.contains(t.tarjetaId),
                fmt: fmt,
                isDark: isDark,
                cs: cs,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Fila de tarjeta individual ────────────────────────────────────────────────
class _TarjetaRow extends StatelessWidget {
  final TarjetaModel tarjeta;
  final bool asignada;
  final NumberFormat fmt;
  final bool isDark;
  final ColorScheme cs;

  const _TarjetaRow({
    required this.tarjeta,
    required this.asignada,
    required this.fmt,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            asignada
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            color: asignada
                ? jadeColor
                : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarjeta.nombreCliente,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Saldo: \$${fmt.format(tarjeta.saldoPendiente)}  ·  ${tarjeta.nombreAsesora}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (asignada)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: jadeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Asignada',
                style: TextStyle(
                  fontSize: 11,
                  color: jadeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
