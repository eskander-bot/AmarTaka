import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Daily short message with a refresh button.
class QuoteCard extends StatelessWidget {
  final String text;
  final VoidCallback onRefresh;
  const QuoteCard({super.key, required this.text, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? const Color(0xFFE9DDFB) : const Color(0xFF4A2A82);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dark ? const Color(0xFF3B1F66) : const Color(0xFFD5C2F2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF2B1150), Color(0xFF170A2E)]
              : const [Color(0xFFF1E9FC), Color(0xFFE4D8F7)],
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 16, color: fg),
              const SizedBox(width: 6),
              Expanded(
                child: Text('আজকের বার্তা',
                    style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: fg, fontSize: 15, height: 1.5)),
          ]),
        ),
        IconButton(
          tooltip: 'অন্য বার্তা',
          onPressed: onRefresh,
          icon: Icon(Icons.autorenew_rounded, color: fg),
        ),
      ]),
    );
  }
}

/// Big balance card with monthly income, expense and savings rate.
class DashboardBalanceCard extends StatefulWidget {
  final int balance, income, expense;
  final double savingsRate;
  const DashboardBalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.savingsRate,
  });
  @override
  State<DashboardBalanceCard> createState() => _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends State<DashboardBalanceCard> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final main = dark ? Colors.white : const Color(0xFF0B3B2B);
    final soft = dark ? const Color(0xFFB5EBD3) : const Color(0xFF2F6B55);
    final incomeColor = dark ? const Color(0xFF7CF2C0) : const Color(0xFF0A7A55);
    final expenseColor = dark ? const Color(0xFFFF9AA5) : const Color(0xFFD1274A);
    final savingColor = dark ? const Color(0xFFFFE08A) : const Color(0xFFB45309);
    final wide = MediaQuery.textScalerOf(context).scale(14) <= 22;
    final rate = widget.savingsRate.clamp(0.0, 100.0);

    Widget stat(String label, String value, Color color) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: soft, fontSize: 11)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  maxLines: 1,
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        );

    const hidden = '৳ ••••';
    final stats = [
      stat('আয় (মাসিক)', _visible ? formatMinor(widget.income) : hidden, incomeColor),
      stat('খরচ (মাসিক)', _visible ? formatMinor(widget.expense) : hidden, expenseColor),
      stat('সঞ্চয়', '${toBangla(rate.toStringAsFixed(0))}%', savingColor),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? const Color(0xFF14674B) : const Color(0xFF9FE3C4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0B7A55), Color(0xFF064E3B)]
              : const [Color(0xFFDDF8EA), Color(0xFFBDEFD5)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('মোট ব্যালেন্স', style: TextStyle(color: soft, fontSize: 13))),
          IconButton(
            tooltip: _visible ? 'ব্যালেন্স আড়াল করুন' : 'ব্যালেন্স দেখুন',
            onPressed: () => setState(() => _visible = !_visible),
            icon: Icon(_visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: soft, size: 20),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Semantics(
            label: _visible ? 'মোট ব্যালেন্স ${formatMinor(widget.balance)}' : 'ব্যালেন্স আড়াল করা আছে',
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_visible ? formatMinor(widget.balance) : '৳ ••••••',
                  maxLines: 1,
                  style: TextStyle(color: main, fontSize: 36, height: 1.3, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Divider(color: soft.withValues(alpha: 0.35), height: 1),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final s in stats) Expanded(child: s),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final s in stats) Padding(padding: const EdgeInsets.only(bottom: 10), child: s),
                ]),
        ),
      ]),
    );
  }
}

/// Small summary tile: icon, value, label.
class StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              maxLines: 1,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class DayTotals {
  final String label;
  final int income, expense;
  const DayTotals(this.label, this.income, this.expense);
}

/// Income vs expense bars, two bars per day.
class WeekChartCard extends StatelessWidget {
  final String title;
  final List<DayTotals> days;
  const WeekChartCard({super.key, required this.title, required this.days});

  @override
  Widget build(BuildContext context) {
    final incomeColor = AppColors.incomeFor(context);
    final expenseColor = AppColors.expenseFor(context);
    final peak = days.fold<int>(1, (m, d) => math.max(m, math.max(d.income, d.expense)));

    Widget bar(int value, Color color) => Container(
          width: 8,
          height: math.max(3.0, 110.0 * value / peak),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        );

    Widget legend(String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ]);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 165,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final d in days)
                Expanded(
                  child: Semantics(
                    label: '${d.label}, আয় ${formatMinor(d.income)}, ব্যয় ${formatMinor(d.expense)}',
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      SizedBox(
                        height: 110,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [bar(d.income, incomeColor), bar(d.expense, expenseColor)],
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(d.label, maxLines: 1, style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 4, children: [
            legend('আয়', incomeColor),
            legend('খরচ', expenseColor),
          ]),
        ]),
      ),
    );
  }
}

/// Bottom navigation with six tabs. Labels never overflow at large text sizes.
class AppBottomBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const AppBottomBar({super.key, required this.selected, required this.onSelect});

  static const items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'হোম'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'ইতিহাস'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'বিশ্লেষণ'),
    (Icons.track_changes_outlined, Icons.track_changes_rounded, 'বাজেট'),
    (Icons.star_outline_rounded, Icons.star_rounded, 'ইচ্ছা'),
    (Icons.edit_note_outlined, Icons.edit_note_rounded, 'নোট'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant))),
      child: Material(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1,
            maxScaleFactor: 1.15,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Row(children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelect(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(i == selected ? items[i].$2 : items[i].$1,
                              size: 23, color: i == selected ? cs.primary : cs.onSurfaceVariant),
                          const SizedBox(height: 3),
                          Text(items[i].$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: i == selected ? FontWeight.w600 : FontWeight.w400,
                                color: i == selected ? cs.primary : cs.onSurfaceVariant,
                              )),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
