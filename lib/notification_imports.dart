// This file provides compatibility definitions for flutter_local_notifications package

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Export all flutter_local_notifications symbols
export 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Define our own enums that match the package's expected values
enum UILocalNotificationDateInterpretation { absoluteTime, wallClockTime }

// Define Android schedule mode enum
enum AndroidScheduleMode {
  exact,
  exactAllowWhileIdle,
  inexact,
  inexactAllowWhileIdle,
}
