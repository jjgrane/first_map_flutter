import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class PlaceSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final String displayText;

  const PlaceSearchBar({
    super.key,
    required this.onTap,
    required this.displayText,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black;
    final text = displayText;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                    'assets/icons/F_ISO_Celeste_Naranja.svg',
                    width: 30,
                    height: 30,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Merino',
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
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
