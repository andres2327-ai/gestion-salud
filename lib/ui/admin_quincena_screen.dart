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
  List<ComisionModel> _comisiones = [];
  bool _cargando = true;
  final Set<String> _seleccionados = {};
  bool _pagando = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await ref
        .read(comisionControllerProvider.notifier)
        .cargarQuincenaTodos();
    setState(() {
      _comisiones = lista;
      _cargando = false;
    });
  }

  // Group commissions by user
  Map<String, List<ComisionModel>> get _porUsuario {
    final mapa = <String, List<ComisionModel>>{};
    for (final c in _comisiones) {
      mapa.putIfAbsent(c.usuarioUid, () => []).add(c);
    }
    return mapa;
  }

  double _totalUsuario(List<ComisionModel> lista) =>
      lista.fold(0.0, (s, c) => s + c.montoComision);

  double get _totalQuincena =>
      _comisiones.fold(0.0, (s, c) => s + c.montoComision);

  double get _totalSeleccionado {
    return _comisiones
        .where((c) => _seleccionados.contains(c.comisionId))
        .fold(0.0, (s, c) => s + c.montoComision);
  }

  void _toggleUsuario(String uid, List<ComisionModel> lista) {
    setState(() {
      final ids = lista.map((c) => c.comisionId).toList();
      final todosMarcados = ids.every(_seleccionados.contains);
      if (todosMarcados) {
        _seleccionados.removeAll(ids);
      } else {
        _seleccionados.addAll(ids);
      }
    });
  }

  Future<void> _pagarSeleccionados() async {
    if (_seleccionados.isEmpty) return;
    setState(() => _pagando = true);
    final ok = await ref
        .read(comisionControllerProvider.notifier)
        .marcarPagadas(_seleccionados.toList());
    if (ok) {
      _seleccionados.clear();
      await _cargar();
    }
    if (mounted) setState(() => _pagando = false);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de Quincena'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // Summary header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Período: ${_periodoActual()}',
                          style: textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        'Total a pagar: \$${fmt.format(_totalQuincena)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${_comisiones.length} comisiones pendientes',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _comisiones.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: colorScheme.primary, size: 48),
                              const SizedBox(height: 12),
                              Text('No hay comisiones pendientes',
                                  style: textTheme.bodyLarge),
                              Text('para este período.',
                                  style: textTheme.bodyMedium),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: _porUsuario.entries.map((entry) {
                              final uid = entry.key;
                              final lista = entry.value;
                              final nombre = lista.first.nombreUsuario;
                              final tipo = lista.first.tipo;
                              final total = _totalUsuario(lista);
                              final ids = lista.map((c) => c.comisionId).toList();
                              final todosMarcados = ids.every(_seleccionados.contains);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: tipo == TipoComision.venta
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.blue.withValues(alpha: 0.15),
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
                                    '${tipo == TipoComision.venta ? "Asesora" : "Cobrador"} · ${lista.length} comisiones',
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
                                            _seleccionados.add(c.comisionId);
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

                // Bottom pay bar
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
                                '${_seleccionados.length} seleccionadas',
                                style: textTheme.bodySmall,
                              ),
                              Text(
                                '\$${fmt.format(_totalSeleccionado)}',
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
                                      strokeWidth: 2, color: Colors.white),
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
