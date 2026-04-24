import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../core/theme/app_theme.dart';
import '../models/producto_model.dart';
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ProductoState expone List<ProductoModel> + bool cargando + String? error
    // NO es un AsyncValue — el .when() del código original era incorrecto
    final state = ref.watch(productoControllerProvider);

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
      backgroundColor: AppColors.background,

      // 🔹 FAB
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
              // 🔹 Título + botón filtro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventario',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentGlow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: AppColors.accent),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🔍 Buscador con botón limpiar
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textHint, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 📋 Cuerpo principal
              Expanded(
                child: _buildBody(state.cargando, state.error, productos),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    bool cargando,
    String? error,
    List<ProductoModel> productos,
  ) {
    // 1. Spinner inicial (sin datos todavía)
    if (cargando && productos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    // 2. Error sin datos
    if (error != null && productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar inventario',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
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

    // 3. Sin resultados para la búsqueda activa
    if (productos.isEmpty && _query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.textHint, size: 48),
            const SizedBox(height: 16),
            Text(
              'Sin resultados para "$_query"',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 4. Inventario vacío (cero productos en Firebase)
    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: AppColors.accent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No hay productos en inventario',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca el botón + para agregar tu primer producto',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

    // 5. Lista normal ✅
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
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
              MaterialPageRoute(builder: (_) => const ProductoFormPage()),
            ),
          );
        },
      ),
    );
  }
}
