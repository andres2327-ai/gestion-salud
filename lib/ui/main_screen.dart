import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import 'dashboard_screen.dart';
import 'inventario.dart';
import 'asesoras_screen.dart';
import 'reportes_screen.dart';
import 'admin_devoluciones_screen.dart';
import 'asesora_home_screen.dart';
import 'asesora_tarjetas_screen.dart';
import 'asesora_productos_screen.dart';
import 'asesora_perfil_screen.dart';
import 'cobrador_home_screen.dart';
import 'cobrador_perfil_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

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

// ─── Navegación Admin / SuperAdmin ───────────────────────────────────────────
class _AdminNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AdminNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const InventarioPage(),
      const AsesoresScreen(),
      const AdminDevolucionesScreen(),
      const ReportesScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      body: screens[selectedIndex],
      bottomNavigationBar: _BottomNav(
        currentIndex: selectedIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_return_outlined),
            label: 'Devoluc.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}

// ─── Navegación Asesora ───────────────────────────────────────────────────────
class _AsesoraNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AsesoraNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screens = [
      const AsesoraHomeScreen(),
      const AsesoraTarjetasScreen(),
      const AsesoraProductosScreen(),
      const AsesoraPerfilScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      body: screens[selectedIndex],
      bottomNavigationBar: _BottomNav(
        currentIndex: selectedIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ─── Navegación Cobrador ──────────────────────────────────────────────────────
class _CobradorNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CobradorNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screens = [
      const CobradorHomeScreen(),
      const CobradorPerfilScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      body: screens[selectedIndex],
      bottomNavigationBar: _BottomNav(
        currentIndex: selectedIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Mis Cobros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ─── BottomNav compartido ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1A1C3A),
      selectedItemColor: Colors.tealAccent,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: items,
    );
  }
}
