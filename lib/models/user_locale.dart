enum UserLocale {
  taiwan(
    id: 'taiwan',
    name: '台灣',
    emoji: '🇹🇼',
    languageCode: 'zh-TW',
    culturePrompt: '用繁體中文回覆，風格撩人但不油膩，符合台灣年輕人的聊天語感，口語自然、帶點俏皮。',
  ),
  hongkong(
    id: 'hongkong',
    name: '香港',
    emoji: '🇭🇰',
    languageCode: 'zh-HK',
    culturePrompt: '用繁體中文（港式用語）回覆，帶港式幽默感，語氣輕鬆抵死，適當加入廣東話口語。',
  ),
  japan(
    id: 'japan',
    name: '日本',
    emoji: '🇯🇵',
    languageCode: 'ja',
    culturePrompt: '用日本語回覆，風格含蓄委婉，不直接表白但暗示好感，符合日本人的曖昧美學。',
  ),
  korea(
    id: 'korea',
    name: '韓國',
    emoji: '🇰🇷',
    languageCode: 'ko',
    culturePrompt: '用韓國語回覆，風格甜蜜可愛，像韓劇男女主角般撒嬌，帶有애교感。',
  ),
  usa(
    id: 'usa',
    name: '美國',
    emoji: '🇺🇸',
    languageCode: 'en-US',
    culturePrompt: 'Reply in American English. Style: direct, bold, humor-driven. Use casual slang and confident energy.',
  ),
  uk(
    id: 'uk',
    name: '英國',
    emoji: '🇬🇧',
    languageCode: 'en-GB',
    culturePrompt: 'Reply in British English. Style: gentlemanly humour, witty and understated. Dry wit is key.',
  ),
  thailand(
    id: 'thailand',
    name: '泰國',
    emoji: '🇹🇭',
    languageCode: 'th',
    culturePrompt: 'ตอบเป็นภาษาไทย สไตล์หวานๆ โรแมนติก สุภาพ มีมารยาท แต่น่ารัก',
  ),
  vietnam(
    id: 'vietnam',
    name: '越南',
    emoji: '🇻🇳',
    languageCode: 'vi',
    culturePrompt: 'Trả lời bằng tiếng Việt. Phong cách dịu dàng, lãng mạn, chân thành và tình cảm.',
  ),
  indonesia(
    id: 'indonesia',
    name: '印尼',
    emoji: '🇮🇩',
    languageCode: 'id',
    culturePrompt: 'Balas dalam Bahasa Indonesia. Gaya sopan, romantis, dan penuh perhatian.',
  ),
  france(
    id: 'france',
    name: '法國',
    emoji: '🇫🇷',
    languageCode: 'fr',
    culturePrompt: 'Répondez en français. Style romantique et élégant, avec charme et esprit.',
  ),
  spain(
    id: 'spain',
    name: '西班牙',
    emoji: '🇪🇸',
    languageCode: 'es',
    culturePrompt: 'Responde en español. Estilo apasionado y extrovertido, con energía y calidez.',
  ),
  germany(
    id: 'germany',
    name: '德國',
    emoji: '🇩🇪',
    languageCode: 'de',
    culturePrompt: 'Antworte auf Deutsch. Stil: direkt und aufrichtig, ehrlich aber charmant.',
  ),
  brazil(
    id: 'brazil',
    name: '巴西',
    emoji: '🇧🇷',
    languageCode: 'pt-BR',
    culturePrompt: 'Responda em português brasileiro. Estilo caloroso, aberto e apaixonado.',
  ),
  global(
    id: 'global',
    name: '其他',
    emoji: '🌍',
    languageCode: 'en',
    culturePrompt: 'Reply in English with a universal, friendly international style. Be warm, respectful, and culturally neutral.',
  );

  const UserLocale({
    required this.id,
    required this.name,
    required this.emoji,
    required this.languageCode,
    required this.culturePrompt,
  });

  final String id;
  final String name;
  final String emoji;
  final String languageCode;
  final String culturePrompt;

  String get displayName => '$emoji $name';

  static UserLocale fromId(String id) {
    return UserLocale.values.firstWhere(
      (l) => l.id == id,
      orElse: () => UserLocale.global,
    );
  }

  static UserLocale fromSystemLocale(String systemLocale) {
    final lower = systemLocale.toLowerCase().replaceAll('-', '_');

    if (lower.startsWith('zh') && (lower.contains('tw') || lower.contains('hant'))) {
      return UserLocale.taiwan;
    }
    if (lower.startsWith('zh') && lower.contains('hk')) {
      return UserLocale.hongkong;
    }
    if (lower.startsWith('ja')) return UserLocale.japan;
    if (lower.startsWith('ko')) return UserLocale.korea;
    if (lower.startsWith('en') && lower.contains('gb')) return UserLocale.uk;
    if (lower.startsWith('en')) return UserLocale.usa;
    if (lower.startsWith('th')) return UserLocale.thailand;
    if (lower.startsWith('vi')) return UserLocale.vietnam;
    if (lower.startsWith('id') || lower.startsWith('ms')) {
      return UserLocale.indonesia;
    }
    if (lower.startsWith('fr')) return UserLocale.france;
    if (lower.startsWith('es')) return UserLocale.spain;
    if (lower.startsWith('de')) return UserLocale.germany;
    if (lower.startsWith('pt') && lower.contains('br')) return UserLocale.brazil;
    if (lower.startsWith('pt')) return UserLocale.brazil;
    if (lower.startsWith('zh')) return UserLocale.taiwan;

    return UserLocale.global;
  }
}
