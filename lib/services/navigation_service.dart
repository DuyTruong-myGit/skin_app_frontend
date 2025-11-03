import 'package:flutter/material.dart';

class NavigationService {
  // GlobalKey cho phép truy cập Navigator từ bất kỳ đâu
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}