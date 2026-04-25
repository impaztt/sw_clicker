import 'package:flutter/material.dart';

/// Static metadata for the 17 시/도 in the stock-market system.
///
/// Volatility is per-minute σ% — converted to per-second σ by dividing by
/// √60 in the price tick. Hourly yield is the dividend rate per hour
/// (e.g. 0.08 = 8% of the holding's market value paid out per hour into
/// the region's pendingDividend).
class RegionDef {
  final String id;
  final String name;
  final String shortName;
  final int unlockOrder; // 1 = first to unlock (always 경기도)
  final double baseMarketCap;
  final int totalShares;
  final double initialPrice;
  final double volatilityPerMinute;
  final double hourlyYield;
  final Color accent;

  const RegionDef({
    required this.id,
    required this.name,
    required this.shortName,
    required this.unlockOrder,
    required this.baseMarketCap,
    required this.totalShares,
    required this.initialPrice,
    required this.volatilityPerMinute,
    required this.hourlyYield,
    required this.accent,
  });
}

/// Threshold (as a fraction) of ownership in the previous region required
/// to unlock the next.
const regionUnlockOwnershipThreshold = 0.20; // 20%

/// Trade fee fraction applied on both buy and sell.
const stockTradeFee = 0.02; // 2%

/// Candle window length in seconds.
const candleWindowSeconds = 30;

/// Maximum candles retained per region.
const candleHistoryMax = 60;

/// Dividend accrual interval.
const dividendIntervalSeconds = 3600; // 1 hour

