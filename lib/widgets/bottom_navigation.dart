import 'package:flutter/material.dart';
import 'package:flutter_keiko/pages/home/home.dart';
import 'package:flutter_keiko/pages/pomodoro/pomodoro_config.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigationBar({super.key, required this.currentIndex});

  void _navigateToPage(BuildContext context, int index) {
    if (index == currentIndex) return; // Si el índice es el mismo, no navega.

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const Home();
        break;
      case 1:
        targetPage = const PomodoroConfig();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).bottomNavigationBarTheme;

    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timer),
          label: 'Pomodoro',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: theme.selectedItemColor,
      unselectedItemColor: theme.unselectedItemColor,
      backgroundColor: theme.backgroundColor,
      onTap: (index) => _navigateToPage(context, index),
    );
  }
}
