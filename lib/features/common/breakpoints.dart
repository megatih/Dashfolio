import 'package:flutter/widgets.dart';

enum ScreenSize {
  compact, // < 600: phone
  medium, // 600–1199: tablet / small window
  expanded; // >= 1200: desktop / wide web

  static const double mediumMin = 600;
  static const double expandedMin = 1200;

  static ScreenSize ofWidth(double w) => w >= expandedMin ? expanded : (w >= mediumMin ? medium : compact);

  static ScreenSize of(BuildContext context) => ofWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;
  bool get isExpanded => this == expanded;
}
