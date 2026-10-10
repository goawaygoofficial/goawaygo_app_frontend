// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

class WanderbookGrid extends StatefulWidget {
  const WanderbookGrid({super.key});

  @override
  State<WanderbookGrid> createState() => _WanderbookGridState();
}

class _WanderbookGridState extends State<WanderbookGrid> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.025,
        vertical: height * 0.025,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, _) => Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          childCount: 6,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: width * 0.025,
          mainAxisSpacing: height * 0.025,
        ),
      ),
    );
  }
}
