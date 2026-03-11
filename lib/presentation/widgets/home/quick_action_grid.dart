import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class QuickActionGrid extends StatelessWidget {
  final VoidCallback onTopUp;
  final VoidCallback onTransfer;
  final VoidCallback onRencana;
  final VoidCallback onPayLater;

  const QuickActionGrid({
    super.key,
    required this.onTopUp,
    required this.onTransfer,
    required this.onRencana,
    required this.onPayLater,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionItem(
          icon: Icons.add_circle_outline,
          label: 'Top Up',
          color: AppColors.success,
          onTap: onTopUp,
        ),
        _ActionItem(
          icon: Icons.send,
          label: 'Transfer',
          color: AppColors.primary,
          onTap: onTransfer,
        ),
        _ActionItem(
          icon: Icons.calendar_month_rounded,
          label: 'My Plan',
          color: AppColors.info,
          onTap: onRencana,
        ),
        _ActionItem(
          icon: Icons.credit_card,
          label: 'PayLater',
          color: AppColors.error,
          onTap: onPayLater,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
