import 'package:flutter/material.dart';
import '../models/tap_upgrade.dart';

const tapUpgradeCatalog = <TapUpgradeDef>[
  TapUpgradeDef(
    id: 'sharper_blade',
    name: '날카로운 검날',
    description: '터치당 +1',
    icon: Icons.content_cut,
    accent: Color(0xFF90CAF9),
    baseCost: 25,
    tapPowerPerLevel: 1,
  ),
  TapUpgradeDef(
    id: 'magic_infusion',
    name: '마력 주입',
    description: '터치당 +5',
    icon: Icons.auto_fix_high,
    accent: Color(0xFFCE93D8),
    baseCost: 250,
    tapPowerPerLevel: 5,
  ),
  TapUpgradeDef(
    id: 'sword_aura',
    name: '검기 각성',
    description: '터치당 +25',
    icon: Icons.flash_on,
    accent: Color(0xFFFFD54F),
    baseCost: 2500,
    tapPowerPerLevel: 25,
  ),
  TapUpgradeDef(
    id: 'divine_strike',
    name: '신성한 일격',
    description: '터치당 +100',
    icon: Icons.bolt,
    accent: Color(0xFFFFAB91),
    baseCost: 25000,
    tapPowerPerLevel: 100,
  ),
  TapUpgradeDef(
    id: 'legendary_swing',
    name: '전설의 일섬',
    description: '터치당 +500',
    icon: Icons.whatshot,
    accent: Color(0xFFEF5350),
    baseCost: 250000,
    tapPowerPerLevel: 500,
  ),
];
