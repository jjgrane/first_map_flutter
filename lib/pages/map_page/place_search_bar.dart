import 'dart:ui';
import 'package:flutter/material.dart';

class PlaceSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final String? displayText;

  const PlaceSearchBar({
    super.key,
    required this.onTap,
    this.displayText,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final showText = displayText != null && displayText!.trim().isNotEmpty;
    final textColor = showText ? Colors.black : Colors.grey;
    final text = showText ? displayText! : "Buscar lugar...";

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          // Fondo desenfocado
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: statusBarHeight + 85, // 85 para incluir el buscador con algo de margen
            color: Colors.white.withOpacity(0.6),
            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 0), // 👈 justo debajo del notch
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
