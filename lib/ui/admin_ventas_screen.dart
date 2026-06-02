import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tarjeta_model.dart';
import '../providers.dart';
import '../core/theme/app_theme.dart';
import 'admin_nueva_venta_screen.dart';
import 'venta_detalle_screen.dart';

class AdminVentasScreen extends ConsumerStatefulWidget {
  const AdminVentasScreen({super.key});

  @override
  ConsumerState<AdminVentasScreen> createState() => _AdminVentasScreenState();
}

class _AdminVentasScreenState extends ConsumerState<AdminVentasScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _zonaFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tarjetaControllerProvider.notifier).cargarTodas();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _editarVenta(TarjetaModel tarjeta) async {
    final nombreCtrl = TextEditingController(text: tarjeta.nombreCliente);
    final telefonoCtrl = TextEditingController(text: tarjeta.telefonoCliente);
    final direccionCtrl = TextEditingController(text: tarjeta.direccionCliente);
    EstadoTarjeta estado = tarjeta.estado;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Venta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EstadoTarjeta>(
                  initialValue: estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: EstadoTarjeta.values.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(_labelEstado(e)),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => estado = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    nombreCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();

    if (result == true && mounted) {
      await ref.read(tarjetaControllerProvider.notifier).actualizarTarjeta(
        tarjeta.tarjetaId,
        {
          'nombre_cliente': nombreCtrl.text.trim(),
          'telefono_cliente': telefonoCtrl.text.trim(),
          'direccion_cliente': direccionCtrl.text.trim(),
          'estado': estado.name,
        },
      );
    }
  }

  Future<void> _eliminarVenta(TarjetaModel tarjeta) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text(
          '¿Eliminar la venta de ${tarjeta.nombreCliente}? '
          'Se eliminarán también todas las cuotas asociadas. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref
          .read(tarjetaControllerProvider.notifier)
          .eliminarTarjeta(tarjeta.tarjetaId);
    }
  }

  String _labelEstado(EstadoTarjeta e) {
    switch (e) {
      case EstadoTarjeta.activa:
        return 'Activa';
      case EstadoTarjeta.pagada:
        return 'Pagada';
      case EstadoTarjeta.vencida:
        return 'Vencida';
      case EstadoTarjeta.atrasada:
        return 'Atrasada';
      case EstadoTarjeta.enDevolucion:
        return 'En devolución';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tarjetaControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    var ventas = state.tarjetas;
    if (_zonaFiltro != null) {
      ventas = ventas.where((t) => t.zona == _zonaFiltro).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      ventas = ventas
          .where(
            (t) =>
                t.nombreCliente.toLowerCase().contains(q) ||
                t.nombreAsesora.toLowerCase().contains(q),
          )
          .toList();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminNuevaVentaScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ventas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: jadeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ventas.length}',
                      style: TextStyle(
                        color: jadeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ZonaChip(
                      label: 'Todas',
                      selected: _zonaFiltro == null,
                      isDark: isDark,
                      cs: cs,
                      onTap: () => setState(() => _zonaFiltro = null),
                    ),
                    ...kZonas.map(
                      (z) => _ZonaChip(
                        label: z,
                        selected: _zonaFiltro == z,
                        isDark: isDark,
                        cs: cs,
                        onTap: () => setState(
                            () => _zonaFiltro = _zonaFiltro == z ? null : z),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente o asesora...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildBody(context, state.cargando, state.error, ventas, isDark, cs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool cargando,
    String? error,
    List<TarjetaModel> ventas,
    bool isDark,
    ColorScheme cs,
  ) {
    if (cargando && ventas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && ventas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar ventas',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(tarjetaControllerProvider.notifier).cargarTodas(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (ventas.isEmpty) {
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
                Icons.receipt_long_outlined,
                color: cs.onSurfaceVariant,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _query.isNotEmpty
                  ? 'Sin resultados para "$_query"'
                  : 'No hay ventas registradas',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(tarjetaControllerProvider.notifier).cargarTodas(),
      child: ListView.builder(
        itemCount: ventas.length,
        itemBuilder: (context, i) {
          final venta = ventas[i];
          return _VentaCard(
            venta: venta,
            isDark: isDark,
            cs: cs,
            onEdit: () => _editarVenta(venta),
            onDelete: () => _eliminarVenta(venta),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VentaDetalleScreen(tarjeta: venta),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Card de venta ────────────────────────────────────────────────────────────
class _VentaCard extends StatelessWidget {
  final TarjetaModel venta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;

  const _VentaCard({
    required this.venta,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.isDark,
    required this.cs,
  });

  (Color, Color, String) _estadoStyle(EstadoTarjeta e) {
    switch (e) {
      case EstadoTarjeta.activa:
        return (
          isDark ? AppColors.darkViolet : AppColors.violet,
          isDark ? AppColors.darkViolet50 : AppColors.violet50,
          'Activa',
        );
      case EstadoTarjeta.pagada:
        return (
          isDark ? AppColors.darkJade : AppColors.brandJade,
          isDark ? AppColors.darkJade50 : AppColors.lightJade50,
          'Pagada',
        );
      case EstadoTarjeta.vencida:
        return (
          isDark ? AppColors.darkCoral : AppColors.coral,
          isDark ? AppColors.darkCoral50 : AppColors.coral50,
          'Vencida',
        );
      case EstadoTarjeta.atrasada:
        return (
          isDark ? AppColors.darkAmber : AppColors.amber,
          isDark ? AppColors.darkAmber50 : AppColors.amber50,
          'Atrasada',
        );
      case EstadoTarjeta.enDevolucion:
        return (
          isDark ? AppColors.darkViolet : AppColors.violet,
          isDark ? AppColors.darkViolet50 : AppColors.violet50,
          'En devolución',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (estadoColor, estadoBg, estadoLabel) = _estadoStyle(venta.estado);
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;

    final fecha =
        '${venta.fechaVenta.day.toString().padLeft(2, '0')}/'
        '${venta.fechaVenta.month.toString().padLeft(2, '0')}/'
        '${venta.fechaVenta.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 6),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    venta.nombreCliente,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: estadoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estadoLabel,
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18,
                              color: AppColors.coral),
                          const SizedBox(width: 10),
                          Text('Eliminar',
                              style: TextStyle(color: AppColors.coral)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  venta.nombreAsesora,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(fecha, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(venta.telefonoCliente,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const Spacer(),
                Text(
                  '\$${venta.totalVenta.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: jadeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (venta.zona.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.map_outlined, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    venta.zona,
                    style: TextStyle(
                      color: jadeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (venta.descripcion != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        venta.descripcion!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (venta.tipoPago == TipoPago.cuotas) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${venta.numCuotas} cuotas · \$${venta.montoCuota.toStringAsFixed(0)} c/u',
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    'Saldo: \$${venta.saldoPendiente.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: venta.saldoPendiente > 0
                          ? (isDark ? AppColors.darkCoral : AppColors.coral)
                          : (isDark ? AppColors.darkJade : AppColors.brandJade),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

// ─── Chip de filtro por zona ──────────────────────────────────────────────────
class _ZonaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme cs;

  const _ZonaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final jadeColor = isDark ? AppColors.darkJade : AppColors.brandJade;
    final jadeBg = isDark ? AppColors.darkJade50 : AppColors.lightJade50;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? jadeBg
              : (isDark ? AppColors.darkInk100 : AppColors.lightInk100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? jadeColor
                : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? jadeColor : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
