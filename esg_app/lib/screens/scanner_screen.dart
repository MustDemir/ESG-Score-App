import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/scanfair_tokens.dart';

typedef ScannerViewportBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<String> onBarcodeDetected,
    );

enum ScannerFailureType { permissionDenied, unsupported, unavailable }

String? normalizeScannedBarcode(String? rawValue) {
  final normalized = rawValue?.trim();
  if (normalized == null || !RegExp(r'^\d{8,14}$').hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({this.viewportBuilder, super.key});

  final ScannerViewportBuilder? viewportBuilder;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  var _hasCompleted = false;

  bool get _usesPhysicalCamera => widget.viewportBuilder == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
      returnImage: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_usesPhysicalCamera || !_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_hasCompleted) unawaited(_startScanner());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_stopScanner());
    }
  }

  Future<void> _completeScan(String rawValue) async {
    if (_hasCompleted) return;

    final barcode = normalizeScannedBarcode(rawValue);
    if (barcode == null) return;

    _hasCompleted = true;
    if (_usesPhysicalCamera) await _stopScanner();
    if (!mounted) return;
    Navigator.of(context).pop(barcode);
  }

  void _handleCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = normalizeScannedBarcode(barcode.rawValue);
      if (value != null) {
        unawaited(_completeScan(value));
        return;
      }
    }
  }

  ScannerFailureType _mapFailure(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        ScannerFailureType.permissionDenied,
      MobileScannerErrorCode.unsupported => ScannerFailureType.unsupported,
      _ => ScannerFailureType.unavailable,
    };
  }

  Future<void> _restartScanner() async {
    await _stopScanner();
    await _startScanner();
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
    } on MobileScannerException {
      // The controller publishes the native error for ScannerErrorView.
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _controller.stop();
    } on MobileScannerException {
      // Stopping an unavailable camera must not block navigation or lifecycle.
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } on MobileScannerException {
      // The scanner remains usable when a device cannot toggle its torch.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport =
        widget.viewportBuilder?.call(context, (value) {
          unawaited(_completeScan(value));
        }) ??
        MobileScanner(
          controller: _controller,
          fit: BoxFit.cover,
          tapToFocus: true,
          onDetect: _handleCapture,
          errorBuilder: (_, _) =>
              const ColoredBox(color: ScanFairTokens.bgDeep),
          placeholderBuilder: (_) => const ColoredBox(
            color: ScanFairTokens.bgDeep,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        );

    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        final failure = _usesPhysicalCamera && state.error != null
            ? _mapFailure(state.error!)
            : null;

        return Scaffold(
          backgroundColor: ScanFairTokens.bgDeep,
          body: Stack(
            fit: StackFit.expand,
            children: [
              viewport,
              if (failure == null) ...[
                const IgnorePointer(child: _ScannerOverlay()),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ScanFairTokens.space4),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ScannerControlButton(
                              icon: Icons.close,
                              tooltip: 'Scanner schließen',
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            if (_usesPhysicalCamera)
                              _ScannerControlButton(
                                icon: state.torchState == TorchState.on
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                tooltip: 'Licht umschalten',
                                onPressed:
                                    state.torchState != TorchState.unavailable
                                    ? () => unawaited(_toggleTorch())
                                    : null,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(ScanFairTokens.space4),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(14, 27, 23, 0.88),
                            borderRadius: BorderRadius.circular(
                              ScanFairTokens.radiusSm,
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Barcode in den Rahmen halten',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ScanFairTokens.fsMd,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: ScanFairTokens.space1),
                              Text(
                                'Der Scan startet automatisch.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ScanFairTokens.green100,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                ScannerErrorView(
                  failure: failure,
                  onRetry: _restartScanner,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ScannerErrorView extends StatelessWidget {
  const ScannerErrorView({
    required this.failure,
    required this.onBack,
    this.onRetry,
    super.key,
  });

  final ScannerFailureType failure;
  final VoidCallback onBack;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (failure) {
      ScannerFailureType.permissionDenied => (
        'Kamerazugriff fehlt',
        'Erlaube den Kamerazugriff unter Einstellungen > ScanFair > Kamera. '
            'ScanFair speichert keine Bilder.',
      ),
      ScannerFailureType.unsupported => (
        'Keine Kamera verfügbar',
        'Auf diesem Gerät kann der Barcode-Scanner nicht verwendet werden.',
      ),
      ScannerFailureType.unavailable => (
        'Scanner nicht verfügbar',
        'Die Kamera konnte nicht gestartet werden. Versuche es erneut oder '
            'gib den Barcode manuell ein.',
      ),
    };

    return ColoredBox(
      color: ScanFairTokens.bgDeep,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(ScanFairTokens.space5),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - ScanFairTokens.space6,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.no_photography_outlined,
                        size: 48,
                        color: ScanFairTokens.green200,
                      ),
                      const SizedBox(height: ScanFairTokens.space4),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: ScanFairTokens.space2),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ScanFairTokens.green100),
                      ),
                      const SizedBox(height: ScanFairTokens.space5),
                      if (onRetry != null)
                        FilledButton.icon(
                          onPressed: () => unawaited(onRetry!()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut prüfen'),
                        ),
                      TextButton(
                        onPressed: onBack,
                        child: const Text(
                          'Barcode manuell eingeben',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 292,
        height: 172,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(ScanFairTokens.radiusSm),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 123, 92, 0.55),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerControlButton extends StatelessWidget {
  const _ScannerControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: const Color.fromRGBO(14, 27, 23, 0.82),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        minimumSize: const Size.square(48),
      ),
    );
  }
}
