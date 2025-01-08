import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
  ),
);
