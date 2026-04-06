import 'package:flutter/material.dart';

/// Ekran kengligi bo'yicha breakpointlar
const double kMobileBreak = 600;
const double kTabletBreak = 900;
const double kDesktopBreak = 1200;

/// Kontent uchun maksimal kenglik (wide ekranlarda)
const double kMaxContentWidth = 960.0;

/// Keng ekranda maksimal kenglikda markazlashtirilgan, tor ekranda to'liq kenglik.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kTabletBreak;
        if (!isWide) return child;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        );
      },
    );
  }
}

/// To'liq ekran uchun — fon rangi qoladi, kontent markazlashadi.
class ResponsiveScaffoldBody extends StatelessWidget {
  const ResponsiveScaffoldBody({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
    this.backgroundColor,
  });

  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Breakpoint yordamchilari
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isMobile => screenWidth < kMobileBreak;
  bool get isTablet =>
      screenWidth >= kMobileBreak && screenWidth < kDesktopBreak;
  bool get isDesktop => screenWidth >= kDesktopBreak;
  bool get isWide => screenWidth >= kTabletBreak;
}
