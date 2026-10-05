# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase (if needed)
-keep class com.google.firebase.** { *; }

# Sentry
-keep class io.sentry.** { *; }

# Modelos y entidades para evitar que gson/json-serializable falle
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
