import 'package:app_frontend/features/09_profile/widgets/profile_field.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onClose;
  const UserProfilePage({super.key, this.user, required this.onClose});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.01),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: width * 0.2,
                    height: height * 0.15,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/user_profile.png',
                        width: width * 0.08,
                        height: height * 0.08,
                      ),
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      size: width * 0.075,
                      color: ColorsUtil.secondaryLight,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        ProfileField(
                          label: 'Email',
                          value: 'tripkaro@gmail.com',
                        ),
                        ProfileField(
                          label: 'Password',
                          value: '**************',
                          isObscured: true,
                        ),
                        ProfileField(
                          label: 'Phone Number',
                          value: '+XX XXXXXXXXXX',
                        ),
                        ProfileField(
                          label: 'Country / Region',
                          value: 'United Kingdom',
                        ),
                        ProfileField(label: 'Currency', value: 'GBP'),
                        ProfileField(
                          label: 'Display Name',
                          value: 'Sikandar Rajaji',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Sign out logic
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF57C2A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onClose,
                          child: const Text(
                            "Back",
                            style: TextStyle(
                              color: ColorsUtil.whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
