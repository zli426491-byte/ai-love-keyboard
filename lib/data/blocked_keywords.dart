/// Blocked keyword lists for content safety filtering.
/// Organized by category and language for the content filter.
///
/// Languages covered: zh-Hant (Traditional Chinese), en (English),
/// ja (Japanese), ko (Korean).
///
/// IMPORTANT: These lists are intentionally kept focused to reduce
/// false positives while catching genuinely harmful content.
class BlockedKeywords {
  BlockedKeywords._();

  // ══════════════════════════════════════════════════════════════════════
  // CATEGORY 1: Sexually explicit content
  // ══════════════════════════════════════════════════════════════════════

  static const List<String> sexuallyExplicit = [
    // zh-Hant
    '做愛', '性交', '口交', '肛交', '打砲', '約砲', '裸照',
    '自慰', '手淫', '色情片', 'A片', '援交', '性服務',
    '叫床', '情色', '裸體', '露點', '性愛影片', '成人影片',
    '一夜情', '炮友', '性奴', '調教', '捆綁',
    // en
    'porn', 'pornography', 'nude photo', 'sex tape', 'blowjob',
    'handjob', 'anal sex', 'orgasm', 'masturbat', 'erotic',
    'hentai', 'xxx', 'nsfw', 'onlyfans', 'escort service',
    'sexual intercourse', 'strip naked',
    // ja
    'セックス', 'エロ動画', 'アダルト', 'ポルノ', '裸体',
    '風俗', 'ソープ', 'デリヘル', 'オナニー',
    // ko
    '섹스', '포르노', '성인물', '야동', '자위',
    '성매매', '유흥업소',
  ];

  // ══════════════════════════════════════════════════════════════════════
  // CATEGORY 2: Violence and harassment
  // ══════════════════════════════════════════════════════════════════════

  static const List<String> violenceHarassment = [
    // zh-Hant
    '殺了', '殺掉', '打死', '弄死', '去死', '砍死',
    '跟蹤', '偷拍', '偷窺', '騷擾', '恐嚇', '威脅',
    '報復', '毀容', '潑硫酸', '下毒', '綁架',
    '強暴', '性侵', '強姦', '非禮',
    // en
    'kill you', 'murder', 'stalk', 'stalking', 'harass',
    'threaten', 'rape', 'assault', 'kidnap', 'acid attack',
    'revenge porn', 'blackmail', 'doxxing', 'dox',
    'spy on', 'hidden camera',
    // ja
    'ストーカー', '殺す', '脅迫', '盗撮', 'レイプ',
    '誘拐', '嫌がらせ', '復讐ポルノ',
    // ko
    '스토킹', '살해', '협박', '몰카', '강간',
    '납치', '보복', '도촬',
  ];

  // ══════════════════════════════════════════════════════════════════════
  // CATEGORY 3: Illegal activity
  // ══════════════════════════════════════════════════════════════════════

  static const List<String> illegalActivity = [
    // zh-Hant
    '毒品', '販毒', '吸毒', '迷藥', '安非他命', '大麻',
    '搖頭丸', 'K粉', '迷姦藥', '迷奸藥', '下藥',
    '偽造', '洗錢', '詐騙', '賭博網站',
    // en
    'drug deal', 'cocaine', 'heroin', 'meth', 'ecstasy',
    'date rape drug', 'roofie', 'rohypnol', 'ghb',
    'spike drink', 'drug someone', 'forge document',
    'money launder', 'fraud scheme',
    // ja
    '薬物', '覚醒剤', '大麻', '睡眠薬を飲ませ',
    '詐欺', 'マネーロンダリング',
    // ko
    '마약', '각성제', '대마초', '수면제를 넣',
    '사기', '자금세탁',
  ];

  // ══════════════════════════════════════════════════════════════════════
  // CATEGORY 4: Minor-related content (STRONGEST FILTER)
  // ══════════════════════════════════════════════════════════════════════

  static const List<String> minorRelated = [
    // zh-Hant
    '未成年', '小學生', '國中生', '國小', '兒童色情',
    '蘿莉', '正太', '幼女', '幼童', '童貞', '童真',
    '戀童', '兒少', '未滿18', '未滿十八',
    // en
    'underage', 'minor', 'child porn', 'pedophil', 'loli',
    'shota', 'jailbait', 'preteen', 'kiddie',
    'child exploit', 'under 18', 'under eighteen',
    // ja
    'ロリコン', 'ショタコン', '児童ポルノ', '未成年',
    '小学生', '中学生', 'ペドフィリア',
    // ko
    '미성년', '아동 포르노', '소아성애', '로리콘',
    '쇼타콘', '초등학생',
  ];

  // ══════════════════════════════════════════════════════════════════════
  // CATEGORY 5: Manipulation / abusive tactics
  // ══════════════════════════════════════════════════════════════════════

  static const List<String> manipulativeTactics = [
    // zh-Hant
    'PUA', '情感操控', '煤氣燈', '精神虐待', '情緒勒索',
    '冷暴力', '控制狂', '家暴', '打女人', '打老婆',
    '羞辱', '貶低', '洗腦',
    // en
    'gaslighting', 'love bombing', 'negging', 'emotional abuse',
    'manipulate feelings', 'psychological abuse', 'domestic violence',
    'hit your partner', 'control her', 'control him',
    'make her jealous', 'make him jealous', 'play mind games',
    'guilt trip', 'isolate from friends',
    // ja
    'ガスライティング', '精神的虐待', 'マインドコントロール',
    'DV', 'モラハラ',
    // ko
    '가스라이팅', '정서적 학대', '세뇌', '정신적 학대',
  ];

  // ══════════════════════════════════════════════════════════════════════
  // CATEGORY 6: Suicide / self-harm (for detection / warning, not block)
  // ══════════════════════════════════════════════════════════════════════

  static const List<String> suicideSelfHarm = [
    // zh-Hant
    '自殺', '自殘', '割腕', '跳樓', '燒炭', '上吊',
    '不想活', '想死', '活不下去', '結束生命',
    '吃安眠藥', '尋短',
    // en
    'kill myself', 'suicide', 'self-harm', 'cut myself',
    'end my life', 'want to die', 'wrist cut',
    'overdose', 'jump off',
    // ja
    '自殺', '自傷', 'リストカット', '死にたい',
    '飛び降り',
    // ko
    '자살', '자해', '죽고싶', '극단적 선택',
  ];

  /// Mental health hotline info shown when suicide/self-harm is detected.
  static const String mentalHealthHotlineInfo = '''
如果你或你認識的人正在經歷困難，請撥打以下心理健康熱線：

🇹🇼 台灣：1925（安心專線）/ 1980（張老師專線）
🇭🇰 香港：2382 0000（撒瑪利亞防止自殺會）
🇯🇵 日本：0570-064-556（よりそいホットライン）
🇰🇷 韓國：1393（自殺預防諮詢電話）
🌍 International: befrienders.org

你並不孤單，專業的人可以幫助你。❤️''';
}
