import 'package:flutter/material.dart';

/// Button zum Ein-/Ausklappen aller Gruppen in einer Liste.
class CollapseButton extends StatelessWidget {
  const CollapseButton({super.key, required this.collapsed, required this.onTap});
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          collapsed ? Icons.unfold_more : Icons.unfold_less,
          size: 16,
        ),
        label: Text(collapsed ? 'Alle ausklappen' : 'Alle einklappen'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// Überschrift für eine Sektion in einer Liste.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, this.icon, {super.key});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Scrollbare Leeransicht (kompatibel mit RefreshIndicator).
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

/// Fehleransicht mit Retry-Button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text('Fehler beim Laden:\n$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                    onPressed: onRetry, child: const Text('Erneut versuchen')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
