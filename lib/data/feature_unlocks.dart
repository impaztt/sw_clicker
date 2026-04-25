import 'package:flutter/material.dart';

import '../data/sword_sets.dart';
import '../providers/game_provider.dart';

/// Feature IDs gated by progression. UI checks
/// [GameState.isFeatureUnlocked] before showing the relevant surface.
class FeatureUnlocks {
  static const summonTab = 'summon_tab';
  static const missionsTab = 'missions_tab';
  static const achievementsTab = 'achievements_tab';
  static const boosterShop = 'booster_shop';
  static const prestigeTab = 'prestige_tab';
  static const swordSetsView = 'sword_sets_view';
}

class FeatureUnlockDef {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(GameState state) trigger;

  const FeatureUnlockDef({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.trigger,
  });
}

bool _ownsAnySetPair(GameState state) {
  if (state.ownedSwords.isEmpty) return false;
  for (final s in swordSets) {
    var owned = 0;
    for (final id in s.swordIds) {
      if ((state.ownedSwords[id] ?? 0) > 0) owned++;
      if (owned >= 2) return true;
    }
  }
  return false;
}

final featureUnlockCatalog = <FeatureUnlockDef>[
  FeatureUnlockDef(
    id: FeatureUnlocks.missionsTab,
    label: '미션',
    description: '도감에 미션 탭이 열렸어요. 일일·주간 미션으로 정수와 코인을 모아보세요.',
    icon: Icons.flag,
    color: const Color(0xFF00897B),
    trigger: (s) => s.totalTaps >= 1,
  ),
  FeatureUnlockDef(
    id: FeatureUnlocks.summonTab,
    label: '소환',
    description: '도감에 소환 탭이 열렸어요. 정수로 새로운 검을 뽑아보세요.',
    icon: Icons.auto_awesome,
    color: const Color(0xFF7C4DFF),
    trigger: (s) => s.essence >= 50,
  ),
  FeatureUnlockDef(
    id: FeatureUnlocks.achievementsTab,
    label: '업적',
    description: '도감에 업적 탭이 열렸어요. 누적 진행도에 따라 정수가 추가로 지급돼요.',
    icon: Icons.emoji_events,
    color: const Color(0xFFFFB300),
    trigger: (s) => s.unlockedAchievements.isNotEmpty,
  ),
  FeatureUnlockDef(
    id: FeatureUnlocks.swordSetsView,
    label: '검 세트',
    description: '도감에 세트 탭이 열렸어요. 같은 세트의 검을 모두 모으면 강력한 보너스가 적용돼요.',
    icon: Icons.workspaces,
    color: const Color(0xFFEC407A),
    trigger: _ownsAnySetPair,
  ),
  FeatureUnlockDef(
    id: FeatureUnlocks.prestigeTab,
    label: '환생',
    description: '환생이 가능해졌어요. 모든 진행을 초기화하는 대신 영구 강화 코인을 얻을 수 있어요.',
    icon: Icons.auto_awesome,
    color: const Color(0xFF7C4DFF),
    trigger: (s) => s.prestigeCoinsAvailable >= 1,
  ),
  FeatureUnlockDef(
    id: FeatureUnlocks.boosterShop,
    label: '부스터 상점',
    description: '홈 화면 우측 하단에 부스터 상점 버튼이 나타났어요. 정수로 한정 시간 가속 효과를 구매할 수 있어요.',
    icon: Icons.bolt,
    color: const Color(0xFFFF8A65),
    trigger: (s) => s.prestigeCount >= 1,
  ),
];

final Map<String, FeatureUnlockDef> _byId = {
  for (final d in featureUnlockCatalog) d.id: d,
};

FeatureUnlockDef? featureUnlockDef(String id) => _byId[id];
