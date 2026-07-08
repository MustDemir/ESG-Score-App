import 'package:flutter/material.dart';

import '../theme/scanfair_tokens.dart';
import '../theme/scanfair_typography.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.barcode, super.key});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Produkt nicht gefunden')),
      body: ListView(
        padding: const EdgeInsets.all(ScanFairTokens.space4),
        children: [
          const SizedBox(height: ScanFairTokens.space5),
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ScanFairTokens.bgAlt,
              borderRadius: BorderRadius.circular(ScanFairTokens.radius2xl),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 44),
          ),
          const SizedBox(height: ScanFairTokens.space5),
          Text(
            'Noch nicht in der Datenbank',
            style: ScanFairTypography.eyebrow,
          ),
          const SizedBox(height: ScanFairTokens.space3),
          Text(
            'Dieses Produkt kennen wir noch nicht.',
            style: textTheme.displaySmall,
          ),
          const SizedBox(height: ScanFairTokens.space3),
          Text('Barcode: $barcode', style: textTheme.bodyMedium),
          const SizedBox(height: ScanFairTokens.space5),
          _OptionTile(
            icon: Icons.add_a_photo_outlined,
            title: 'Foto ergänzen',
            subtitle: 'Für spätere Crowdsourcing-Funktion vorbereitet',
          ),
          const SizedBox(height: ScanFairTokens.space2),
          _OptionTile(
            icon: Icons.edit_note_outlined,
            title: 'Manuell hinzufügen',
            subtitle: 'Produktdaten lokal vormerken',
          ),
          const SizedBox(height: ScanFairTokens.space2),
          _OptionTile(
            icon: Icons.factory_outlined,
            title: 'Hersteller anfragen',
            subtitle: 'Datenlücke transparent machen',
          ),
          const SizedBox(height: ScanFairTokens.space5),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.qr_code_scanner_outlined),
            label: const Text('Weiter scannen'),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