const regionCatalog = <RegionDef>[
  RegionDef(
    id: 'gyeonggi',
    name: '경기도',
    shortName: '경기',
    unlockOrder: 1,
    baseMarketCap: 5000000000,
    totalShares: 10000000,
    initialPrice: 500,
    volatilityPerMinute: 0.005,
    hourlyYield: 0.08,
    accent: Color(0xFF42A5F5),
  ),
  RegionDef(
    id: 'incheon',
    name: '인천광역시',
    shortName: '인천',
    unlockOrder: 2,
    baseMarketCap: 6000000000,
    totalShares: 8000000,
    initialPrice: 750,
    volatilityPerMinute: 0.006,
    hourlyYield: 0.08,
    accent: Color(0xFF26A69A),
  ),
  RegionDef(
    id: 'chungbuk',
    name: '충청북도',
    shortName: '충북',
    unlockOrder: 3,
    baseMarketCap: 7000000000,
    totalShares: 7000000,
    initialPrice: 1000,
    volatilityPerMinute: 0.005,
    hourlyYield: 0.09,
    accent: Color(0xFF66BB6A),
  ),
  RegionDef(
    id: 'chungnam',
    name: '충청남도',
    shortName: '충남',
    unlockOrder: 4,
    baseMarketCap: 9000000000,
    totalShares: 6000000,
    initialPrice: 1500,
    volatilityPerMinute: 0.005,
    hourlyYield: 0.09,
    accent: Color(0xFF9CCC65),
  ),
  RegionDef(
    id: 'sejong',
    name: '세종특별자치시',
    shortName: '세종',
    unlockOrder: 5,
    baseMarketCap: 10000000000,
    totalShares: 4000000,
    initialPrice: 2500,
    volatilityPerMinute: 0.004,
    hourlyYield: 0.10,
    accent: Color(0xFF7E57C2),
  ),
  RegionDef(
    id: 'jeonbuk',
    name: '전라북도',
    shortName: '전북',
    unlockOrder: 6,
    baseMarketCap: 12000000000,
    totalShares: 6000000,
    initialPrice: 2000,
    volatilityPerMinute: 0.007,
    hourlyYield: 0.10,
    accent: Color(0xFFFFA726),
  ),
  RegionDef(
    id: 'jeonnam',
    name: '전라남도',
    shortName: '전남',
    unlockOrder: 7,
    baseMarketCap: 16000000000,
    totalShares: 5000000,
    initialPrice: 3200,
    volatilityPerMinute: 0.007,
    hourlyYield: 0.10,
    accent: Color(0xFFFFB74D),
  ),
  RegionDef(
    id: 'gwangju',
    name: '광주광역시',
    shortName: '광주',
    unlockOrder: 8,
    baseMarketCap: 20000000000,
    totalShares: 5000000,
    initialPrice: 4000,
    volatilityPerMinute: 0.006,
    hourlyYield: 0.09,
    accent: Color(0xFFEF5350),
  ),
  RegionDef(
    id: 'daejeon',
    name: '대전광역시',
    shortName: '대전',
    unlockOrder: 9,
    baseMarketCap: 28000000000,
    totalShares: 4000000,
    initialPrice: 7000,
    volatilityPerMinute: 0.006,
    hourlyYield: 0.09,
    accent: Color(0xFFEC407A),
  ),
  RegionDef(
    id: 'daegu',
    name: '대구광역시',
    shortName: '대구',
    unlockOrder: 10,
    baseMarketCap: 40000000000,
    totalShares: 4000000,
    initialPrice: 10000,
    volatilityPerMinute: 0.007,
    hourlyYield: 0.10,
    accent: Color(0xFFAB47BC),
  ),
  RegionDef(
    id: 'gyeongbuk',
    name: '경상북도',
    shortName: '경북',
    unlockOrder: 11,
    baseMarketCap: 55000000000,
    totalShares: 4000000,
    initialPrice: 13750,
    volatilityPerMinute: 0.008,
    hourlyYield: 0.10,
    accent: Color(0xFF8D6E63),
  ),
  RegionDef(
    id: 'gyeongnam',
    name: '경상남도',
    shortName: '경남',
    unlockOrder: 12,
    baseMarketCap: 75000000000,
    totalShares: 3000000,
    initialPrice: 25000,
    volatilityPerMinute: 0.007,
    hourlyYield: 0.11,
    accent: Color(0xFF6D4C41),
  ),
  RegionDef(
    id: 'busan',
    name: '부산광역시',
    shortName: '부산',
    unlockOrder: 13,
    baseMarketCap: 100000000000,
    totalShares: 3000000,
    initialPrice: 33333,
    volatilityPerMinute: 0.006,
    hourlyYield: 0.10,
    accent: Color(0xFF5C6BC0),
  ),
  RegionDef(
    id: 'ulsan',
    name: '울산광역시',
    shortName: '울산',
    unlockOrder: 14,
    baseMarketCap: 140000000000,
    totalShares: 2000000,
    initialPrice: 70000,
    volatilityPerMinute: 0.007,
    hourlyYield: 0.11,
    accent: Color(0xFF3949AB),
  ),
  RegionDef(
    id: 'gangwon',
    name: '강원특별자치도',
    shortName: '강원',
    unlockOrder: 15,
    baseMarketCap: 180000000000,
    totalShares: 2000000,
    initialPrice: 90000,
    volatilityPerMinute: 0.008,
    hourlyYield: 0.12,
    accent: Color(0xFF1E88E5),
  ),
  RegionDef(
    id: 'jeju',
    name: '제주도',
    shortName: '제주',
    unlockOrder: 16,
    baseMarketCap: 250000000000,
    totalShares: 1000000,
    initialPrice: 250000,
    volatilityPerMinute: 0.012,
    hourlyYield: 0.14,
    accent: Color(0xFF00ACC1),
  ),
  RegionDef(
    id: 'seoul',
    name: '서울특별시',
    shortName: '서울',
    unlockOrder: 17,
    baseMarketCap: 1000000000000,
    totalShares: 5000000,
    initialPrice: 200000,
    volatilityPerMinute: 0.004,
    hourlyYield: 0.08,
    accent: Color(0xFFD32F2F),
  ),
];

final Map<String, RegionDef> _byId = {
  for (final r in regionCatalog) r.id: r,
};

RegionDef regionDefById(String id) => _byId[id]!;

/// Returns the next region in unlock order after [id], or null when [id] is
/// the last region.
RegionDef? nextRegionAfter(String id) {
  final cur = _byId[id];
  if (cur == null) return null;
  for (final r in regionCatalog) {
    if (r.unlockOrder == cur.unlockOrder + 1) return r;
  }
  return null;
}

/// Trigger threshold (cumulative gold) that unlocks the stock-market UI.
const stockMarketLifetimeGoldTrigger = 1000000000.0; // 1B
