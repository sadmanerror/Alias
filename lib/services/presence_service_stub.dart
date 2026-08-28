/// Stub implementation for non-web platforms.
void registerWebPresence({
  required void Function() onOnline,
  required void Function() onOffline,
}) {
  // No-op on non-web platforms
}

/// Stub check for non-web platforms
bool isBrowserOnline() => true;
