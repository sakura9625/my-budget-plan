import 'package:flutter/material.dart';
import '../theme.dart';

// 年月を+/-ステッパーで選ぶ共通ウィジェット。
class MonthPicker extends StatelessWidget {
  final String label;
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  const MonthPicker({
    super.key,
    required this.label,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text('$year年$month月',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  int y = year, m = month - 1;
                  if (m < 1) {
                    m = 12;
                    y--;
                  }
                  onChanged(y, m);
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chevron_left,
                      size: 20, color: AppTheme.primary),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  int y = year, m = month + 1;
                  if (m > 12) {
                    m = 1;
                    y++;
                  }
                  onChanged(y, m);
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chevron_right,
                      size: 20, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
