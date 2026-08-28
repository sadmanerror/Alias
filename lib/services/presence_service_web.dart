// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web implementation for online/offline and tab close events.
void registerWebPresence({
  required void Function() onOnline,
  required void Function() onOffline,
}) {
  // Tab closed or navigated away
  html.window.onBeforeUnload.listen((_) {
    onOffline();
  });
  html.window.onUnload.listen((_) {
    onOffline();
  });
  // Real internet connectivity drop / recovery
  html.window.onOffline.listen((_) {
    onOffline();
  });
  html.window.onOnline.listen((_) {
    onOnline();
  });
}

/// Check if browser currently has active internet connection
bool isBrowserOnline() {
  return html.window.navigator.onLine ?? true;
}
