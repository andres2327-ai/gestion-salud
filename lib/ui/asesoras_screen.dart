import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/usuario_model.dart';
import 'admin_asignar_productos_screen.dart';
import 'admin_asignar_tarjetas_screen.dart';

class AsesoresScreen extends ConsumerStatefulWidget {
  const AsesoresScreen({super.key});

  @override
  ConsumerState<AsesoresScreen> createState() => _AsesoresScreenState();
}

class _AsesoresScreenState extends ConsumerState<AsesoresScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(usuarioControllerProvider.notifier).cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuarioState = ref.watch(usuarioControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        title: const Text(
          'Usuarios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        onPressed: () => _mostrarFormularioUsuario(context),
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
      body: usuarioState.cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : usuarioState.error != null
          ? Center(
              child: Text(
                'Error: ${usuarioState.error}',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(usuarioControllerProvider.notifier).cargar(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C3A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ResumenItem(
                            'Total',
                            usuarioState.todos.length.toString(),
                            Colors.blue,
                          ),
                          _ResumenItem(
                            'Activos',
                            usuarioState.todos
                                .where((u) => u.activo)
                                .length
                                .toString(),
                            Colors.green,
                          ),
                          _ResumenItem(
                            'Inactivos',
                            usuarioState.todos
                                .where((u) => !u.activo)
                                .length
                                .toString(),
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (usuarioState.asesoras.isNotEmpty) ...[
                      _SectionTitle(
                        'Asesoras (${usuarioState.asesoras.length})',
                      ),
                      const SizedBox(height: 12),
                      ...usuarioState.asesoras.map(
                        (u) => _UsuarioCard(
                          usuario: u,
                          onTap: () => _mostrarOpcionesUsuario(context, u),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (usuarioState.cobradores.isNotEmpty) ...[
                      _SectionTitle(
                        'Cobradores (${usuarioState.cobradores.length})',
                      ),
                      const SizedBox(height: 12),
                      ...usuarioState.cobradores.map(
                        (u) => _UsuarioCard(
                          usuario: u,
                          onTap: () => _mostrarOpcionesUsuario(context, u),
                        ),
                      ),
                    ],

                    if (usuarioState.todos.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No hay usuarios registrados',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _mostrarOpcionesUsuario(BuildContext context, UsuarioModel usuario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.tealAccent.withAlpha(40),
                  child: Text(
                    usuario.nombre.isNotEmpty
                        ? usuario.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        usuario.rol == RolUsuario.asesora
                            ? 'Asesora'
                            : 'Cobrador',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 28),

            // Toggle activo/inactivo
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                usuario.activo
                    ? Icons.person_off_outlined
                    : Icons.person_outlined,
                color: usuario.activo ? Colors.orange : Colors.green,
              ),
              title: Text(
                usuario.activo ? 'Desactivar usuario' : 'Activar usuario',
                style: TextStyle(
                  color: usuario.activo ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(usuarioControllerProvider.notifier)
                    .toggleActivo(usuario);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        usuario.activo
                            ? 'Usuario desactivado'
                            : 'Usuario activado',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
            ),

            // Asignar productos (solo asesoras)
            if (usuario.rol == RolUsuario.asesora)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.tealAccent,
                ),
                title: const Text(
                  'Asignar productos',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarAsignarProductos(context, usuario);
                },
              ),

            // Asignar tarjetas de cobro (solo cobradores)
            if (usuario.rol == RolUsuario.cobrador)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.credit_card_outlined,
                  color: Colors.blueAccent,
                ),
                title: const Text(
                  'Asignar tarjetas',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminAsignarTarjetasScreen(cobrador: usuario),
                    ),
                  );
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarAsignarProductos(BuildContext context, UsuarioModel asesora) {
    ref
        .read(asignacionProductoControllerProvider.notifier)
        .escucharAsignaciones(asesora.uid);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAsignarProductosScreen(asesora: asesora),
      ),
    );
  }

  void _mostrarFormularioUsuario(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    RolUsuario rolSeleccionado = RolUsuario.asesora;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1C3A),
          title: const Text(
            'Nuevo Usuario',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: nombreCtrl, hint: 'Nombre'),
                const SizedBox(height: 10),
                _DialogField(
                  controller: emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: passwordCtrl,
                  hint: 'Contraseña',
                  obscure: true,
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: telefonoCtrl,
                  hint: 'Teléfono',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _DialogField(controller: direccionCtrl, hint: 'Dirección'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1123),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha(80)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<RolUsuario>(
                      value: rolSeleccionado,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1C3A),
                      items: [
                        DropdownMenuItem(
                          value: RolUsuario.asesora,
                          child: Text(
                            'Asesora',
                            style: TextStyle(
                              color: rolSeleccionado == RolUsuario.asesora
                                  ? Colors.tealAccent
                                  : Colors.white,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: RolUsuario.cobrador,
                          child: Text(
                            'Cobrador',
                            style: TextStyle(
                              color: rolSeleccionado == RolUsuario.cobrador
                                  ? Colors.tealAccent
                                  : Colors.white,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: RolUsuario.admin,
                          child: Text(
                            'Administrador',
                            style: TextStyle(
                              color: rolSeleccionado == RolUsuario.admin
                                  ? Colors.tealAccent
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => rolSeleccionado = v);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nombreCtrl.text.isEmpty ||
                    emailCtrl.text.isEmpty ||
                    passwordCtrl.text.isEmpty ||
                    telefonoCtrl.text.isEmpty ||
                    direccionCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Completa todos los campos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final ok = await ref
                    .read(usuarioControllerProvider.notifier)
                    .crearUsuario(
                      nombre: nombreCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passwordCtrl.text,
                      telefono: telefonoCtrl.text.trim(),
                      direccion: direccionCtrl.text.trim(),
                      rol: rolSeleccionado,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Usuario creado' : 'Error al crear usuario',
                      ),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C3A),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

// ─── Widgets locales ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _ResumenItem(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;
  final VoidCallback onTap;

  const _UsuarioCard({required this.usuario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: usuario.activo
                ? Colors.green.withAlpha(60)
                : Colors.grey.withAlpha(30),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.tealAccent.withAlpha(30),
              child: Text(
                usuario.nombre.isNotEmpty
                    ? usuario.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        usuario.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: usuario.activo
                              ? Colors.green.withAlpha(40)
                              : Colors.red.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          usuario.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: usuario.activo ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    usuario.telefono,
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;

  const _DialogField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF0F1123),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
