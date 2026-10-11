import 'package:app_frontend/features/01_auth_register/screens/auth_screen.dart';
import 'package:app_frontend/features/01_auth_register/sign_out.dart';
import 'package:app_frontend/features/01_auth_register/widgets/feature_item.dart';
import 'package:app_frontend/features/09_profile/screens/user_profile.dart';
import 'package:app_frontend/features/09_profile/widgets/auth_button.dart';
import 'package:app_frontend/features/09_profile/widgets/profile_button.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';

class MyProfile extends StatefulWidget {
  final void Function(bool) toggleBottomBar;
  final UserModel? user;

  const MyProfile({super.key, this.user, required this.toggleBottomBar});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool _showAuthScreen = false;
  bool _showUserProfile = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isLoggedIn = widget.user != null;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.03,
                  horizontal: size.width * 0.06,
                ),
                child: isLoggedIn
                    ? _buildProfileContent(height) // logged in
                    : _buildGuestContent(width, height), // guest view
              ),
            ),
          ),

          SlideFadeTransition(
            visible: _showAuthScreen,
            onClose: () {
              setState(() {
                _showAuthScreen = false;
              });
            },
            child: AuthScreen(
              onClose: () {
                setState(() {
                  _showAuthScreen = false;
                });
              },
            ),
          ),

          SlideFadeTransition(
            visible: _showUserProfile,
            onClose: () {
              setState(() {
                _showUserProfile = false;
                widget.toggleBottomBar(true);
              });
            },
            child: UserProfilePage(
              user: widget.user,
              onClose: () {
                setState(() {
                  _showUserProfile = false;
                  widget.toggleBottomBar(true);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// --- Guest Content (Logo + Feature + Sign In) ---
  Widget _buildGuestContent(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: width * 0.3,
          height: height * 0.25,
        ),
        Column(
          children: const [
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
        ),
        SizedBox(height: height * 0.05),
        AuthButton(
          text: 'SIGN IN',
          bgColor: ColorsUtil.secondary,
          textColor: ColorsUtil.whiteColor,
          onTap: () {
            setState(() {
              _showAuthScreen = true;
              widget.toggleBottomBar(false);
            });
          },
        ),
      ],
    );
  }

  /// --- Logged In Content (Profile Buttons) ---
  Widget _buildProfileContent(double height) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sign out, top-right, styled like the header's notification bell.
        Align(
          alignment: Alignment.centerRight,
          child: SignOutIconButton(
            color: ColorsUtil.secondaryLight,
            size: width * 0.075,
          ),
        ),
        SizedBox(height: height * 0.01),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ProfileButton(
              imagePath: 'assets/icons/mytrips_white.png',
              title: 'My Trips',
              onTap: () {},
            ),
            ProfileButton(
              imagePath: 'assets/icons/recently_viewed.png',
              title: 'Recently Viewed',
              onTap: () {},
            ),
            ProfileButton(
              imagePath: 'assets/icons/saved.png',
              title: 'Saved',
              onTap: () {},
            ),
          ],
        ),
        SizedBox(height: height * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ProfileButton(
              imagePath: 'assets/icons/review.png',
              title: 'Reviews',
              onTap: () {},
            ),
            ProfileButton(
              imagePath: 'assets/icons/rewards.png',
              title: 'Rewards',
              onTap: () {},
            ),
            ProfileButton(
              imagePath: 'assets/icons/user_profile.png',
              title: 'User Profile',
              onTap: () {
                setState(() {
                  _showUserProfile = true;
                  widget.toggleBottomBar(false);
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
