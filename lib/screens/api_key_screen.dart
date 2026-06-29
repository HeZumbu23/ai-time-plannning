import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase/supabase.dart';

import '../config/supabase_client.dart';
import '../services/key_storage.dart';

const _supabaseUrl = 'https://vnfkkujtkbgkqafbbipj.supabase.co';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _controller = TextEditingController();
  bool _scanning = false;
  bool _saving = false;
  bool _qrSent = false;
  bool _changingKey = false;
  String? _error;
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _controller.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _error = null;
      _scannerController = MobileScannerController();
    });
  }

  void _stopScan() {
    _scannerController?.dispose();
    setState(() {
      _scanning = false;
      _scannerController = null;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw != null && raw.isNotEmpty) {
      _controller.text = raw.trim();
      _stopScan();
    }
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Bitte einen API-Key eingeben.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      initSupabaseClient(SupabaseClient(_supabaseUrl, key));
      await KeyStorage.saveKey(key);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _error = 'Ungültiger Key: $e';
        _saving = false;
      });
    }
  }

  Future<void> _printQr() async {
    setState(() => _qrSent = false);
    try {
      await http.get(Uri.parse('/api/log-qr'));
      if (mounted) setState(() => _qrSent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR-Endpoint nicht erreichbar.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API-Key')),
      body: _scanning
          ? _buildScanner()
          : (isSupabaseInitialized && !_changingKey)
              ? _buildConfigured()
              : _buildForm(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: _onDetect,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _stopScan,
            child: const Icon(Icons.close),
          ),
        ),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Text(
            'QR-Code im Rahmen positionieren',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigured() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'API-Key konfiguriert',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text('QR-Code in Container-Logs ausgeben'),
                onPressed: _printQr,
              ),
              if (_qrSent) ...[
                const SizedBox(height: 8),
                Text(
                  'QR-Code wurde in die Container-Logs geschrieben.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Key ändern'),
                onPressed: () => setState(() => _changingKey = true),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Zurück zur App'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.vpn_key_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Supabase API-Key',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Gib deinen Supabase Publishable Key ein '
                'oder scanne den QR-Code aus deinen Projekteinstellungen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'API-Key (anon / publishable)',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _controller.clear(),
                  ),
                ),
                minLines: 1,
                maxLines: 3,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR-Code scannen'),
                onPressed: _startScan,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Speichern & verbinden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
