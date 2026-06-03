import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'inventario.dart';
import 'asesoras_screen.dart';
import 'reportes_screen.dart';
import 'admin_devoluciones_screen.dart';
import 'admin_ventas_screen.dart';
import 'asesora_home_screen.dart';
import 'asesora_tarjetas_screen.dart';
import 'asesora_productos_screen.dart';
import 'asesora_perfil_screen.dart';
import 'cobrador_home_screen.dart';
import 'cobrador_perfil_screen.dart';
import 'admin_quincena_screen.dart';
import 'admin_prestamos_screen.dart';
import 'cobrador_cierre_dia_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Precarga usuarios una sola vez al autenticarse para que
    // estén disponibles offline en cualquier pantalla.
    Future.microtask(
      () => ref.read(usuarioControllerProvider.notifier).cargar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(rolActualProvider);

    switch (rol) {
      case RolUsuario.asesora:
        return _AsesoraNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        );
      case RolUsuario.cobrador:
        return _CobradorNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        );
      default:
        return _AdminNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        );
    }
  }
}

// ─── Admin nav ────────────────────────────────────────────────────────────────
class _AdminNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AdminNav({required this.selectedIndex, required this.onTap});

  @override
  State<_AdminNav> createState() => _AdminNavState();
}

class _AdminNavState extends State<_AdminNav> {
  // Solo 3 pantallas principales en stack; las demás se abren vía Navigator.
  static const _screens = [
    DashboardScreen(),
    InventarioPage(),
    AdminVentasScreen(),
  ];

  void _handleTap(int index) {
    if (index == 3) {
      _showMasSheet();
      return;
    }
    widget.onTap(index);
  }

  void _showMasSheet() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MasSheet(
        onNavigate: _navigateTo,
        cs: cs,
        isDark: isDark,
      ),
    );
  }

  void _navigateTo(String screen) {
    Navigator.pop(context); // close sheet first
    Widget dest;
    switch (screen) {
      case 'usuarios':
        dest = const AsesoresScreen();
      case 'devoluciones':
        dest = const AdminDevolucionesScreen();
      case 'quincena':
        dest = const AdminQuincenaScreen();
      case 'prestamos':
        dest = const AdminPrestamosScreen();
      case 'reportes':
        dest = const ReportesScreen();
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: widget.selectedIndex.clamp(0, _screens.length - 1),
        children: _screens,
      ),
      bottomNavigationBar: _QSBottomNav(
        currentIndex: widget.selectedIndex,
        onTap: _handleTap,
        items: const [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
          _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventario'),
          _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Ventas'),
          _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Más'),
        ],
      ),
    );
  }
}

// ─── Sheet "Más" del admin ────────────────────────────────────────────────────
class _MasSheet extends StatelessWidget {
  final void Function(String) onNavigate;
  final ColorScheme cs;
  final bool isDark;

  const _MasSheet({
    required this.onNavigate,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SheetItem('usuarios', Icons.people_alt_outlined, 'Usuarios', AppColors.violet, AppColors.violet50),
      _SheetItem('devoluciones', Icons.assignment_return_outlined, 'Devoluciones', AppColors.coral, AppColors.coral50),
      _SheetItem('quincena', Icons.payments_outlined, 'Quincena', AppColors.amber, AppColors.amber50),
      _SheetItem('prestamos', Icons.account_balance_wallet_outlined, 'Préstamos', AppColors.brandJade, AppColors.lightJade50),
      _SheetItem('reportes', Icons.bar_chart_outlined, 'Reportes', AppColors.sky, AppColors.sky50),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 100 : 30),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            'Más herramientas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: items
                .map((it) => _SheetTile(item: it, onTap: () => onNavigate(it.id), cs: cs))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SheetItem {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final Color tint;
  const _SheetItem(this.id, this.icon, this.label, this.color, this.tint);
}

class _SheetTile extends StatelessWidget {
  final _SheetItem item;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SheetTile({required this.item, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Asesora nav ──────────────────────────────────────────────────────────────
class _AsesoraNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AsesoraNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const screens = [
      AsesoraHomeScreen(),
      AsesoraTarjetasScreen(),
      AsesoraProductosScreen(),
      AsesoraPerfilScreen(),
    ];
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: _QSBottomNav(
        currentIndex: selectedIndex,
        onTap: onTap,
        items: const [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
          _NavItem(icon: Icons.credit_card_outlined, activeIcon: Icons.credit_card, label: 'Clientes'),
          _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Productos'),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
        ],
      ),
    );
  }
}

// ─── Cobrador nav ─────────────────────────────────────────────────────────────
class _CobradorNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CobradorNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const screens = [
      CobradorHomeScreen(),
      CobradorCierreDiaScreen(),
      CobradorPerfilScreen(),
    ];
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: _QSBottomNav(
        currentIndex: selectedIndex,
        onTap: onTap,
        items: const [
          _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Mis Cobros'),
          _NavItem(icon: Icons.summarize_outlined, activeIcon: Icons.summarize, label: 'Cierre'),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
        ],
      ),
    );
  }
}

// ─── Premium pill bottom nav ──────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _QSBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _QSBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(14, 8, 14, (bottom > 0 ? bottom : 14)),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 18),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            final activeColor =
                isDark ? AppColors.darkBg : Colors.white;
            final activeBg =
                isDark ? AppColors.darkJade : AppColors.lightInk900;
            final inactiveColor =
                isDark ? AppColors.darkInk500 : AppColors.lightInk500;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? items[i].activeIcon : items[i].icon,
                        size: 19,
                        color: active ? activeColor : inactiveColor,
                      ),
                      if (active) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            items[i].label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: activeColor,
                              letterSpacing: -0.005,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
