// lib/ui/admin_quincena_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/comision_model.dart';
import '../models/prestamo_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';

class AdminQuincenaScreen extends ConsumerStatefulWidget {
  const AdminQuincenaScreen({super.key});

  @override
  ConsumerState<AdminQuincenaScreen> createState() =>
      _AdminQuincenaScreenState();
}

class _AdminQuincenaScreenState extends ConsumerState<AdminQuincenaScreen> {
  final Set<String> _seleccionados = {};
  bool _pagando = false;

  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  TipoComision? _filtroTipo;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(comisionControllerProvider.notifier).escucharComisionesPendientes(),
    );
    _searchCtrl.addListener(
      () => setState(() => _busqueda = _searchCtrl.text.trim().toLowerCase()),
    );
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

  Map<String, List<ComisionModel>> _agruparPorUsuario(
      List<ComisionModel> lista) {
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

  void _mostrarDetalle({
    required String uid,
    required String nombre,
    required List<ComisionModel> comisiones,
    required TipoComision tipo,
    required Color accentColor,
    required Color accentBg,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuincenaDetalleSheet(
        uid: uid,
        nombre: nombre,
        comisiones: comisiones,
        tipo: tipo,
        accentColor: accentColor,
        accentBg: accentBg,
        onPagado: () => setState(() => _seleccionados.clear()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

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
            icon: Icon(Icons.refresh, color: jadeColor),
            onPressed: () => ref
                .read(comisionControllerProvider.notifier)
                .escucharComisionesPendientes(),
          ),
        ],
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator(color: jadeColor))
          : Column(
              children: [
                // ── Resumen ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: jadeBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período: ${_periodoActual()}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '\$${fmt.format(hayFiltro ? totalFiltrado : totalGeneral)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: jadeColor,
                            ),
                          ),
                          if (hayFiltro) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(total: \$${fmt.format(totalGeneral)})',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${filtradas.length} comisión${filtradas.length == 1 ? '' : 'es'}'
                        '${hayFiltro ? ' filtradas' : ' pendientes'}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
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
                            accentColor: isDark
                                ? AppColors.darkViolet
                                : AppColors.violet,
                            accentBg: isDark
                                ? AppColors.darkViolet50
                                : AppColors.violet50,
                            selected: _filtroTipo == TipoComision.venta,
                            onTap: () => setState(
                                () => _filtroTipo = TipoComision.venta),
                          ),
                          const SizedBox(width: 8),
                          _FiltroChip(
                            label: 'Cobradores',
                            icon: Icons.payments_outlined,
                            accentColor: jadeColor,
                            accentBg: jadeBg,
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
                                  hayFiltro
                                      ? Icons.search_off
                                      : Icons.check_circle_outline,
                                  color: cs.onSurfaceVariant,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                hayFiltro
                                    ? 'Sin resultados para este filtro'
                                    : 'No hay comisiones pendientes\npara este período',
                                style:
                                    TextStyle(color: cs.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: jadeColor,
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
                              final isAsesora = tipo == TipoComision.venta;
                              final accentColor = isAsesora
                                  ? (isDark
                                      ? AppColors.darkViolet
                                      : AppColors.violet)
                                  : jadeColor;
                              final accentBg = isAsesora
                                  ? (isDark
                                      ? AppColors.darkViolet50
                                      : AppColors.violet50)
                                  : jadeBg;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkInk200
                                        : AppColors.lightInk200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withAlpha(isDark ? 40 : 6),
                                      blurRadius: 1,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: ExpansionTile(
                                    backgroundColor: cs.surface,
                                    collapsedBackgroundColor: cs.surface,
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: accentBg,
                                        borderRadius:
                                            BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        isAsesora
                                            ? Icons.storefront_outlined
                                            : Icons.payments_outlined,
                                        color: accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${isAsesora ? "Asesora" : "Cobrador"} · ${lista.length} comisión${lista.length == 1 ? '' : 'es'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '\$${fmt.format(total)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                        Checkbox(
                                          value: todosMarcados,
                                          onChanged: (_) =>
                                              _toggleUsuario(uid, lista),
                                          activeColor: accentColor,
                                        ),
                                      ],
                                    ),
                                    children: [
                                      // ── Comisiones individuales ──────
                                      ...lista.map(
                                        (c) => ListTile(
                                          dense: true,
                                          leading: Checkbox(
                                            value: _seleccionados
                                                .contains(c.comisionId),
                                            onChanged: (_) =>
                                                setState(() {
                                              if (_seleccionados.contains(
                                                  c.comisionId)) {
                                                _seleccionados
                                                    .remove(c.comisionId);
                                              } else {
                                                _seleccionados
                                                    .add(c.comisionId);
                                              }
                                            }),
                                            activeColor: accentColor,
                                          ),
                                          title: Text(
                                            c.nombreCliente,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Base: \$${fmt.format(c.montoBase)} · 20%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          trailing: Text(
                                            '\$${fmt.format(c.montoComision)}',
                                            style: TextStyle(
                                              color: accentColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ── Botón ver desglose ───────────
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 4, 16, 12),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () => _mostrarDetalle(
                                              uid: uid,
                                              nombre: nombre,
                                              comisiones: lista,
                                              tipo: tipo,
                                              accentColor: accentColor,
                                              accentBg: accentBg,
                                            ),
                                            icon: Icon(
                                              Icons.receipt_long_outlined,
                                              size: 16,
                                              color: accentColor,
                                            ),
                                            label: Text(
                                              'Ver desglose y pagar quincena',
                                              style: TextStyle(
                                                  color: accentColor,
                                                  fontSize: 13),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: accentColor
                                                      .withAlpha(100)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),

                // ── Barra de pago rápido (multi-selección) ────────────────
                if (_seleccionados.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.darkInk200
                              : AppColors.lightInk200,
                        ),
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
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant),
                              ),
                              Text(
                                '\$${fmt.format(_totalSeleccionado(todas))}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: jadeColor,
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
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.payment_outlined, size: 18),
                          label: const Text('Marcar Pagadas'),
                          style: ElevatedButton.styleFrom(
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

// ─── Sheet de desglose por usuario ───────────────────────────────────────────

class _QuincenaDetalleSheet extends ConsumerStatefulWidget {
  final String uid;
  final String nombre;
  final List<ComisionModel> comisiones;
  final TipoComision tipo;
  final Color accentColor;
  final Color accentBg;
  final VoidCallback onPagado;

  const _QuincenaDetalleSheet({
    required this.uid,
    required this.nombre,
    required this.comisiones,
    required this.tipo,
    required this.accentColor,
    required this.accentBg,
    required this.onPagado,
  });

  @override
  ConsumerState<_QuincenaDetalleSheet> createState() =>
      _QuincenaDetalleSheetState();
}

class _QuincenaDetalleSheetState
    extends ConsumerState<_QuincenaDetalleSheet> {
  List<PrestamoModel>? _prestamos;
  double? _deduccionDevol; // solo asesoras
  bool _cargando = true;
  bool _pagando = false;

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final prestamoSvc = ref.read(prestamoServiceProvider);
      final cobroSvc = ref.read(cobroServiceProvider);

      final futures = await Future.wait([
        prestamoSvc.prestamosAprobadosConSaldo(widget.uid),
        if (widget.tipo == TipoComision.venta)
          cobroSvc.deduccionDevolucionesAsesora(widget.uid),
      ]);

      if (!mounted) return;
      setState(() {
        _prestamos = futures[0] as List<PrestamoModel>;
        if (widget.tipo == TipoComision.venta) {
          _deduccionDevol = futures[1] as double;
        } else {
          _deduccionDevol = 0;
        }
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prestamos = [];
        _deduccionDevol = 0;
        _cargando = false;
      });
    }
  }

  double get _bruto =>
      widget.comisiones.fold(0.0, (s, c) => s + c.montoComision);

  double get _montoBase =>
      widget.comisiones.fold(0.0, (s, c) => s + c.montoBase);

  double get _deudaPrestamo =>
      (_prestamos ?? []).fold(0.0, (s, p) => s + p.saldoPendiente);

  double get _deduccionDevolucion =>
      (_deduccionDevol ?? 0).clamp(0.0, _bruto);

  double get _disponibleParaDeuda =>
      (_bruto - _deduccionDevolucion).clamp(0.0, double.infinity);

  double get _deudaADescontar =>
      _deudaPrestamo.clamp(0.0, _disponibleParaDeuda);

  double get _neto =>
      (_disponibleParaDeuda - _deudaADescontar).clamp(0.0, double.infinity);

  Future<void> _pagar() async {
    setState(() => _pagando = true);
    try {
      final comisionIds =
          widget.comisiones.map((c) => c.comisionId).toList();

      final ok = await ref
          .read(comisionControllerProvider.notifier)
          .marcarPagadas(comisionIds);

      if (!ok) {
        if (mounted) appSnackbar(context, 'Error al marcar comisiones', error: true);
        setState(() => _pagando = false);
        return;
      }

      if (_deudaADescontar > 0) {
        await ref
            .read(prestamoServiceProvider)
            .descontarDeuda(
              usuarioUid: widget.uid,
              montoADescontar: _deudaADescontar,
            );
      }

      widget.onPagado();
      if (mounted) {
        Navigator.pop(context);
        appSnackbar(
          context,
          'Quincena pagada — neto: \$${fmt.format(_neto)}',
        );
      }
    } catch (e) {
      if (mounted) appSnackbar(context, e.toString(), error: true);
      setState(() => _pagando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAsesora = widget.tipo == TipoComision.venta;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInk300 : AppColors.lightInk300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.accentBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isAsesora
                        ? Icons.storefront_outlined
                        : Icons.payments_outlined,
                    color: widget.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${isAsesora ? "Asesora" : "Cobrador"} · ${widget.comisiones.length} comisión${widget.comisiones.length == 1 ? '' : 'es'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.accentBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAsesora ? 'ASESORA' : 'COBRADOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),

          // ── Body (scrollable) ────────────────────────────────────────────
          Expanded(
            child: _cargando
                ? Center(
                    child: CircularProgressIndicator(
                        color: widget.accentColor),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Resumen financiero ─────────────────────────────
                        _SectionLabel(
                          'RESUMEN DE PAGO',
                          color: widget.accentColor,
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkInk100
                                : AppColors.lightInk100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Monto base (ventas/cobros)
                              _DesgloseFila(
                                label: isAsesora
                                    ? 'Total vendido en el período'
                                    : 'Total cobrado en el período',
                                valor: _montoBase,
                                fmt: fmt,
                                cs: cs,
                                negrita: false,
                              ),
                              const SizedBox(height: 8),

                              // Comisión bruta
                              _DesgloseFila(
                                label: 'Comisión bruta (20%)',
                                valor: _bruto,
                                fmt: fmt,
                                cs: cs,
                                color: widget.accentColor,
                                negrita: true,
                              ),

                              if (isAsesora && _deduccionDevolucion > 0) ...[
                                const SizedBox(height: 8),
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? AppColors.darkInk200
                                      : AppColors.lightInk200,
                                ),
                                const SizedBox(height: 8),
                                _DesgloseFila(
                                  label: '(-) Devoluciones aprobadas',
                                  valor: _deduccionDevolucion,
                                  fmt: fmt,
                                  cs: cs,
                                  negativo: true,
                                  color: isDark
                                      ? AppColors.darkCoral
                                      : AppColors.coral,
                                ),
                              ],

                              if (_deudaADescontar > 0) ...[
                                const SizedBox(height: 8),
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? AppColors.darkInk200
                                      : AppColors.lightInk200,
                                ),
                                const SizedBox(height: 8),
                                _DesgloseFila(
                                  label: '(-) Descuento préstamo',
                                  valor: _deudaADescontar,
                                  fmt: fmt,
                                  cs: cs,
                                  negativo: true,
                                  color: isDark
                                      ? AppColors.darkAmber
                                      : AppColors.amber,
                                ),
                                if (_deudaPrestamo > _deudaADescontar)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Saldo de deuda restante: \$${fmt.format(_deudaPrestamo - _deudaADescontar)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                thickness: 1.5,
                                color: isDark
                                    ? AppColors.darkInk300
                                    : AppColors.lightInk300,
                              ),
                              const SizedBox(height: 10),

                              // Neto a pagar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'NETO A PAGAR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    '\$${fmt.format(_neto)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: widget.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Préstamos activos ─────────────────────────────
                        if (_prestamos!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionLabel(
                            'PRÉSTAMOS ACTIVOS',
                            color: widget.accentColor,
                          ),
                          const SizedBox(height: 10),
                          ..._prestamos!.map(
                            (p) => _PrestamoTile(
                              prestamo: p,
                              fmt: fmt,
                              cs: cs,
                              isDark: isDark,
                              accentColor: isDark
                                  ? AppColors.darkAmber
                                  : AppColors.amber,
                              accentBg: isDark
                                  ? AppColors.darkAmber50
                                  : AppColors.amber50,
                            ),
                          ),
                        ],

                        // ── Comisiones detalle ────────────────────────────
                        const SizedBox(height: 20),
                        _SectionLabel(
                          isAsesora ? 'VENTAS DEL PERÍODO' : 'COBROS DEL PERÍODO',
                          color: widget.accentColor,
                        ),
                        const SizedBox(height: 10),
                        ...widget.comisiones.map(
                          (c) => _ComisionTile(
                            comision: c,
                            fmt: fmt,
                            cs: cs,
                            isDark: isDark,
                            accentColor: widget.accentColor,
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),

          // ── Botón pagar ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _cargando || _pagando ? null : _pagar,
                icon: _pagando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payments_outlined, size: 20),
                label: Text(
                  _cargando
                      ? 'Calculando…'
                      : 'Pagar quincena — \$${fmt.format(_neto)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets locales ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _DesgloseFila extends StatelessWidget {
  final String label;
  final double valor;
  final NumberFormat fmt;
  final ColorScheme cs;
  final bool negativo;
  final bool negrita;
  final Color? color;

  const _DesgloseFila({
    required this.label,
    required this.valor,
    required this.fmt,
    required this.cs,
    this.negativo = false,
    this.negrita = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final efectivoColor = color ?? cs.onSurface;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: negrita ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: negrita ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '${negativo ? '−' : ''}\$${fmt.format(valor)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: negrita ? FontWeight.w700 : FontWeight.w500,
            color: efectivoColor,
          ),
        ),
      ],
    );
  }
}

class _PrestamoTile extends StatelessWidget {
  final PrestamoModel prestamo;
  final NumberFormat fmt;
  final ColorScheme cs;
  final bool isDark;
  final Color accentColor;
  final Color accentBg;

  const _PrestamoTile({
    required this.prestamo,
    required this.fmt,
    required this.cs,
    required this.isDark,
    required this.accentColor,
    required this.accentBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 16, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prestamo.motivo,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Monto: \$${fmt.format(prestamo.monto)}',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant),
              ),
              Text(
                'Saldo: \$${fmt.format(prestamo.saldoPendiente)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComisionTile extends StatelessWidget {
  final ComisionModel comision;
  final NumberFormat fmt;
  final ColorScheme cs;
  final bool isDark;
  final Color accentColor;

  const _ComisionTile({
    required this.comision,
    required this.fmt,
    required this.cs,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comision.nombreCliente,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  'Base: \$${fmt.format(comision.montoBase)}',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${fmt.format(comision.montoComision)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: accentColor,
                ),
              ),
              Text(
                '20%',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
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
  final Color? accentColor;
  final Color? accentBg;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
    this.accentBg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        accentColor ?? (isDark ? AppColors.darkJade : AppColors.brandJade);
    final bg =
        accentBg ?? (isDark ? AppColors.darkJade50 : AppColors.lightJade50);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? bg
              : (isDark ? AppColors.darkInk100 : AppColors.lightInk100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14, color: selected ? color : cs.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
