import 'package:flutter/material.dart';

import '../accessibility/semantic_terminology.dart';
import '../services/product_lookup_failure.dart';
import '../theme/scanfair_tokens.dart';

class LookupErrorScreen extends StatelessWidget {
  const LookupErrorScreen({
    required this.failure,
    required this.onRetry,
    super.key,
  });

  final ProductLookupFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produktabfrage')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ScanFairTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconFor(failure.type),
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: ScanFairTokens.space4),
              Text(
                _titleFor(failure.type),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: ScanFairTokens.space3),
              TerminologyText(
                failure.message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              if (failure.canRetry)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ),
              const SizedBox(height: ScanFairTokens.space2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zurueck'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(ProductLookupFailureType type) => switch (type) {
    ProductLookupFailureType.invalidBarcode => 'Barcode nicht gueltig',
    ProductLookupFailureType.noConnection => 'Keine Verbindung',
    ProductLookupFailureType.timeout => 'Abfrage dauert zu lange',
    ProductLookupFailureType.rateLimited => 'Bitte kurz warten',
    ProductLookupFailureType.server => 'Dienst nicht erreichbar',
    ProductLookupFailureType.invalidResponse => 'Produktdaten nicht lesbar',
  };

  IconData _iconFor(ProductLookupFailureType type) => switch (type) {
    ProductLookupFailureType.invalidBarcode => Icons.qr_code_2,
    ProductLookupFailureType.noConnection => Icons.wifi_off,
    ProductLookupFailureType.timeout => Icons.timer_off_outlined,
    ProductLookupFailureType.rateLimited => Icons.hourglass_top,
    ProductLookupFailureType.server => Icons.cloud_off_outlined,
    ProductLookupFailureType.invalidResponse => Icons.data_object,
  };
}
