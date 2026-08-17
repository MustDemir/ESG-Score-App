import 'dart:async';

import 'package:flutter/material.dart';

import '../accessibility/semantic_terminology.dart';
import '../models/esg_score.dart';
import '../models/product.dart';
import '../services/esg_score_calculator.dart';
import '../services/product_lookup_failure.dart';
import '../services/product_repository.dart';
import '../theme/scanfair_tokens.dart';
import '../theme/scanfair_typography.dart';
import '../widgets/score_widgets.dart';
import 'detail_screen.dart';
import 'low_data_screen.dart';
import 'lookup_error_screen.dart';
import 'not_found_screen.dart';
import 'result_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.repository,
    required this.calculator,
    this.scannerViewportBuilder,
    super.key,
  });

  final ProductRepository repository;
  final ESGScoreCalculator calculator;
  final ScannerViewportBuilder? scannerViewportBuilder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _barcodeController = TextEditingController();
  var _isLoading = false;
  var _scannerOpen = false;
  var _detailsOpen = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _openBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty || _isLoading) return;

    // Schleife statt Callback-Rekursion: "Erneut versuchen" auf dem
    // Fehler-Screen liefert true zurueck und startet den Lookup neu.
    while (true) {
      final result = await _lookup(normalizedBarcode);
      if (!mounted) return;

      final failure = result.failure;
      if (failure != null) {
        final retry = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => LookupErrorScreen(failure: failure),
          ),
        );
        if (retry == true && mounted) continue;
        return;
      }

      final product = result.product;
      if (product == null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => NotFoundScreen(barcode: normalizedBarcode),
          ),
        );
        return;
      }

      final score = widget.calculator.calculate(product);
      if (score.state == ScoreState.dataIncomplete) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => LowDataScreen(product: product, score: score),
          ),
        );
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            product: product,
            score: score,
            alternative: widget.repository.suggestAlternativeFor(product),
            onOpenDetails: () => unawaited(_openDetails(product, score)),
          ),
        ),
      );
      return;
    }
  }

  Future<({ScanFairProduct? product, ProductLookupFailure? failure})> _lookup(
    String barcode,
  ) async {
    setState(() => _isLoading = true);
    try {
      final product = await widget.repository.findByBarcode(barcode);
      return (product: product, failure: null);
    } on ProductLookupFailure catch (error) {
      return (product: null, failure: error);
    } on Object catch (error) {
      // Letzte Verteidigungslinie (FM-17): unerwartete Fehler wie TLS- oder
      // Mapping-Ausnahmen duerfen die App nicht dauerhaft sperren.
      return (
        product: null,
        failure: ProductLookupFailure(
          type: ProductLookupFailureType.invalidResponse,
          message:
              'Bei der Produktabfrage ist ein unerwarteter Fehler '
              'aufgetreten. Bitte versuche es erneut.',
          cause: error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetails(ScanFairProduct product, ESGScore score) async {
    if (_detailsOpen || !mounted) return;
    _detailsOpen = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DetailScreen(product: product, score: score),
        ),
      );
    } finally {
      _detailsOpen = false;
    }
  }

  Future<void> _openScanner() async {
    if (_isLoading || _scannerOpen) return;

    // Guard gegen Doppel-Tap: zwei ScannerScreens wuerden um die einzige
    // Kamera-Session konkurrieren und eine tote Preview hinterlassen.
    _scannerOpen = true;
    final String? barcode;
    try {
      barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) =>
              ScannerScreen(viewportBuilder: widget.scannerViewportBuilder),
        ),
      );
    } finally {
      _scannerOpen = false;
    }
    if (!mounted || barcode == null) return;
    await _openBarcode(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final recentProducts = widget.repository.recentProducts();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ScanFairTokens.space4),
          children: [
            Row(
              children: [
                TerminologyText('ScanFair', style: textTheme.titleLarge),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: ScanFairTokens.green50,
                  child: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ScanFairTokens.space5),
            Text('Heute im Wagen', style: ScanFairTypography.eyebrow),
            const SizedBox(height: ScanFairTokens.space2),
            Text("Was gibt's heute im Wagen?", style: textTheme.displayMedium),
            const SizedBox(height: ScanFairTokens.space5),
            _PrimaryScanButton(
              isLoading: _isLoading,
              onPressed: () => unawaited(_openScanner()),
            ),
            const SizedBox(height: ScanFairTokens.space4),
            _ManualBarcodeCard(
              controller: _barcodeController,
              isLoading: _isLoading,
              onSubmit: () => unawaited(_openBarcode(_barcodeController.text)),
            ),
            const SizedBox(height: ScanFairTokens.space5),
            Text('Was du scannen kannst', style: textTheme.titleMedium),
            const SizedBox(height: ScanFairTokens.space3),
            const Row(
              children: [
                _ScanCategory(
                  label: 'Lebensmittel',
                  icon: Icons.restaurant_outlined,
                ),
                SizedBox(width: ScanFairTokens.space2),
                _ScanCategory(
                  label: 'Kleidung',
                  icon: Icons.checkroom_outlined,
                ),
                SizedBox(width: ScanFairTokens.space2),
                _ScanCategory(label: 'Kosmetik', icon: Icons.spa_outlined),
              ],
            ),
            const SizedBox(height: ScanFairTokens.space5),
            if (recentProducts.isNotEmpty) ...[
              Text('Zuletzt gescannt', style: textTheme.titleMedium),
              const SizedBox(height: ScanFairTokens.space3),
              ...recentProducts.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: ScanFairTokens.space2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      ScanFairTokens.radiusLg,
                    ),
                    onTap: _isLoading
                        ? null
                        : () => unawaited(_openBarcode(product.barcode)),
                    child: ProductSummaryCard(product: product, compact: true),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryScanButton extends StatelessWidget {
  const _PrimaryScanButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(ScanFairTokens.space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScanFairTokens.radiusXl),
          ),
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              const Icon(Icons.qr_code_scanner_outlined),
            const SizedBox(width: ScanFairTokens.space3),
            Expanded(
              child: Text(isLoading ? 'Scan wird geprüft' : 'Barcode scannen'),
            ),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class _ManualBarcodeCard extends StatelessWidget {
  const _ManualBarcodeCard({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  hintText: 'z. B. 4025500287955',
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: ScanFairTokens.space3),
            IconButton.filled(
              onPressed: isLoading ? null : onSubmit,
              icon: const Icon(Icons.search),
              tooltip: 'Barcode prüfen',
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCategory extends StatelessWidget {
  const _ScanCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(ScanFairTokens.space3),
        decoration: BoxDecoration(
          color: ScanFairTokens.bgCard,
          border: Border.all(color: ScanFairTokens.border),
          borderRadius: BorderRadius.circular(ScanFairTokens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
