# Flutter ProGuard Rules
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.exoplayer.**
-dontwarn androidx.media3.**
-dontwarn io.agora.**

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.agora.** { *; }
-keep class com.google.android.play.core.** { *; }
