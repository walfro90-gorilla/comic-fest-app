import 'package:comic_fest/models/user_model.dart';
import 'package:comic_fest/services/ticket_service.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TicketService _ticketService = TicketService();
  final UserService _userService = UserService();
  MobileScannerController? _controller;
  final TextEditingController _manualCodeController = TextEditingController();
  
  bool _isProcessing = false;
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _checkAuthorization();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorization() async {
    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _isAuthorized = user?.role == UserRole.staff || user?.role == UserRole.admin;
        _isCheckingAuth = false;
      });

      if (!_isAuthorized && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para escanear boletos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCheckingAuth = false);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    await _processQRCode(code);
  }

  Future<void> _processQRCode(String code) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // El código QR contiene directamente el ID del ticket
      final ticketId = code.trim();
      
      // Validar el ticket contra Supabase
      final isValid = await _ticketService.validateTicket(ticketId);

      if (!mounted) return;

      if (isValid) {
        // Marcar como usado en la base de datos
        await _ticketService.markTicketAsUsed(ticketId);
        _showValidationResult(true, '✅ Boleto válido y registrado\n\nID: ${ticketId.substring(0, 8)}...');
      } else {
        _showValidationResult(false, '❌ Boleto inválido o ya utilizado\n\nID: ${ticketId.substring(0, 8)}...');
      }
    } catch (e) {
      if (mounted) {
        _showValidationResult(false, 'Error al validar: $e');
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isProcessing = false);
        _manualCodeController.clear();
      }
    }
  }

  void _showValidationResult(bool success, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle : Icons.error,
          color: success ? Colors.green : Colors.red,
          size: 64,
        ),
        title: Text(success ? '✅ Acceso Permitido' : '❌ Acceso Denegado'),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrada Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _manualCodeController,
              decoration: InputDecoration(
                hintText: 'Ingresa el ID del ticket\n(ej: 123e4567-e89b-12d3-...)',
                prefixIcon: const Icon(Icons.confirmation_number),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _manualCodeController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final code = _manualCodeController.text.trim();
              Navigator.of(context).pop();
              if (code.isNotEmpty) {
                _processQRCode(code);
              }
            },
            child: const Text('Validar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return const Scaffold(
        body: Center(child: Text('No autorizado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Boletos'),
        actions: [
          if (_controller != null) ...[
            if (!kIsWeb) IconButton(
              icon: Icon(_controller!.torchEnabled ? Icons.flash_on : Icons.flash_off),
              onPressed: () => _controller!.toggleTorch(),
            ),
            if (!kIsWeb) IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => _controller!.switchCamera(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard),
              onPressed: () => _showManualEntryDialog(),
              tooltip: 'Entrada manual',
            ),
          ],
        ],
      ),
      body: _buildScanner(colorScheme),
    );
  }

  Widget _buildScanner(ColorScheme colorScheme) {
    return Stack(
      children: [
        if (_controller != null)
          MobileScanner(
            controller: _controller!,
            onDetect: _handleBarcode,
          ),
        _buildOverlay(colorScheme),
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildOverlay(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black.withValues(alpha: 0.7),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Coloca el código QR dentro del marco',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'El escaneo es automático',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Validando boleto...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
