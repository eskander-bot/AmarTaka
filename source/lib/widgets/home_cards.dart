import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'jewel_icon.dart';
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

/// Big balance card: balance on top, then income | expense | savings with dividers.
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

String _short(int minor) {
  final text = formatMinor(minor);
  final tail = toBangla('.00');
  return text.endsWith(tail) ? text.substring(0, text.length - tail.length) : text;
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
    final amountStyle = TextStyle(color: main, fontSize: 38, height: 1.3, fontWeight: FontWeight.w700);

    Widget cell(String label, Widget value) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: soft, fontSize: 12)),
            const SizedBox(height: 6),
            value,
          ],
        );
    Widget money(String text, Color color) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        );

    const hidden = '৳ ••••';
    final ring = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: rate / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: 40,
        height: 40,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: 4.5,
              strokeCap: StrokeCap.round,
              color: savingColor,
              backgroundColor: soft.withValues(alpha: 0.25),
            ),
          ),
          Text('${toBangla(rate.toStringAsFixed(0))}%',
              style: TextStyle(color: savingColor, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
    final cells = <Widget>[
      cell('আয় (মাসিক)', money(_visible ? _short(widget.income) : hidden, incomeColor)),
      cell('খরচ (মাসিক)', money(_visible ? _short(widget.expense) : hidden, expenseColor)),
      cell('সঞ্চয়', ring),
    ];
    final line = soft.withValues(alpha: 0.35);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: dark ? const Color(0xFF14674B) : const Color(0xFF9FE3C4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF117D67), Color(0xFF073E35)]
              : const [Color(0xFFDDF8EA), Color(0xFFBDEFD5)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -6,
          top: -26,
          child: IgnorePointer(
            child: Text('৳',
                style: TextStyle(
                    fontSize: 150, height: 1, fontWeight: FontWeight.w600, color: main.withValues(alpha: 0.07))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('মোট ব্যালেন্স', style: TextStyle(color: soft, fontSize: 14))),
              IconButton(
                tooltip: _visible ? 'ব্যালেন্স আড়াল করুন' : 'ব্যালেন্স দেখুন',
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(_visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: soft, size: 22),
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
                  child: _visible
                      ? TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: widget.balance.toDouble()),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Text(
                              (v - widget.balance).abs() < 50 ? _short(widget.balance) : _short(v.round() ~/ 100 * 100),
                              maxLines: 1,
                              style: amountStyle),
                        )
                      : Text('৳ ••••••', maxLines: 1, style: amountStyle),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: dark ? 0.08 : 0.45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: wide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: cells[0])),
                        Container(width: 1, height: 56, color: line),
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: cells[1])),
                        Container(width: 1, height: 56, color: line),
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: cells[2])),
                      ])
                    : Column(children: [
                        cells[0],
                        Divider(color: line, height: 20),
                        cells[1],
                        Divider(color: line, height: 20),
                        cells[2],
                      ]),
              ),
            ),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.surface, Color.alphaBlend(color.withValues(alpha: 0.045), cs.surface)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        JewelIcon(icon: icon, color: color, size: 38),
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

    Widget bar(int value, Color color) => TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 110.0 * value / peak),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, h, _) => Container(
            width: 8,
            height: math.max(3.0, h),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, 0.22)!, color]), borderRadius: BorderRadius.circular(4)),
          ),
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

