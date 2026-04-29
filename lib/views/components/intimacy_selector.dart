import 'package:flutter/material.dart';

import 'package:ai_love_keyboard/models/chat_persona.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class IntimacySelector extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onChanged;

  const IntimacySelector({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentIntimacy = IntimacyLevel.levels[selectedLevel - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────
        Row(
          children: [
            Text(
              '親密度',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _levelColor(selectedLevel).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${currentIntimacy.name} - ${currentIntimacy.description}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _levelColor(selectedLevel),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // ── Slider ─────────────────────────────────────────────────
        Row(
          children: [
            const Text('😊', style: TextStyle(fontSize: 18)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _levelColor(selectedLevel),
                  inactiveTrackColor:
                      _levelColor(selectedLevel).withValues(alpha: 0.2),
                  thumbColor: _levelColor(selectedLevel),
                  overlayColor:
                      _levelColor(selectedLevel).withValues(alpha: 0.1),
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: selectedLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => onChanged(value.round()),
                ),
              ),
            ),
            const Text('💕', style: TextStyle(fontSize: 18)),
          ],
        ),

        // ── Level Labels ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: IntimacyLevel.levels.map((level) {
              final isSelected = level.level == selectedLevel;
              return Text(
                level.level.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? _levelColor(selectedLevel)
                      : Colors.grey.shade400,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _levelColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF6366F1); // indigo
      case 2:
        return const Color(0xFF2DD4BF); // teal
      case 3:
        return const Color(0xFFFBBF24); // amber
      case 4:
        return const Color(0xFFEC4899); // pink
      case 5:
        return const Color(0xFFEF4444); // red
      default:
        return AppTheme.primary;
    }
  }
}
