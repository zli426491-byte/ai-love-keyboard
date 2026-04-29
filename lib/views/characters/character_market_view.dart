import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/models/chat_persona.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/views/characters/create_persona_view.dart';
import 'package:ai_love_keyboard/views/components/particle_background.dart';

class CharacterMarketView extends StatefulWidget {
  final ChatPersona? currentPersona;

  const CharacterMarketView({super.key, this.currentPersona});

  @override
  State<CharacterMarketView> createState() => _CharacterMarketViewState();
}

class _CharacterMarketViewState extends State<CharacterMarketView> {
  ChatPersona? _selectedPersona;
  List<ChatPersona> _customPersonas = [];

  @override
  void initState() {
    super.initState();
    _selectedPersona = widget.currentPersona;
    _loadCustomPersonas();
  }

  Future<void> _loadCustomPersonas() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('custom_personas') ?? [];
    setState(() {
      _customPersonas = jsonList
          .map((s) => ChatPersona.fromJson(
                jsonDecode(s) as Map<String, dynamic>,
              ))
          .toList();
    });
  }

  Future<void> _saveCustomPersonas() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        _customPersonas.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('custom_personas', jsonList);
  }

  List<ChatPersona> get _allPersonas => [
        ...ChatPersona.builtInPersonas,
        ..._customPersonas,
      ];

  void _selectPersona(ChatPersona persona) {
    setState(() {
      _selectedPersona =
          _selectedPersona?.id == persona.id ? null : persona;
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedPersona);
  }

  Future<void> _openCreatePersona() async {
    final newPersona = await Navigator.push<ChatPersona>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePersonaView()),
    );
    if (newPersona != null) {
      setState(() {
        _customPersonas.add(newPersona);
      });
      await _saveCustomPersonas();
    }
  }

  Future<void> _deleteCustomPersona(ChatPersona persona) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('刪除人設',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('確定要刪除「${persona.name}」嗎？',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _customPersonas.removeWhere((p) => p.id == persona.id);
        if (_selectedPersona?.id == persona.id) {
          _selectedPersona = null;
        }
      });
      await _saveCustomPersonas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '\u{2728} 角色市場',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: Text(
              _selectedPersona != null ? '確認選擇' : '不使用人設',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const ParticleBackground(particleCount: 12),
          Column(
            children: [
              // ── + Create Custom Button ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                ),
                child: GestureDetector(
                  onTap: _openCreatePersona,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: AppTheme.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFAB47BC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '+ 自訂角色',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              // ── Persona Grid ────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _allPersonas.length,
                  itemBuilder: (context, index) {
                    final persona = _allPersonas[index];
                    final isSelected =
                        _selectedPersona?.id == persona.id;

                    return GestureDetector(
                      onTap: () => _selectPersona(persona),
                      onLongPress: persona.isCustom
                          ? () => _deleteCustomPersona(persona)
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 10, sigmaY: 10),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLg),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accent
                                        .withValues(alpha: 0.6)
                                    : Colors.white
                                        .withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.accent
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  // Large emoji
                                  Text(
                                    persona.emoji,
                                    style:
                                        const TextStyle(fontSize: 40),
                                  ),
                                  const SizedBox(height: 10),
                                  // Name
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      if (persona.isCustom)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(
                                                  right: 4),
                                          child: Icon(
                                            Icons.star,
                                            size: 14,
                                            color: AppTheme.accent,
                                          ),
                                        ),
                                      Flexible(
                                        child: Text(
                                          persona.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                AppTheme.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Description
                                  Text(
                                    persona.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textHint,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  // Use button
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? null
                                          : Colors.white
                                              .withValues(
                                                  alpha: 0.06),
                                      gradient: isSelected
                                          ? AppTheme
                                              .romanticGradient
                                          : null,
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppTheme.radiusFull),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: AppTheme.primary
                                                  .withValues(
                                                      alpha: 0.3),
                                            ),
                                    ),
                                    child: Text(
                                      isSelected ? '使用中' : '使用',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate(
                            delay:
                                Duration(milliseconds: index * 50))
                        .fadeIn(
                            duration:
                                const Duration(milliseconds: 300))
                        .slideY(
                          begin: 0.1,
                          duration:
                              const Duration(milliseconds: 300),
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
