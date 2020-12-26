import 'dart:core';

import 'package:flutter/material.dart';

class Stations with ChangeNotifier {
  List<Stations> _items = [];

  List<Stations> get items {
    return [..._items];
  }

}