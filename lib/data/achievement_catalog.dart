import '../models/achievement.dart';

/// Convenience: numeric target achievements.
AchievementDef _num({
  required String id,
  required String name,
  required String description,
  required AchievementCategory category,
  required int essenceReward,
  required double Function(AchContext) current,
  required double target,
}) {
  return AchievementDef(
    id: id,
    name: name,
    description: description,
    category: category,
    essenceReward: essenceReward,
    progress: (ctx) => AchProgress(current(ctx), target),
  );
}

/// Boolean achievements (target = 1).
AchievementDef _bool({
  required String id,
  required String name,
  required String description,
  required AchievementCategory category,
  required int essenceReward,
  required bool Function(AchContext) test,
}) {
  return AchievementDef(
    id: id,
    name: name,
    description: description,
    category: category,
    essenceReward: essenceReward,
    progress: (ctx) => AchProgress(test(ctx) ? 1 : 0, 1),
  );
}

final achievementCatalog = <AchievementDef>[
  // ============ 1. 터치 (6) ============
  _num(
    id: 'tap_10',
    name: '첫 스윙',
    description: '10회 터치',
    category: AchievementCategory.tap,
    essenceReward: 1,
    current: (c) => c.totalTaps.toDouble(),
    target: 10,
  ),
  _num(
    id: 'tap_100',
    name: '몸풀기',
    description: '100회 터치',
    category: AchievementCategory.tap,
    essenceReward: 1,
    current: (c) => c.totalTaps.toDouble(),
    target: 100,
  ),
  _num(
    id: 'tap_1k',
    name: '검의 친구',
    description: '1,000회 터치',
    category: AchievementCategory.tap,
    essenceReward: 2,
    current: (c) => c.totalTaps.toDouble(),
    target: 1000,
  ),
  _num(
    id: 'tap_10k',
    name: '손목 단련',
    description: '10,000회 터치',
    category: AchievementCategory.tap,
    essenceReward: 5,
    current: (c) => c.totalTaps.toDouble(),
    target: 10000,
  ),
  _num(
    id: 'tap_100k',
    name: '폭풍 연타',
    description: '100,000회 터치',
    category: AchievementCategory.tap,
    essenceReward: 10,
    current: (c) => c.totalTaps.toDouble(),
    target: 100000,
  ),
  _num(
    id: 'tap_1m',
    name: '백만 검객',
    description: '1,000,000회 터치',
    category: AchievementCategory.tap,
    essenceReward: 30,
    current: (c) => c.totalTaps.toDouble(),
    target: 1000000,
  ),

  // ============ 2. 골드 (10) ============
  _num(
    id: 'gold_1k',
    name: '첫 1천',
    description: '누적 골드 1K',
    category: AchievementCategory.gold,
    essenceReward: 1,
    current: (c) => c.lifetimeGold,
    target: 1000,
  ),
  _num(
    id: 'gold_100k',
    name: '짤랑짤랑',
    description: '누적 골드 100K',
    category: AchievementCategory.gold,
    essenceReward: 1,
    current: (c) => c.lifetimeGold,
    target: 100000,
  ),
  _num(
    id: 'gold_1m',
    name: '백만장자',
    description: '누적 골드 1M',
    category: AchievementCategory.gold,
    essenceReward: 2,
    current: (c) => c.lifetimeGold,
    target: 1e6,
  ),
  _num(
    id: 'gold_100m',
    name: '부의 상징',
    description: '누적 골드 100M',
    category: AchievementCategory.gold,
    essenceReward: 3,
    current: (c) => c.lifetimeGold,
    target: 1e8,
  ),
  _num(
    id: 'gold_1b',
    name: '십억의 검',
    description: '누적 골드 1B',
    category: AchievementCategory.gold,
    essenceReward: 5,
    current: (c) => c.lifetimeGold,
    target: 1e9,
  ),
  _num(
    id: 'gold_100b',
    name: '국고 관리자',
    description: '누적 골드 100B',
    category: AchievementCategory.gold,
    essenceReward: 8,
    current: (c) => c.lifetimeGold,
    target: 1e11,
  ),
  _num(
    id: 'gold_1t',
    name: '대륙의 상인',
    description: '누적 골드 1T',
    category: AchievementCategory.gold,
    essenceReward: 15,
    current: (c) => c.lifetimeGold,
    target: 1e12,
  ),
  _num(
    id: 'gold_100t',
    name: '황금의 강',
    description: '누적 골드 100T',
    category: AchievementCategory.gold,
    essenceReward: 25,
    current: (c) => c.lifetimeGold,
    target: 1e14,
  ),
  _num(
    id: 'gold_1qa',
    name: '전설의 금고',
    description: '누적 골드 1Qa',
    category: AchievementCategory.gold,
    essenceReward: 40,
    current: (c) => c.lifetimeGold,
    target: 1e15,
  ),
  _num(
    id: 'gold_1qi',
    name: '우주 자본가',
    description: '누적 골드 1Qi',
    category: AchievementCategory.gold,
    essenceReward: 70,
    current: (c) => c.lifetimeGold,
    target: 1e18,
  ),

  // ============ 3. DPS (6) ============
  _num(
    id: 'dps_10',
    name: '자동 수익 시작',
    description: '최고 DPS 10',
    category: AchievementCategory.dps,
    essenceReward: 1,
    current: (c) => c.maxDpsEver,
    target: 10,
  ),
  _num(
    id: 'dps_1k',
    name: '흘러넘치는 골드',
    description: '최고 DPS 1K',
    category: AchievementCategory.dps,
    essenceReward: 2,
    current: (c) => c.maxDpsEver,
    target: 1000,
  ),
  _num(
    id: 'dps_100k',
    name: '골드 공장',
    description: '최고 DPS 100K',
    category: AchievementCategory.dps,
    essenceReward: 3,
    current: (c) => c.maxDpsEver,
    target: 100000,
  ),
  _num(
    id: 'dps_1m',
    name: '황금 폭포',
    description: '최고 DPS 1M',
    category: AchievementCategory.dps,
    essenceReward: 5,
    current: (c) => c.maxDpsEver,
    target: 1e6,
  ),
  _num(
    id: 'dps_100m',
    name: '초당 1억',
    description: '최고 DPS 100M',
    category: AchievementCategory.dps,
    essenceReward: 10,
    current: (c) => c.maxDpsEver,
    target: 1e8,
  ),
  _num(
    id: 'dps_1b',
    name: '전설의 생산력',
    description: '최고 DPS 1B',
    category: AchievementCategory.dps,
    essenceReward: 20,
    current: (c) => c.maxDpsEver,
    target: 1e9,
  ),

  // ============ 4. 플레이 시간 (5) ============
  _num(
    id: 'play_10m',
    name: '입문자',
    description: '플레이 시간 10분',
    category: AchievementCategory.playtime,
    essenceReward: 1,
    current: (c) => c.playTimeSeconds.toDouble(),
    target: 600,
  ),
  _num(
    id: 'play_1h',
    name: '취미 탐험',
    description: '플레이 시간 1시간',
    category: AchievementCategory.playtime,
    essenceReward: 2,
    current: (c) => c.playTimeSeconds.toDouble(),
    target: 3600,
  ),
  _num(
    id: 'play_5h',
    name: '몰입',
    description: '플레이 시간 5시간',
    category: AchievementCategory.playtime,
    essenceReward: 5,
    current: (c) => c.playTimeSeconds.toDouble(),
    target: 18000,
  ),
  _num(
    id: 'play_24h',
    name: '밤낮을 잊고',
    description: '플레이 시간 24시간',
    category: AchievementCategory.playtime,
    essenceReward: 15,
    current: (c) => c.playTimeSeconds.toDouble(),
    target: 86400,
  ),
  _num(
    id: 'play_100h',
    name: '헌신',
    description: '플레이 시간 100시간',
    category: AchievementCategory.playtime,
    essenceReward: 50,
    current: (c) => c.playTimeSeconds.toDouble(),
    target: 360000,
  ),

  // ============ 5. 동료 (8) ============
  _bool(
    id: 'hire_first',
    name: '첫 동료',
    description: '동료 1명 고용',
    category: AchievementCategory.producer,
    essenceReward: 1,
    test: (c) => c.ownedProducerCount >= 1,
  ),
  _bool(
    id: 'hire_5',
    name: '파티 구성',
    description: '동료 5종 고용',
    category: AchievementCategory.producer,
    essenceReward: 2,
    test: (c) => c.ownedProducerCount >= 5,
  ),
  _bool(
    id: 'hire_all',
    name: '풀 라인업',
    description: '모든 동료 종류 고용',
    category: AchievementCategory.producer,
    essenceReward: 8,
    test: (c) => c.ownedProducerCount >= c.totalProducerCatalogCount,
  ),
  _num(
    id: 'producer_lv_10',
    name: '한 명을 집중 육성',
    description: '동료 중 하나를 Lv 10으로',
    category: AchievementCategory.producer,
    essenceReward: 2,
    current: (c) {
      if (c.producerLevels.isEmpty) return 0;
      return c.producerLevels.values
          .fold<int>(0, (a, b) => a > b ? a : b)
          .toDouble();
    },
    target: 10,
  ),
  _num(
    id: 'producer_lv_25',
    name: '마일스톤 첫 돌파',
    description: '동료 중 하나 Lv 25',
    category: AchievementCategory.producer,
    essenceReward: 3,
    current: (c) {
      if (c.producerLevels.isEmpty) return 0;
      return c.producerLevels.values
          .fold<int>(0, (a, b) => a > b ? a : b)
          .toDouble();
    },
    target: 25,
  ),
  _num(
    id: 'producer_lv_50',
    name: '반환점',
    description: '동료 중 하나 Lv 50',
    category: AchievementCategory.producer,
    essenceReward: 5,
    current: (c) {
      if (c.producerLevels.isEmpty) return 0;
      return c.producerLevels.values
          .fold<int>(0, (a, b) => a > b ? a : b)
          .toDouble();
    },
    target: 50,
  ),
  _num(
    id: 'producer_lv_100',
    name: '세 자리수',
    description: '동료 중 하나 Lv 100',
    category: AchievementCategory.producer,
    essenceReward: 10,
    current: (c) {
      if (c.producerLevels.isEmpty) return 0;
      return c.producerLevels.values
          .fold<int>(0, (a, b) => a > b ? a : b)
          .toDouble();
    },
    target: 100,
  ),
  _num(
    id: 'producer_lv_200',
    name: '마일스톤 완주',
    description: '동료 중 하나 Lv 200',
    category: AchievementCategory.producer,
    essenceReward: 25,
    current: (c) {
      if (c.producerLevels.isEmpty) return 0;
      return c.producerLevels.values
          .fold<int>(0, (a, b) => a > b ? a : b)
          .toDouble();
    },
    target: 200,
  ),

  // ============ 6. 검 수집 (10) ============
  _bool(
    id: 'sword_first',
    name: '첫 검',
    description: '검 1자루 획득',
    category: AchievementCategory.swordCollect,
    essenceReward: 1,
    test: (c) => c.ownedSwordCount >= 1,
  ),
  _num(
    id: 'sword_5',
    name: '다섯 자루',
    description: '검 5자루 수집',
    category: AchievementCategory.swordCollect,
    essenceReward: 2,
    current: (c) => c.ownedSwordCount.toDouble(),
    target: 5,
  ),
  _num(
    id: 'sword_10',
    name: '수집가 입문',
    description: '검 10자루 수집',
    category: AchievementCategory.swordCollect,
    essenceReward: 3,
    current: (c) => c.ownedSwordCount.toDouble(),
    target: 10,
  ),
  _num(
    id: 'sword_20',
    name: '반 이상',
    description: '검 20자루 수집',
    category: AchievementCategory.swordCollect,
    essenceReward: 5,
    current: (c) => c.ownedSwordCount.toDouble(),
    target: 20,
  ),
  _num(
    id: 'sword_30',
    name: '베테랑 수집가',
    description: '검 30자루 수집',
    category: AchievementCategory.swordCollect,
    essenceReward: 10,
    current: (c) => c.ownedSwordCount.toDouble(),
    target: 30,
  ),
  _bool(
    id: 'sword_all',
    name: '대도감 완성',
    description: '모든 검 수집',
    category: AchievementCategory.swordCollect,
    essenceReward: 50,
    test: (c) => c.ownedSwordCount >= c.totalSwordCatalogCount,
  ),
  _bool(
    id: 'sword_r',
    name: '첫 희귀',
    description: 'R 등급 검 획득',
    category: AchievementCategory.swordCollect,
    essenceReward: 2,
    test: (c) => c.ownsAnyR,
  ),
  _bool(
    id: 'sword_sr',
    name: '빛나는 발견',
    description: 'SR 등급 검 획득',
    category: AchievementCategory.swordCollect,
    essenceReward: 5,
    test: (c) => c.ownsAnySr,
  ),
  _bool(
    id: 'sword_ssr',
    name: '전설의 조우',
    description: 'SSR 등급 검 획득',
    category: AchievementCategory.swordCollect,
    essenceReward: 15,
    test: (c) => c.ownsAnySsr,
  ),
  _bool(
    id: 'sword_lr',
    name: '영웅의 이름',
    description: 'LR 등급 검 획득',
    category: AchievementCategory.swordCollect,
    essenceReward: 22,
    test: (c) => c.ownsAnyLr,
  ),
  _bool(
    id: 'sword_ur',
    name: '신화의 일각',
    description: 'UR 등급 검 획득',
    category: AchievementCategory.swordCollect,
    essenceReward: 30,
    test: (c) => c.ownsAnyUr,
  ),

  // ============ 7. 검 강화 (5) ============
  _num(
    id: 'sword_lv_3',
    name: '검 단련 입문',
    description: '검 하나를 Lv 3으로',
    category: AchievementCategory.swordLevel,
    essenceReward: 1,
    current: (c) => c.maxSwordLevel.toDouble(),
    target: 3,
  ),
  _num(
    id: 'sword_lv_5',
    name: '검 절반 각성',
    description: '검 하나를 Lv 5으로',
    category: AchievementCategory.swordLevel,
    essenceReward: 2,
    current: (c) => c.maxSwordLevel.toDouble(),
    target: 5,
  ),
  _num(
    id: 'sword_lv_7',
    name: '검의 주인',
    description: '검 하나를 Lv 7로',
    category: AchievementCategory.swordLevel,
    essenceReward: 5,
    current: (c) => c.maxSwordLevel.toDouble(),
    target: 7,
  ),
  _num(
    id: 'sword_lv_max',
    name: '완전 각성',
    description: '검 하나를 최대 Lv 10으로',
    category: AchievementCategory.swordLevel,
    essenceReward: 10,
    current: (c) => c.maxSwordLevel.toDouble(),
    target: 10,
  ),
  _num(
    id: 'sword_maxed_5',
    name: '다섯 개의 정점',
    description: '검 5자루를 Lv 10으로',
    category: AchievementCategory.swordLevel,
    essenceReward: 30,
    current: (c) => c.maxedSwordCount.toDouble(),
    target: 5,
  ),

  // ============ 8. 소환 (5) ============
  _num(
    id: 'summon_10',
    name: '열 번의 기원',
    description: '소환 10회',
    category: AchievementCategory.summon,
    essenceReward: 1,
    current: (c) => c.totalSummons.toDouble(),
    target: 10,
  ),
  _num(
    id: 'summon_50',
    name: '소환 애호가',
    description: '소환 50회',
    category: AchievementCategory.summon,
    essenceReward: 3,
    current: (c) => c.totalSummons.toDouble(),
    target: 50,
  ),
  _num(
    id: 'summon_100',
    name: '백 번의 운명',
    description: '소환 100회',
    category: AchievementCategory.summon,
    essenceReward: 5,
    current: (c) => c.totalSummons.toDouble(),
    target: 100,
  ),
  _num(
    id: 'summon_500',
    name: '소환 중독',
    description: '소환 500회',
    category: AchievementCategory.summon,
    essenceReward: 15,
    current: (c) => c.totalSummons.toDouble(),
    target: 500,
  ),
  _num(
    id: 'summon_1000',
    name: '천 번의 소환',
    description: '소환 1000회',
    category: AchievementCategory.summon,
    essenceReward: 30,
    current: (c) => c.totalSummons.toDouble(),
    target: 1000,
  ),

  // ============ 9. 환생 (7) ============
  _num(
    id: 'prestige_1',
    name: '새로운 시작',
    description: '첫 환생',
    category: AchievementCategory.prestige,
    essenceReward: 3,
    current: (c) => c.prestigeCount.toDouble(),
    target: 1,
  ),
  _num(
    id: 'prestige_3',
    name: '세 번째 삶',
    description: '환생 3회',
    category: AchievementCategory.prestige,
    essenceReward: 5,
    current: (c) => c.prestigeCount.toDouble(),
    target: 3,
  ),
  _num(
    id: 'prestige_10',
    name: '열 번의 환생',
    description: '환생 10회',
    category: AchievementCategory.prestige,
    essenceReward: 10,
    current: (c) => c.prestigeCount.toDouble(),
    target: 10,
  ),
  _num(
    id: 'prestige_50',
    name: '영원한 순환',
    description: '환생 50회',
    category: AchievementCategory.prestige,
    essenceReward: 30,
    current: (c) => c.prestigeCount.toDouble(),
    target: 50,
  ),
  _num(
    id: 'souls_100',
    name: '백 개의 혼',
    description: '누적 소울 100',
    category: AchievementCategory.prestige,
    essenceReward: 5,
    current: (c) => c.prestigeSouls.toDouble(),
    target: 100,
  ),
  _num(
    id: 'souls_1k',
    name: '천 개의 혼',
    description: '누적 소울 1,000',
    category: AchievementCategory.prestige,
    essenceReward: 20,
    current: (c) => c.prestigeSouls.toDouble(),
    target: 1000,
  ),
  _num(
    id: 'souls_10k',
    name: '만 개의 혼',
    description: '누적 소울 10,000',
    category: AchievementCategory.prestige,
    essenceReward: 60,
    current: (c) => c.prestigeSouls.toDouble(),
    target: 10000,
  ),

  // ============ 10. 마스터 (5) ============
  _bool(
    id: 'master_equip',
    name: '첫 장착',
    description: '검을 장착하여 홈 화면에 반영',
    category: AchievementCategory.master,
    essenceReward: 1,
    test: (c) => c.hasEquippedSword,
  ),
  _num(
    id: 'master_tap_upgrades',
    name: '강화의 달인',
    description: '터치 강화 누적 10회 구매',
    category: AchievementCategory.master,
    essenceReward: 2,
    current: (c) => c.totalTapUpgradesBought.toDouble(),
    target: 10,
  ),
  _num(
    id: 'master_all_producers_lv_10',
    name: '고른 성장',
    description: '모든 동료를 Lv 10 이상으로',
    category: AchievementCategory.master,
    essenceReward: 15,
    current: (c) {
      if (c.producerLevels.length < c.totalProducerCatalogCount) return 0;
      final minLv = c.producerLevels.values
          .fold<int>(1 << 30, (a, b) => a < b ? a : b);
      return minLv.toDouble();
    },
    target: 10,
  ),
  _num(
    id: 'master_total_producer_lv',
    name: '검의 군단',
    description: '모든 동료 레벨 합계 500',
    category: AchievementCategory.master,
    essenceReward: 25,
    current: (c) => c.totalProducerLevels.toDouble(),
    target: 500,
  ),
  _bool(
    id: 'master_perfectionist',
    name: '완벽주의자',
    description: '다른 모든 업적 해제',
    category: AchievementCategory.master,
    essenceReward: 100,
    // Can't self-reference — checked separately in provider.
    test: (_) => false,
  ),
];

AchievementDef? achievementById(String id) {
  for (final a in achievementCatalog) {
    if (a.id == id) return a;
  }
  return null;
}
