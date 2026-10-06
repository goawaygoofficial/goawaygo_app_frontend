import 'package:flutter/material.dart';

class FlightFormControllersUtils {
  static void swapControllers(
    TextEditingController controllerA,
    TextEditingController controllerB,
  ) {
    final temp = controllerA.text;
    controllerA.text = controllerB.text;
    controllerB.text = temp;
  }

  static void incrementController(TextEditingController? controller) {
    final current = int.tryParse(controller?.text ?? '') ?? 0;
    controller?.text = (current + 1).toString();
  }

  static void decrementController(TextEditingController? controller) {
    final current = int.tryParse(controller?.text ?? '') ?? 0;
    if (current > 0) {
      controller?.text = (current - 1).toString();
    }
  }
}