/// Floating navigation dock with original two-tone illustrations.
class AppBottomBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const AppBottomBar({super.key, required this.selected, required this.onSelect});

  static const items = <(IconData, String, Color)>[
    (Icons.home_rounded, 'হোম', Color(0xFF10B981)),
    (Icons.receipt_long_rounded, 'ইতিহাস', Color(0xFF3B82F6)),
    (Icons.bar_chart_rounded, 'বিশ্লেষণ', Color(0xFF9B77F3)),
    (Icons.track_changes_rounded, 'বাজেট', Color(0xFFE5A52E)),
    (Icons.star_rounded, 'ইচ্ছা', Color(0xFFE56AA4)),
    (Icons.edit_note_rounded, 'নোট', Color(0xFF17B6CB)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.18 : 0.06), blurRadius: 24, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == selected,
                    button: true,
                    label: items[i].$2,
                    excludeSemantics: true,
                    child: Tooltip(
                      message: items[i].$2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          if (i != selected) HapticFeedback.selectionClick();
                          onSelect(i);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            JewelIcon(icon: items[i].$1, color: items[i].$3, size: 34,
                                selected: i == selected, navigationIndex: i),
                            const SizedBox(height: 5),
                            Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                                color: i == selected ? cs.onSurface : cs.onSurfaceVariant)),
                            const SizedBox(height: 5),
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
                              height: 3, width: i == selected ? 16 : 4,
                              decoration: BoxDecoration(color: i == selected ? items[i].$3 : Colors.transparent,
                                borderRadius: BorderRadius.circular(3)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child in once, with a small delay per index.
class FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  const FadeSlideIn({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 380 + 70 * math.min(index, 8)),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) =>
            Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child)),
        child: child,
      );
}

/// Text filled with a green-to-blue gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  const GradientText(this.text, {super.key, this.style, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) =>
          LinearGradient(colors: [cs.primary, const Color(0xFF2DB6E8)]).createShader(rect),
      child: Text(text,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: (style ?? const TextStyle()).copyWith(color: Colors.white)),
    );
  }
}

/// Two big colourful add buttons: expense (red) and income (green).
class QuickAddRow extends StatelessWidget {
  final VoidCallback onIncome, onExpense;
  const QuickAddRow({super.key, required this.onIncome, required this.onExpense});

  @override
  Widget build(BuildContext context) {
    Widget button(String label, IconData icon, List<Color> colors, VoidCallback onTap) => Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: colors),
              boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: Colors.white, size: 21),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
        );
    final buttons = [
      button('ব্যয় যোগ', Icons.remove_circle_outline, const [Color(0xFFFF6B6B), Color(0xFFE11D48)], onExpense),
      button('আয় যোগ', Icons.add_circle_outline, const [Color(0xFF10B981), Color(0xFF047857)], onIncome),
    ];
    if (MediaQuery.textScalerOf(context).scale(14) > 22) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        buttons[0],
        const SizedBox(height: 10),
        buttons[1],
      ]);
    }
    return Row(children: [
      Expanded(child: buttons[0]),
      const SizedBox(width: 12),
      Expanded(child: buttons[1]),
    ]);
  }
}

/// A colour and icon for each category, so lists are easy to scan.
class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);

  static const _styles = <String, CategoryStyle>{
    'Bazar': CategoryStyle(Icons.shopping_basket_rounded, Color(0xFFF97316)),
    'Transport': CategoryStyle(Icons.directions_bus_rounded, Color(0xFF3B82F6)),
    'Bills': CategoryStyle(Icons.receipt_long_rounded, Color(0xFFEAB308)),
    'Health': CategoryStyle(Icons.favorite_rounded, Color(0xFFEF4444)),
    'Education': CategoryStyle(Icons.school_rounded, Color(0xFF8B5CF6)),
    'Entertainment': CategoryStyle(Icons.movie_rounded, Color(0xFFEC4899)),
    'Salary': CategoryStyle(Icons.payments_rounded, Color(0xFF10B981)),
    'Freelance': CategoryStyle(Icons.laptop_mac_rounded, Color(0xFF06B6D4)),
    'Business': CategoryStyle(Icons.storefront_rounded, Color(0xFF14B8A6)),
    'Gift': CategoryStyle(Icons.card_giftcard_rounded, Color(0xFFF43F5E)),
    'Misc': CategoryStyle(Icons.category_rounded, Color(0xFF64748B)),
  };

  static CategoryStyle of(String category, bool income) =>
      _styles[category] ??
      CategoryStyle(income ? Icons.south_west_rounded : Icons.north_east_rounded,
          income ? const Color(0xFF10B981) : const Color(0xFFEF4444));
}
