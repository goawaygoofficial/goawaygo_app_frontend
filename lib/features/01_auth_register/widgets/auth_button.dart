import 'package:flutter/material.dart';

class AuthButton extends StatefulWidget {
  final String icon;
  final String text;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const AuthButton({
    super.key,
    required this.icon,
    required this.text,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: double.infinity,
      height: height * 0.07,
      child: ElevatedButton.icon(
        onPressed: widget.onTap,
        icon: Image.asset(widget.icon, width: width * 0.05),
        label: Text(
          widget.text,
          style: TextStyle(
            fontSize: 18,
            color: widget.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
      ),
    );
  }
}
