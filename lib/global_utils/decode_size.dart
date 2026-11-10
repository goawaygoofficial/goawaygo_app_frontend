import 'package:flutter/widgets.dart';

/// Speed (4.7): network photos are decoded no wider than they are shown. Wanderbook keeps the originals (often
/// 4000 px wide), and decoding those whole would cost tens of megabytes each and make scrolling stutter.
int decodeWidth(BuildContext context, double logicalWidth) =>
    (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();

/// [decodeWidth] for a photo as wide as the screen.
int screenDecodeWidth(BuildContext context) =>
    decodeWidth(context, MediaQuery.sizeOf(context).width);
