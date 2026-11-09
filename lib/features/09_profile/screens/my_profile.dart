import 'package:app_frontend/features/01_auth_register/screens/forgot_password_screen.dart';
import 'package:app_frontend/features/01_auth_register/screens/register_screen.dart';
import 'package:app_frontend/features/01_auth_register/widgets/feature_item.dart';
import 'package:app_frontend/features/01_auth_register/widgets/sign_in_panel.dart';
import 'package:app_frontend/features/09_profile/screens/recently_viewed_screen.dart';
import 'package:app_frontend/features/09_profile/screens/user_profile.dart';
import 'package:app_frontend/features/09_profile/widgets/profile_button.dart';
import 'package:app_frontend/features/09_profile/widgets/verify_email_banner.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/legal_links.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Profile tab. Signed out, it signs in right here with the same panel as the sign-in screen; signed in, it
/// shows the profile tiles. Sign out lives on the User Profile page only.
class MyProfile extends StatefulWidget {
  final void Function(bool) toggleBottomBar;

  /// Opens the My Trips tab.
  final VoidCallback onOpenTrips;

  const MyProfile({
    super.key,
    required this.toggleBottomBar,
    required this.onOpenTrips,
  });

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool _showUserProfile = false;
  bool _showRegister = false;
  bool _showForgotPassword = false;

  void _open(void Function() show) {
    setState(show);
    widget.toggleBottomBar(false);
  }

  void _closeOverlays() {
    setState(() {
      _showUserProfile = false;
      _showRegister = false;
      _showForgotPassword = false;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    widget.toggleBottomBar(true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Follows sign-in / sign-out as it happens (signing in here keeps the user on this tab).
    final user = context.watch<UserProvider>().user;

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
                child: user != null
                    ? _buildProfileContent(user.name, height)
                    : _buildGuestContent(width, height),
              ),
            ),
          ),

          // Signed out: Register / Forgot Password from the sign-in panel.
          SlideFadeTransition(
            visible: _showRegister,
            onClose: _closeOverlays,
            child: RegisterScreen(onBack: _closeOverlays),
          ),
          SlideFadeTransition(
            visible: _showForgotPassword,
            onClose: _closeOverlays,
            child: ForgotPasswordScreen(onBack: _closeOverlays),
          ),

          SlideFadeTransition(
            visible: _showUserProfile,
            onClose: _closeOverlays,
            child: UserProfilePage(user: user, onClose: _closeOverlays),
          ),
        ],
      ),
    );
  }

  /// --- Signed out: logo, features and the sign-in panel ---
  Widget _buildGuestContent(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: width * 0.3,
          height: height * 0.2,
        ),
        const FeatureList(),
        SizedBox(height: height * 0.03),
        SignInPanel(
          onSignedIn: (_) {}, // Stay on Profile; it rebuilds as signed in.
          onRegister: () => _open(() => _showRegister = true),
          onForgotPassword: () => _open(() => _showForgotPassword = true),
        ),
        const LegalFooter(),
      ],
    );
  }

  /// --- Signed in: profile tiles ---
  Widget _buildProfileContent(String name, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo header, as on the other tabs and the website.
        Image.asset('assets/images/logo.png', height: height * 0.12),
        const VerifyEmailBanner(),
        SizedBox(height: height * 0.02),
        Text(
          'Hi, $name',
          style: const TextStyle(
            color: ColorsUtil.whiteColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: height * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // Tiles line up at the top even when one says "Coming soon".
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileButton(
              imagePath: 'assets/icons/mytrips_white.png',
              title: 'My Trips',
              onTap: widget.onOpenTrips,
            ),
            ProfileButton(
              imagePath: 'assets/icons/recently_viewed.png',
              title: 'Recently Viewed',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RecentlyViewedScreen(),
                ),
              ),
            ),
            ProfileButton(imagePath: 'assets/icons/saved.png', title: 'Saved'),
          ],
        ),
        SizedBox(height: height * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // Tiles line up at the top even when one says "Coming soon".
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileButton(
              imagePath: 'assets/icons/review.png',
              title: 'Reviews',
            ),
            ProfileButton(
              imagePath: 'assets/icons/rewards.png',
              title: 'Rewards',
            ),
            ProfileButton(
              imagePath: 'assets/icons/user_profile.png',
              title: 'User Profile',
              onTap: () => _open(() => _showUserProfile = true),
            ),
          ],
        ),
        SizedBox(height: height * 0.03),
        const Center(child: LegalFooter()),
      ],
    );
  }
}
