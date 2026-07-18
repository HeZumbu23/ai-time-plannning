const String appVersion = '0.1.0';

/// Zeitpunkt des Docker-Builds (UTC, ISO-8601), gesetzt via
/// `--dart-define=BUILD_TIME=...` im Dockerfile. Bei lokalen Builds ohne
/// dieses Define bleibt der Platzhalter stehen.
const String buildTime = String.fromEnvironment(
  'BUILD_TIME',
  defaultValue: 'lokaler Build',
);
