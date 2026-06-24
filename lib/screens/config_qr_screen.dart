import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/app_config.dart';

/// Erfasst die Supabase-Verbindungsdaten per QR-Code oder manueller Eingabe.
///
/// Pop-Ergebnis: `({String url, String anonKey})?`
///   - `null`  -> abgebrochen
///   - Record  -> gültige, noch **nicht** gespeicherte Werte (der Aufrufer
///                entscheidet, ob er sie speichert / die App neu initialisiert)
class ConfigQrScreen extends StatefulWidget {
  const ConfigQrScreen({super.key});

  @override
  State<ConfigQrScreen> createState() => _ConfigQrScreenState();
}

class _ConfigQrScreenState extends State<ConfigQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handled = false;
  bool _manual = false;
  String? _error;

  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final parsed = AppConfig.parsePayload(raw);
      if (parsed != null) {
        _handled = true;
        _controller.stop();
        Navigator.of(context).pop(parsed);
        return;
      }
    }
    if (mounted) {
      setState(() => _error = 'QR-Code erkannt, aber kein gültiges Config-JSON.');
    }
  }

  void _submitManual() {
    final parsed = AppConfig.parsePayload(
      '{"supabaseUrl": ${_jsonString(_urlCtrl.text.trim())}, '
      '"supabaseAnonKey": ${_jsonString(_keyCtrl.text.trim())}}',
    );
    if (parsed == null) {
      setState(() => _error = 'URL muss mit http beginnen und der Key darf nicht leer sein.');
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  static String _jsonString(String s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verbindung einrichten'),
        actions: [
          IconButton(
            tooltip: _manual ? 'QR-Scanner' : 'Manuell eingeben',
            icon: Icon(_manual ? Icons.qr_code_scanner : Icons.keyboard),
            onPressed: () => setState(() {
              _manual = !_manual;
              _error = null;
            }),
          ),
        ],
      ),
      body: _manual ? _buildManual() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Kamera nicht verfügbar:\n${error.errorCode.name}\n\n'
                      'Nutze stattdessen die manuelle Eingabe (Tastatur-Symbol oben).',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error ?? 'Scanne den Config-QR-Code aus tools/make_config_qr.py.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _error != null ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManual() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Supabase-URL'),
          const SizedBox(height: 6),
          TextField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'https://xxxx.supabase.co',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Anon / Publishable Key'),
          const SizedBox(height: 6),
          TextField(
            controller: _keyCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'eyJhbGciOi...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitManual,
            icon: const Icon(Icons.check),
            label: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
