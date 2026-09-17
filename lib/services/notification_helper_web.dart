// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void requestWebNotificationPermission() {
  try {
    if (html.Notification.permission != 'granted') {
      html.Notification.requestPermission();
    }
  } catch (_) {}
}

void showWebNotification(String title, String body, {String? tag}) {
  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(
        title,
        body: body,
        tag: tag,
        icon: 'favicon.png',
      );
    }
  } catch (_) {}
}
