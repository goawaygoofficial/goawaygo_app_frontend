import 'package:flutter/material.dart';

class RentalsFormControllersUtils {
  static void swapControllers(
    TextEditingController controllerA,
    TextEditingController controllerB,
  ) {
    final temp = controllerA.text;
    controllerA.text = controllerB.text;
    controllerB.text = temp;
  }
}
