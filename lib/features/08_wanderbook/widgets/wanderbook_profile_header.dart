import 'package:app_frontend/features/08_wanderbook/widgets/stat_item.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class WanderbookProfileHeader extends StatelessWidget {
  final double shrinkOffset;
  final double maxExtent;

  const WanderbookProfileHeader({
    super.key,
    required this.shrinkOffset,
    required this.maxExtent,
  });

  double get progress => (shrinkOffset / maxExtent).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    // Smooth easing
    final curved = Curves.easeOut.transform(1 - progress);
    final opacity = curved;
    final scale = 0.85 + (0.15 * curved);
    final translateY = -60 * (1 - curved);

    return SizedBox.expand(
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: opacity,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                /// Backdrop
                Positioned(
                  top: height * 0.01,
                  left: width * 0.025,
                  right: width * 0.025,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/home_image_01.png',
                      height: height * 0.2,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                /// Camera button (bottom-left of backdrop)
                Positioned(
                  top:
                      height * 0.01 +
                      height * 0.2 -
                      height * 0.06, // imageTop + imageHeight - buttonSize
                  left: width * 0.05,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: width * 0.09,
                      height: width * 0.09,
                      decoration: BoxDecoration(
                        color: ColorsUtil.whiteColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 28,
                        color: ColorsUtil.secondary,
                      ),
                    ),
                  ),
                ),

                /// Avatar
                Positioned(
                  top: height * 0.01 + height * 0.22 - height * 0.06,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: ColorsUtil.secondary,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: ColorsUtil.whiteColor,
                    ),
                  ),
                ),

                /// Name + Location
                Positioned(
                  top: height * 0.01 + height * 0.22 + height * 0.06,
                  child: Column(
                    children: [
                      Text(
                        "SIKANDAR RAJAJI",
                        style: TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        "IBIZA, SPAIN",
                        style: TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Stats + Bio
                Positioned(
                  top: height * 0.01 + height * 0.22 + height * 0.13,
                  left: width * 0.05,
                  right: width * 0.05,
                  child: Opacity(
                    opacity: opacity * 0.9,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - curved)),
                      child: Column(
                        children: [
                          /// Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              StatItem(count: "212", label: "Posts"),
                              StatItem(count: "14.2K", label: "Followers"),
                              StatItem(count: "88", label: "Following"),
                            ],
                          ),

                          SizedBox(height: height * 0.008),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "🌍 Living for the thrill of new places\n🎯 Culture | Adventure | Stories",
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    color: ColorsUtil.whiteColor,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                              /// ✏️ Edit icon
                              GestureDetector(
                                onTap: () {
                                  // TODO: open edit bio flow
                                },
                                child: CircleAvatar(
                                  backgroundColor: ColorsUtil.secondary,
                                  radius: 20,
                                  child: Center(
                                    child: Icon(
                                      Icons.edit,
                                      color: ColorsUtil.whiteColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
