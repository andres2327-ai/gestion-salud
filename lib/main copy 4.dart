import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gestion_salud/firebase_options.dart';
import 'package:gestion_salud/ui/login.dart';
import 'package:gestion_salud/ui/main_screen.dart';
import 'package:gestion_salud/services/storage_service.dart';
import 'firebase_options.dart';
import 'providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientacion preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Cerrar sesión al iniciar la app para que no permanezca iniciada de forma permanente
  await FirebaseAuth.instance.signOut();

  // Inicializar datos de locale para que DateFormat('es_ES') funcione
  await initializeDateFormatting('es_ES', null);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiero Salud',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF057661),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF057661),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      themeMode: ThemeMode.system,
      home: const RootRoute(),
    );
  }
}

class RootRoute extends ConsumerWidget {
  const RootRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Mostrar pantalla de carga mientras se verifica autenticacion
    if (authState.cargando && authState.firebaseUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF033F3F),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF057661)),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando...',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Si el usuario esta autenticado, mostrar la app con solicitud de permisos
    if (authState.autenticado) {
      return const LocationPermissionWrapper(child: MainScreen());
    }

    // Si no esta autenticado, mostrar login
    return const Scaffold(body: Login());
  }
}

// ─── Widget para solicitar permisos de ubicación ──────────────────────────────
class LocationPermissionWrapper extends StatefulWidget {
  final Widget child;

  const LocationPermissionWrapper({super.key, required this.child});

  @override
  State<LocationPermissionWrapper> createState() =>
      _LocationPermissionWrapperState();
}

class _LocationPermissionWrapperState extends State<LocationPermissionWrapper> {
  bool _hasCheckedPermissions = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _solicitarPermisos();
  }

  Future<void> _solicitarPermisos() async {
    if (_hasCheckedPermissions) return;

    final gpsService = GpsService();
    final serviceEnabled = await gpsService.isLocationServiceEnabled();

    if (!mounted) return;

    if (!serviceEnabled) {
      _mostrarDialogoUbicacion();
      setState(() {
        _hasCheckedPermissions = true;
        _permissionGranted = false;
      });
      return;
    }

    final granted = await gpsService.solicitarPermisos();

    if (!mounted) return;

    if (!granted) {
      _mostrarDialogoPermisoRequerido();
    }

    setState(() {
      _hasCheckedPermissions = true;
      _permissionGranted = granted;
    });
  }

  void _mostrarDialogoUbicacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ubicación Requerida'),
        content: const Text(
          'Para usar la función de rutas, necesitamos acceso a tu ubicación. '
          'Por favor, habilita la ubicación en la configuración de tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora No'),
          ),
          ElevatedButton(
            onPressed: () async {
              final gpsService = GpsService();
              await gpsService.abrirConfiguracionUbicacion();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPermisoRequerido() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de ubicación necesario'),
        content: const Text(
          'La aplicación necesita permiso de ubicación para funcionar correctamente. '
          'Por favor concede el permiso y reinicia la aplicación si es necesario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final gpsService = GpsService();
              await gpsService.abrirConfiguracionApp();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedPermissions) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_permissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permisos de ubicación')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'La aplicación necesita permiso de ubicación para continuar.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _solicitarPermisos,
                child: const Text('Solicitar permisos nuevamente'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final gpsService = GpsService();
                  await gpsService.abrirConfiguracionApp();
                },
                child: const Text('Abrir ajustes de la aplicación'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
