import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDarkTheme = false;

  void toggleTheme() {
    isDarkTheme = !isDarkTheme;
    notifyListeners();
  }

  ThemeData get currentTheme {
    return isDarkTheme ? darkTheme : lightTheme;
  }

  ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          border: const Border(
            bottom: BorderSide(
              color: Colors.white,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      primaryColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          border: const Border(
            bottom: BorderSide(
              color: Colors.black,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
