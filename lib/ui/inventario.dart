import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/producto_model.dart';
import '../core/theme/app_theme.dart';
import './product_card.dart';
import './view_producto.dart';

class InventarioPage extends ConsumerStatefulWidget {
  const InventarioPage({super.key});

  @override
  ConsumerState<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends ConsumerState<InventarioPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  Future<void> _confirmarEliminar(
    BuildContext context,
    String codigoBarras,
    String nombre,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "$nombre" del inventario? Esta acción no se puede deshacer.'),
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
      await ref.read(productoControllerProvider.notifier).eliminarProducto(codigoBarras);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productoControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final productos = _query.isEmpty
        ? state.productos
        : state.productos
            .where(
              (p) =>
                  p.nombre.toLowerCase().contains(_query.toLowerCase()) ||
                  p.codigoBarras.contains(_query),
            )
            .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductoFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + botón filtro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inventario',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Builder(
                    builder: (ctx) {
                      final isDark = Theme.of(ctx).brightness == Brightness.dark;
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkJade50 : AppColors.lightJade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: isDark ? AppColors.darkJade : AppColors.brandJade,
                          ),
                          onPressed: () {},
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Buscador
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
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
                  productos,
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
    List<ProductoModel> productos,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (cargando && productos.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (error != null && productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar inventario',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(productoControllerProvider.notifier).cargar(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (productos.isEmpty && _query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados para "$_query"',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en inventario',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar tu primer producto',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductoFormPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Producto'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () =>
          ref.read(productoControllerProvider.notifier).cargar(),
      child: ListView.builder(
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];
          return ProductoCard(
            nombre: producto.nombre,
            tipo: producto.tipo.name,
            cantidad: producto.cantidadStock,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductoFormPage(productoEditar: producto),
              ),
            ),
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductoFormPage(productoEditar: producto),
              ),
            ),
            onDelete: () => _confirmarEliminar(context, producto.codigoBarras, producto.nombre),
          );
        },
      ),
    );
  }
}
