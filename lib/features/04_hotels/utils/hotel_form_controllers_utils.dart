import 'package:flutter/material.dart';

class HotelFormControllersUtils {
  static void swapControllers(
    TextEditingController controllerA,
    TextEditingController controllerB,
  ) {
    final temp = controllerA.text;
    controllerA.text = controllerB.text;
    controllerB.text = temp;
  }
}
