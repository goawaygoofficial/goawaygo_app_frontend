import 'package:flutter/material.dart';

class FeatureItem extends StatelessWidget {
  final String icon;
  final String text;

  const FeatureItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            icon,
            width: width * 0.1,
            height: width * 0.1,
            fit: BoxFit.contain,
          ),
          SizedBox(width: width * 0.02),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The three selling points shown above the sign-in panel (sign-in screen and signed-out Profile).
class FeatureList extends StatelessWidget {
  const FeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FeatureItem(
          icon: 'assets/images/auth_image_01.png',
          text: 'Travel the World in Your Terms',
        ),
        FeatureItem(
          icon: 'assets/images/auth_image_02.png',
          text: 'Personalised Travel Plans',
        ),
        FeatureItem(
          icon: 'assets/images/auth_image_03.png',
          text: 'Your Own WanderBook',
        ),
      ],
    );
  }
}
