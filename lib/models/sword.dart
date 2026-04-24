import 'package:flutter/material.dart';

enum SwordTier { n, r, sr, ssr, ur }

extension SwordTierInfo on SwordTier {
  String get label => switch (this) {
        SwordTier.n => 'N',
        SwordTier.r => 'R',
        SwordTier.sr => 'SR',
        SwordTier.ssr => 'SSR',
        SwordTier.ur => 'UR',
      };

  String get korLabel => switch (this) {
        SwordTier.n => '일반',
        SwordTier.r => '희귀',
        SwordTier.sr => '초희귀',
        SwordTier.ssr => '전설',
        SwordTier.ur => '신화',
      };

  Color get color => switch (this) {
        SwordTier.n => const Color(0xFF9E9E9E),
        SwordTier.r => const Color(0xFF42A5F5),
        SwordTier.sr => const Color(0xFFAB47BC),
        SwordTier.ssr => const Color(0xFFFFB300),
        SwordTier.ur => const Color(0xFFEF5350),
      };

  /// Roll rate as a percent (sum = 100).
  double get rate => switch (this) {
        SwordTier.n => 60,
        SwordTier.r => 25,
        SwordTier.sr => 10,
        SwordTier.ssr => 4,
        SwordTier.ur => 1,
      };
}

enum SparkleStyle { none, dim, bright, orbiting }

class SwordVisual {
  final Color bladeColor;
  final Color bladeAccent;
  final Color guardColor;
  final Color handleColor;
  final Color pommelColor;
  final Color auraColor;
  final double auraIntensity;
  final SparkleStyle sparkle;

  const SwordVisual({
    required this.bladeColor,
    required this.bladeAccent,
    required this.guardColor,
    required this.handleColor,
    required this.pommelColor,
    required this.auraColor,
    this.auraIntensity = 0.3,
    this.sparkle = SparkleStyle.none,
  });
}

class SwordDef {
  static const maxLevel = 10;

  final String id;
  final String name;
  final String description;
  final SwordTier tier;
  final double baseTapMult;
  final double baseDpsMult;
  final SwordVisual visual;

  const SwordDef({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.baseTapMult,
    this.baseDpsMult = 1.0,
    required this.visual,
  });

  /// At level L (1~10), effective multiplier = base * (1 + (L-1) * 0.1).
  /// So Lv 1 = base, Lv 10 = 1.9 * base.
  double tapMultAt(int level) =>
      baseTapMult * (1 + (level.clamp(1, maxLevel) - 1) * 0.1);
  double dpsMultAt(int level) =>
      baseDpsMult * (1 + (level.clamp(1, maxLevel) - 1) * 0.1);
}
