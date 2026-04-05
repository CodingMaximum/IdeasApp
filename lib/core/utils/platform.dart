import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

bool get isMobilePlatform {
  if (kIsWeb) return false;

  return Platform.isAndroid || Platform.isIOS;
}

bool get isDesktopPlatform {
  if (kIsWeb) return true;

  return Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;
}