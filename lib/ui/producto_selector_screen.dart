// lib/ui/producto_selector_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import 'widgets/shared_widgets.dart';

// ── Adaptador genérico ────────────────────────────────────────────────────────
// Permite usar la pantalla tanto con ProductoModel (admin) como con
// AsignacionProductoModel (asesora) sin acoplar la UI al modelo.

class ProductoSelectorItem {
  final String codigo;
  final String nombre;
  final double precio;
  final int stockDisponible;

  const ProductoSelectorItem({
    required this.codigo,
    required this.nombre,
    required this.precio,
    required this.stockDisponible,
  });
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class ProductoSelectorScreen extends StatefulWidget {
  final List<ProductoSelectorItem> productos;
  final Map<String, int> cantidadesIniciales;
  final Color accentColor;
  final Color accentBg;

  const ProductoSelectorScreen({
    super.key,
    required this.productos,
    required this.cantidadesIniciales,
    required this.accentColor,
    required this.accentBg,
  });

  /// Abre la pantalla y retorna las cantidades actualizadas (o null si cancela).
  static Future<Map<String, int>?> abrir(
    BuildContext context, {
    required List<ProductoSelectorItem> productos,
    required Map<String, int> cantidadesIniciales,
    required Color accentColor,
    required Color accentBg,
  }) {
    return Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoSelectorScreen(
          productos: productos,
          cantidadesIniciales: cantidadesIniciales,
          accentColor: accentColor,
          accentBg: accentBg,
        ),
      ),
    );
  }

  @override
  State<ProductoSelectorScreen> createState() => _ProductoSelectorScreenState();
}

class _ProductoSelectorScreenState extends State<ProductoSelectorScreen> {
  final _searchCtrl = TextEditingController();
  late final Map<String, int> _cantidades;
  String _busqueda = '';

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  void initState() {
    super.initState();
    _cantidades = Map.from(widget.cantidadesIniciales);
    _searchCtrl.addListener(() {
      setState(() => _busqueda = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductoSelectorItem> get _filtrados {
    if (_busqueda.isEmpty) return widget.productos;
    return widget.productos
        .where((p) => p.nombre.toLowerCase().contains(_busqueda))
        .toList();
  }

  int get _totalSeleccionados =>
      _cantidades.values.where((q) => q > 0).length;

  int get _totalUnidades =>
      _cantidades.values.fold(0, (acc, q) => acc + q);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtrados = _filtrados;

    // Ordenar: seleccionados primero
    filtrados.sort((a, b) {
      final qa = _cantidades[a.codigo] ?? 0;
      final qb = _cantidades[b.codigo] ?? 0;
      if (qa > 0 && qb == 0) return -1;
      if (qa == 0 && qb > 0) return 1;
      return a.nombre.compareTo(b.nombre);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Productos'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: cs.onSurface),
          ),
        ),
        actions: [
          if (_totalSeleccionados > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_totalSeleccionados seleccionado${_totalSeleccionados == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // ── Contador de resultados ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtrados.length} producto${filtrados.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (_totalUnidades > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_totalUnidades unidad${_totalUnidades == 1 ? '' : 'es'} en carrito',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: filtrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin resultados para "$_busqueda"',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = filtrados[i];
                      final qty = _cantidades[p.codigo] ?? 0;
                      return _SelectorProductoRow(
                        item: p,
                        cantidad: qty,
                        fmt: fmt,
                        isDark: isDark,
                        cs: cs,
                        accentColor: widget.accentColor,
                        accentBg: widget.accentBg,
                        onChanged: (v) =>
                            setState(() => _cantidades[p.codigo] = v),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Bottom bar ─────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(
              color:
                  isDark ? AppColors.darkInk200 : AppColors.lightInk200,
            ),
          ),
        ),
        child: ElevatedButton(
          onPressed: _totalSeleccionados == 0
              ? null
              : () => Navigator.pop(context, Map<String, int>.from(_cantidades)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                isDark ? AppColors.darkInk200 : AppColors.lightInk200,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            _totalSeleccionados == 0
                ? 'Selecciona al menos un producto'
                : 'Confirmar $_totalSeleccionados producto${_totalSeleccionados == 1 ? '' : 's'} · \$${fmt.format(_totalCosto())}',
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }

  double _totalCosto() {
    return widget.productos.fold(0.0, (acc, p) {
      final qty = _cantidades[p.codigo] ?? 0;
      return acc + p.precio * qty;
    });
  }
}

// ── Fila de producto en el selector ──────────────────────────────────────────

class _SelectorProductoRow extends StatelessWidget {
  final ProductoSelectorItem item;
  final int cantidad;
  final NumberFormat fmt;
  final bool isDark;
  final ColorScheme cs;
  final Color accentColor;
  final Color accentBg;
  final ValueChanged<int> onChanged;

  const _SelectorProductoRow({
    required this.item,
    required this.cantidad,
    required this.fmt,
    required this.isDark,
    required this.cs,
    required this.accentColor,
    required this.accentBg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final seleccionado = cantidad > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: seleccionado ? accentBg : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: seleccionado
              ? accentColor.withAlpha(120)
              : (isDark ? AppColors.darkInk200 : AppColors.lightInk200),
          width: seleccionado ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // ── Ícono ─────────────────────────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: seleccionado
                  ? accentColor.withAlpha(40)
                  : (isDark ? AppColors.darkInk100 : AppColors.lightInk100),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.medication_rounded,
              size: 18,
              color: seleccionado ? accentColor : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ──────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: seleccionado ? accentColor : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '\$${fmt.format(item.precio)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: seleccionado
                            ? accentColor
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: ${item.stockDisponible}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Contador ─────────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CounterButton(
                icon: Icons.remove_rounded,
                enabled: cantidad > 0,
                accentColor: accentColor,
                accentBg: accentBg,
                onTap: () => onChanged(cantidad - 1),
              ),
              SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    '$cantidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: seleccionado ? accentColor : cs.onSurface,
                    ),
                  ),
                ),
              ),
              CounterButton(
                icon: Icons.add_rounded,
                enabled: cantidad < item.stockDisponible,
                accentColor: accentColor,
                accentBg: accentBg,
                onTap: () => onChanged(cantidad + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
