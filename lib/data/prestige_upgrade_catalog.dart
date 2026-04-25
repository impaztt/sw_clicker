import 'package:flutter/material.dart';

import '../models/prestige_upgrade.dart';

const prestigeUpgradeCatalog = <PrestigeUpgradeDef>[
  PrestigeUpgradeDef(
    id: 'legacy_tap',
    name: 'Blade Legacy',
    description: 'Permanent tap power boost.',
    icon: Icons.touch_app,
    accent: Color(0xFFFF7043),
    baseCost: 12,
    growthRate: 1.45,
    maxLevel: 40,
    tapBonusPerLevel: 0.12,
  ),
  PrestigeUpgradeDef(
    id: 'legacy_dps',
    name: 'Engine Legacy',
    description: 'Permanent DPS boost.',
    icon: Icons.bolt,
    accent: Color(0xFF26A69A),
    baseCost: 12,
    growthRate: 1.45,
    maxLevel: 40,
    dpsBonusPerLevel: 0.12,
  ),
  PrestigeUpgradeDef(
    id: 'legacy_all',
    name: 'Transcendent Core',
    description: 'Permanent boost to both tap and DPS.',
    icon: Icons.auto_awesome,
    accent: Color(0xFFFFB300),
    baseCost: 40,
    growthRate: 1.70,
    maxLevel: 25,
    tapBonusPerLevel: 0.08,
    dpsBonusPerLevel: 0.08,
  ),
  PrestigeUpgradeDef(
    id: 'legacy_coin',
    name: 'Soul Recycler',
    description: 'Gain more prestige coins when resetting.',
    icon: Icons.currency_exchange,
    accent: Color(0xFF7C4DFF),
    baseCost: 20,
    growthRate: 1.60,
    maxLevel: 30,
    coinGainBonusPerLevel: 0.15,
  ),
];

PrestigeUpgradeDef prestigeUpgradeById(String id) =>
    prestigeUpgradeCatalog.firstWhere((u) => u.id == id);

double prestigeTapBonusFraction(Map<String, int> levels) {
  double total = 0;
  for (final def in prestigeUpgradeCatalog) {
    final lv = levels[def.id] ?? 0;
    total += def.tapBonusPerLevel * lv;
  }
  return total;
}

double prestigeDpsBonusFraction(Map<String, int> levels) {
  double total = 0;
  for (final def in prestigeUpgradeCatalog) {
    final lv = levels[def.id] ?? 0;
    total += def.dpsBonusPerLevel * lv;
  }
  return total;
}

double prestigeCoinGainBonusFraction(Map<String, int> levels) {
  double total = 0;
  for (final def in prestigeUpgradeCatalog) {
    final lv = levels[def.id] ?? 0;
    total += def.coinGainBonusPerLevel * lv;
  }
  return total;
}
