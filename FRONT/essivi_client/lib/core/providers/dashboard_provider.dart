import 'package:flutter/foundation.dart';

/// Provider pour gérer l'index du BottomNavigationBar du Dashboard
class DashboardProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void goHome() {
    selectTab(0);
  }

  void goOrders() {
    selectTab(1);
  }

  void goCreateOrder() {
    selectTab(2);
  }

  void goProfile() {
    selectTab(3);
  }
}
