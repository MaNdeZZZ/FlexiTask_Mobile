import 'package:flutter/material.dart';

/// A collection of custom page transitions specifically designed for FlexiTask
class AppTransitions {
  /// Subtle fade transition with slight vertical offset - ideal for task screens
  static Route<T> fadeInTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 220),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Combined fade and slight slide up
        const begin = Offset(0.0, 0.03);
        const end = Offset.zero;
        const fadeCurve = Curves.easeOutSine;
        const slideCurve = Curves.easeOutCubic;

        var slideTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: slideCurve));
        var fadeTween =
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: fadeCurve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      // Keep the background visible during transition for smoother experience
      opaque: false,
      // Disable barrier color for a cleaner look
      barrierDismissible: false,
    );
  }

  /// Clean lateral slide transition - good for navigating between hierarchy levels
  static Route<T> slideTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 200),
    bool rightToLeft = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Direction aware slide
        final begin =
            rightToLeft ? const Offset(0.03, 0.0) : const Offset(-0.03, 0.0);
        const end = Offset.zero;
        const curve = Curves.fastLinearToSlowEaseIn;

        var offsetTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(offsetTween),
            child: child,
          ),
        );
      },
      opaque: true,
    );
  }

  /// Layered transition with subtle elevation - perfect for dialogs and modals
  static Route<T> elevationTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.92;
        const end = 1.0;
        const curve = Curves.easeOutQuint;

        var scaleTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween =
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              color: Colors.transparent,
              elevation: animation.value * 8, // Subtle elevation change
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: ScaleTransition(
                  scale: animation.drive(scaleTween),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
      opaque: false,
      barrierColor: Colors.black12,
    );
  }

  /// Dissolve transition that creates a smooth blend between pages
  static Route<T> dissolveTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Create a dissolve effect with subtle scale
        const curve = Curves.easeInOut;

        // Fade animation
        var fadeTween =
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        // Very subtle scale animation (almost imperceptible but adds depth)
        var scaleTween = Tween(begin: 0.98, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        // Slight brightness/contrast change for more of a dissolve feel
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix([
                1 + animation.value * 0.03,
                0,
                0,
                0,
                0,
                0,
                1 + animation.value * 0.03,
                0,
                0,
                0,
                0,
                0,
                1 + animation.value * 0.03,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: child,
            ),
          ),
        );
      },
      opaque: false,
      barrierColor: Colors.transparent,
      maintainState: true,
    );
  }

  /// Navigation helper for dissolve-style transitions (elegant page transitions)
  static Future<T?> pushDissolve<T>(BuildContext context, Widget page,
      {String? routeName}) {
    return Navigator.of(context).push(
      dissolveTransition<T>(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Replacement navigation with dissolve effect
  static Future<T?> pushReplacementDissolve<T, TO>(
      BuildContext context, Widget page,
      {String? routeName}) {
    return Navigator.of(context).pushReplacement(
      dissolveTransition<T>(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Navigation helper to push a page with the subtle fade + vertical transition
  static Future<T?> push<T>(BuildContext context, Widget page,
      {String? routeName}) {
    return Navigator.of(context).push(
      fadeInTransition<T>(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Navigation helper to replace current page with fade transition
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page,
      {String? routeName}) {
    return Navigator.of(context).pushReplacement(
      fadeInTransition<T>(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  /// Navigation helper to clear all routes with a clean fade transition
  static Future<T?> pushAndRemoveUntil<T>(BuildContext context, Widget page,
      {String? routeName}) {
    return Navigator.of(context).pushAndRemoveUntil(
      fadeInTransition<T>(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
      (route) => false,
    );
  }

  /// Navigation helper specifically for sliding transitions (like going deeper in navigation)
  static Future<T?> pushSlide<T>(BuildContext context, Widget page,
      {String? routeName, bool rightToLeft = true}) {
    return Navigator.of(context).push(
      slideTransition<T>(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
        rightToLeft: rightToLeft,
      ),
    );
  }

  /// Navigation helper for modal-style transitions (like dialogs or detail views)
  static Future<T?> pushElevation<T>(BuildContext context, Widget page,
      {String? routeName}) {
    return Navigator.of(context).push(
      elevationTransition<T>(
        page: page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }
}
