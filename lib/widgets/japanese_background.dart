import 'package:flutter/material.dart';

class JapaneseBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/japanese_background.jpg"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
