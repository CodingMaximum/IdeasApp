import 'package:flutter/foundation.dart';

bool get isMobilePlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

bool get isDesktopPlatform {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// True für Web — dort wird Supabase als Datenbasis verwendet.
/// Native (Mobile + Desktop) arbeitet mit lokalem Drift-Store.
bool get usesRemoteRepository => kIsWeb;