// lib/ui/admin_quincena_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/comision_model.dart';

class AdminQuincenaScreen extends ConsumerStatefulWidget {
  const AdminQuincenaScreen({super.key});

  @override
  ConsumerState<AdminQuincenaScreen> createState() => _AdminQuincenaScreenState();
}

class _AdminQuincenaScreenState extends ConsumerState<AdminQuincenaScreen> {
  final Set<String> _seleccionados = {};
  bool _pagando = false;

  // Filtros
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  TipoComision? _filtroTipo;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    // Usar stream igual que el resto de la app — Firestore entrega los datos
    // en cuanto la conexión/auth están listos, sin depender de timing.
    Future.microtask(() {
      ref.read(comisionControllerProvider.notifier).escucharComisionesPendientes();
    });
    _searchCtrl.addListener(() {
      setState(() => _busqueda = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pagarSeleccionados() async {
    if (_seleccionados.isEmpty) return;
    setState(() => _pagando = true);
    final ok = await ref
        .read(comisionControllerProvider.notifier)
        .marcarPagadas(_seleccionados.toList());
    if (ok) setState(() => _seleccionados.clear());
    if (mounted) setState(() => _pagando = false);
  }

  List<ComisionModel> _aplicarFiltros(List<ComisionModel> todas) {
    return todas.where((c) {
      final coincideTipo = _filtroTipo == null || c.tipo == _filtroTipo;
      final coincideBusqueda = _busqueda.isEmpty ||
          c.nombreUsuario.toLowerCase().contains(_busqueda) ||
          c.nombreCliente.toLowerCase().contains(_busqueda);
      return coincideTipo && coincideBusqueda;
    }).toList();
  }

  Map<String, List<ComisionModel>> _agruparPorUsuario(List<ComisionModel> lista) {
    final mapa = <String, List<ComisionModel>>{};
    for (final c in lista) {
      mapa.putIfAbsent(c.usuarioUid, () => []).add(c);
    }
    return mapa;
  }

  double _totalUsuario(List<ComisionModel> lista) =>
      lista.fold(0.0, (s, c) => s + c.montoComision);

  double _totalSeleccionado(List<ComisionModel> todas) => todas
      .where((c) => _seleccionados.contains(c.comisionId))
      .fold(0.0, (s, c) => s + c.montoComision);

  void _toggleUsuario(String uid, List<ComisionModel> lista) {
    setState(() {
      final ids = lista.map((c) => c.comisionId).toList();
      if (ids.every(_seleccionados.contains)) {
        _seleccionados.removeAll(ids);
      } else {
        _seleccionados.addAll(ids);
      }
    });
  }

  String _periodoActual() {
    final ahora = DateTime.now();
    final mes = DateFormat('MMMM yyyy', 'es_ES').format(ahora);
    if (ahora.day <= 15) {
      return '1–15 de $mes';
    } else {
      return '16–${DateFormat('d', 'es_ES').format(DateTime(ahora.year, ahora.month + 1, 0))} de $mes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Leer directamente del provider — se actualiza automáticamente por el stream
    final comisionState = ref.watch(comisionControllerProvider);
    final todas = comisionState.comisiones;
    final cargando = comisionState.cargando && todas.isEmpty;

    final filtradas = _aplicarFiltros(todas);
    final porUsuario = _agruparPorUsuario(filtradas);
    final hayFiltro = _filtroTipo != null || _busqueda.isNotEmpty;
    final totalGeneral = todas.fold(0.0, (s, c) => s + c.montoComision);
    final totalFiltrado = filtradas.fold(0.0, (s, c) => s + c.montoComision);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de Quincena'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: () => ref
                .read(comisionControllerProvider.notifier)
                .escucharComisionesPendientes(),
          ),
        ],
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // ── Resumen ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Período: ${_periodoActual()}',
                          style: textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '\$${fmt.format(hayFiltro ? totalFiltrado : totalGeneral)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (hayFiltro) ...[
                            const SizedBox(width: 6),
                            Text('(total: \$${fmt.format(totalGeneral)})',
                                style: textTheme.bodySmall),
                          ],
                        ],
                      ),
                      Text(
                        '${filtradas.length} comisión${filtradas.length == 1 ? '' : 'es'}'
                        '${hayFiltro ? ' filtradas' : ' pendientes'}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // ── Filtros ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _busqueda.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: _searchCtrl.clear,
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: colorScheme.outlineVariant),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _FiltroChip(
                            label: 'Todos',
                            selected: _filtroTipo == null,
                            onTap: () => setState(() => _filtroTipo = null),
                          ),
                          const SizedBox(width: 8),
                          _FiltroChip(
                            label: 'Asesoras',
                            icon: Icons.storefront_outlined,
                            color: Colors.green,
                            selected: _filtroTipo == TipoComision.venta,
                            onTap: () => setState(
                                () => _filtroTipo = TipoComision.venta),
                          ),
                          const SizedBox(width: 8),
                          _FiltroChip(
                            label: 'Cobradores',
                            icon: Icons.payments_outlined,
                            color: Colors.blue,
                            selected: _filtroTipo == TipoComision.cobro,
                            onTap: () => setState(
                                () => _filtroTipo = TipoComision.cobro),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Lista ────────────────────────────────────────────────
                Expanded(
                  child: filtradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hayFiltro
                                    ? Icons.search_off
                                    : Icons.check_circle_outline,
                                color: colorScheme.primary,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                hayFiltro
                                    ? 'Sin resultados para este filtro'
                                    : 'No hay comisiones pendientes\npara este período',
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => ref
                              .read(comisionControllerProvider.notifier)
                              .escucharComisionesPendientes(),
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: porUsuario.entries.map((entry) {
                              final uid = entry.key;
                              final lista = entry.value;
                              final nombre = lista.first.nombreUsuario;
                              final tipo = lista.first.tipo;
                              final total = _totalUsuario(lista);
                              final ids =
                                  lista.map((c) => c.comisionId).toList();
                              final todosMarcados =
                                  ids.every(_seleccionados.contains);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        tipo == TipoComision.venta
                                            ? Colors.green
                                                .withValues(alpha: 0.15)
                                            : Colors.blue
                                                .withValues(alpha: 0.15),
                                    child: Icon(
                                      tipo == TipoComision.venta
                                          ? Icons.storefront_outlined
                                          : Icons.payments_outlined,
                                      color: tipo == TipoComision.venta
                                          ? Colors.green
                                          : Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(nombre,
                                      style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    '${tipo == TipoComision.venta ? "Asesora" : "Cobrador"} · ${lista.length} comisión${lista.length == 1 ? '' : 'es'}',
                                    style: textTheme.bodySmall,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '\$${fmt.format(total)}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Checkbox(
                                        value: todosMarcados,
                                        onChanged: (_) =>
                                            _toggleUsuario(uid, lista),
                                        activeColor: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                  children: lista.map((c) {
                                    return ListTile(
                                      dense: true,
                                      leading: Checkbox(
                                        value: _seleccionados
                                            .contains(c.comisionId),
                                        onChanged: (_) => setState(() {
                                          if (_seleccionados
                                              .contains(c.comisionId)) {
                                            _seleccionados
                                                .remove(c.comisionId);
                                          } else {
                                            _seleccionados
                                                .add(c.comisionId);
                                          }
                                        }),
                                        activeColor: colorScheme.primary,
                                      ),
                                      title: Text(
                                        c.nombreCliente,
                                        style: textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        'Base: \$${fmt.format(c.montoBase)} · 20%',
                                        style: textTheme.bodySmall,
                                      ),
                                      trailing: Text(
                                        '\$${fmt.format(c.montoComision)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),

                // ── Barra de pago ─────────────────────────────────────────
                if (_seleccionados.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_seleccionados.length} seleccionada${_seleccionados.length == 1 ? '' : 's'}',
                                style: textTheme.bodySmall,
                              ),
                              Text(
                                '\$${fmt.format(_totalSeleccionado(todas))}',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pagando ? null : _pagarSeleccionados,
                          icon: _pagando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.payment_outlined, size: 18),
                          label: const Text('Marcar Pagadas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─── Chip de filtro ──────────────────────────────────────────────────────────

class _FiltroChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected
                      ? chipColor
                      : colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? chipColor : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
