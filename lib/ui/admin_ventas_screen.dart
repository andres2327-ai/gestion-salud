import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tarjeta_model.dart';
import '../providers.dart';
import 'admin_nueva_venta_screen.dart';

class AdminVentasScreen extends ConsumerStatefulWidget {
  const AdminVentasScreen({super.key});

  @override
  ConsumerState<AdminVentasScreen> createState() => _AdminVentasScreenState();
}

class _AdminVentasScreenState extends ConsumerState<AdminVentasScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _zonaFiltro; // null = todas las zonas

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
    final colorScheme = Theme.of(context).colorScheme;
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
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tarjetaControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Apply search + zone filter
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
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ventas.length}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Filtros por zona ─────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ZonaChip(
                      label: 'Todas',
                      selected: _zonaFiltro == null,
                      colorScheme: colorScheme,
                      onTap: () => setState(() => _zonaFiltro = null),
                    ),
                    ...kZonas.map(
                      (z) => _ZonaChip(
                        label: z,
                        selected: _zonaFiltro == z,
                        colorScheme: colorScheme,
                        onTap: () =>
                            setState(() => _zonaFiltro = _zonaFiltro == z ? null : z),
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
                child: _buildBody(
                  context,
                  state.cargando,
                  state.error,
                  ventas,
                  colorScheme,
                  textTheme,
                ),
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
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (cargando && ventas.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (error != null && ventas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar ventas',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: textTheme.bodySmall),
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
            Icon(
              Icons.receipt_long_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _query.isNotEmpty
                  ? 'Sin resultados para "$_query"'
                  : 'No hay ventas registradas',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () async =>
          ref.read(tarjetaControllerProvider.notifier).cargarTodas(),
      child: ListView.builder(
        itemCount: ventas.length,
        itemBuilder: (context, i) {
          final venta = ventas[i];
          return _VentaCard(
            venta: venta,
            onEdit: () => _editarVenta(venta),
            onDelete: () => _eliminarVenta(venta),
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

  const _VentaCard({
    required this.venta,
    required this.onEdit,
    required this.onDelete,
  });

  Color _estadoColor(EstadoTarjeta e, ColorScheme cs) {
    switch (e) {
      case EstadoTarjeta.activa:
        return cs.primary;
      case EstadoTarjeta.pagada:
        return Colors.green;
      case EstadoTarjeta.vencida:
        return cs.error;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final estadoColor = _estadoColor(venta.estado, colorScheme);

    final fecha =
        '${venta.fechaVenta.day.toString().padLeft(2, '0')}/'
        '${venta.fechaVenta.month.toString().padLeft(2, '0')}/'
        '${venta.fechaVenta.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
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
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _labelEstado(venta.estado),
                    style: textTheme.labelSmall?.copyWith(
                      color: estadoColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
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
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  venta.nombreAsesora,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(fecha, style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(venta.telefonoCliente, style: textTheme.bodySmall),
                const Spacer(),
                Text(
                  '\$${venta.totalVenta.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (venta.zona.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    venta.zona,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (venta.descripcion != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        venta.descripcion!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                  Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${venta.numCuotas} cuotas · \$${venta.montoCuota.toStringAsFixed(0)} c/u',
                    style: textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'Saldo: \$${venta.saldoPendiente.toStringAsFixed(0)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: venta.saldoPendiente > 0
                          ? colorScheme.error
                          : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
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
  final ColorScheme colorScheme;

  const _ZonaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
