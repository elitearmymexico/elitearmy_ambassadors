import 'package:flutter/foundation.dart';

/// Índice del tab actual del BottomNavigationBar.
/// 0 = Dashboard (Inicio), 1 = Mi Red, 2 = Bonos, 3 = Perfil
class AppNav {
  static final tabIndex = ValueNotifier<int>(0);
}
