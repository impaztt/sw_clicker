import 'package:flutter/material.dart';

import '../core/theme.dart';

class OnboardingDialog extends StatelessWidget {
  const OnboardingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.deepCoral),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '첫 여정 가이드',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '처음에는 아래 3가지만 집중하면 빠르게 성장합니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 12),
            const _StepRow(
              icon: Icons.touch_app,
              title: '1) 홈에서 터치/스킬로 초기 골드 확보',
              desc: '터치 배율과 콤보를 먼저 올리면 초반 속도가 빨라집니다.',
            ),
            const _StepRow(
              icon: Icons.upgrade,
              title: '2) 강화에서 동료/터치 균형 투자',
              desc: '동료는 방치 수익, 터치는 즉시 수익을 담당합니다.',
            ),
            const _StepRow(
              icon: Icons.auto_awesome,
              title: '3) 환생 코인으로 영구 성장을 누적',
              desc: '코인 상점 영구 각인과 업그레이드가 중장기 핵심입니다.',
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text(
                '시작하기',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _StepRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF00695C)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
