import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class StyleSelector extends StatelessWidget {
  final ReplyStyle selected;
  final ValueChanged<ReplyStyle> onSelected;

  const StyleSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        itemCount: ReplyStyle.values.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppTheme.spacingSm),
        itemBuilder: (context, index) {
          final style = ReplyStyle.values[index];
          final isSelected = style == selected;

          return GestureDetector(
            onTap: () => onSelected(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? style.color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isSelected ? style.color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(style.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    style.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? style.color
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideX(
                begin: 0.2,
                duration: const Duration(milliseconds: 300),
              );
        },
      ),
    );
  }
}
