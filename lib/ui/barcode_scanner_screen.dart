// lib/ui/barcode_scanner_screen.dart
// Escáner de código de barras para el inventario de productos.
// Soporta EAN-13, EAN-8, UPC-A, UPC-E, Code-128, Code-39, etc.
// Al detectar, hace pop con el número escaneado como String.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf,
    ],
  );

  bool _flashOn = false;
  bool _scanned = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _permissionDenied = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ctrl.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw != null && raw.isNotEmpty) {
      setState(() => _scanned = true);
      _ctrl.stop();
      Navigator.of(context).pop(raw);
    }
  }

  Future<void> _toggleFlash() async {
    await _ctrl.toggleTorch();
    setState(() => _flashOn = !_flashOn);
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return _PermissionDeniedView(
        onOpenSettings: () {
          openAppSettings();
          Navigator.pop(context);
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C3A),
        foregroundColor: Colors.white,
        title: const Text('Escanear Código de Barras'),
        actions: [
          IconButton(
            tooltip: _flashOn ? 'Apagar flash' : 'Encender flash',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _flashOn ? Icons.flash_on : Icons.flash_off,
                key: ValueKey(_flashOn),
                color: _flashOn ? Colors.amber : Colors.white,
              ),
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          _ScanOverlay(),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Apunta al código de barras del producto',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pantalla sin permiso ──────────────────────────────────────────────────────
class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionDeniedView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: const Color(0xFF1A1C3A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F1123),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Permiso de cámara requerido',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Para escanear el código de barras de los productos '
                'necesitamos acceso a la cámara.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Abrir ajustes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overlay con recuadro y línea animada ──────────────────────────────────────
class _ScanOverlay extends StatefulWidget {
  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _line;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _line = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Rectángulo horizontal (más ancho que alto) para códigos de barras
      final w = constraints.maxWidth * 0.75;
      const h = 140.0;
      final left = (constraints.maxWidth - w) / 2;
      final top = (constraints.maxHeight - h) / 2.2;

      return Stack(
        children: [
          // Fondo semitransparente con hueco rectangular
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Positioned(
                  top: top,
                  left: left,
                  child: Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Esquinas del recuadro
          Positioned(
            top: top,
            left: left,
            child: _CornerFrame(width: w, height: h),
          ),

          // Línea roja animada (clásica de escáner de barras)
          Positioned(
            top: top,
            left: left,
            child: SizedBox(
              width: w,
              height: h,
              child: AnimatedBuilder(
                animation: _line,
                builder: (context, child) => Stack(
                  children: [
                    Positioned(
                      top: _line.value * (h - 3),
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.tealAccent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CornerFrame extends StatelessWidget {
  final double width;
  final double height;
  const _CornerFrame({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    const len = 22.0;
    const thick = 3.5;
    const color = Colors.tealAccent;
    const r = Radius.circular(4);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Top-left
          Positioned(top: 0, left: 0,
              child: Container(width: len, height: thick,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: r)))),
          Positioned(top: 0, left: 0,
              child: Container(width: thick, height: len,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: r)))),
          // Top-right
          Positioned(top: 0, right: 0,
              child: Container(width: len, height: thick,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(topRight: r)))),
          Positioned(top: 0, right: 0,
              child: Container(width: thick, height: len,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(topRight: r)))),
          // Bottom-left
          Positioned(bottom: 0, left: 0,
              child: Container(width: len, height: thick,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(bottomLeft: r)))),
          Positioned(bottom: 0, left: 0,
              child: Container(width: thick, height: len,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(bottomLeft: r)))),
          // Bottom-right
          Positioned(bottom: 0, right: 0,
              child: Container(width: len, height: thick,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(bottomRight: r)))),
          Positioned(bottom: 0, right: 0,
              child: Container(width: thick, height: len,
                  decoration: const BoxDecoration(color: color, borderRadius: BorderRadius.only(bottomRight: r)))),
        ],
      ),
    );
  }
}
