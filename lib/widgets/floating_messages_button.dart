import 'package:flutter/material.dart';

class FloatingMessagesButton extends StatelessWidget {
  const FloatingMessagesButton({
    super.key,
    this.badgeCount = 0,
    this.onPressed,
    this.heroTag = 'messagesFab',
  });

  final int badgeCount;
  final VoidCallback? onPressed;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      width: 68,
      child: FloatingActionButton(
        heroTag: heroTag,
        backgroundColor: const Color(0xFF8D0B15),
        foregroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
        onPressed: onPressed,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 26),
            if (badgeCount > 0)
              Positioned(
                top: -28,
                right: -20,
                child: _Badge(count: badgeCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
