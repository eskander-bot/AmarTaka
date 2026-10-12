import 'package:flutter/material.dart';
import '../finance/portfolio.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';

/// Shared, offline visuals for the dashboard, savings and budget screens.
class WealthStyle {
  static const green = Color(0xFF20D99B);
  static const teal = Color(0xFF12B88A);
  static const blue = Color(0xFF24A8F5);
  static const amber = Color(0xFFF2AB22);
  static Color accent(BuildContext context, String kind) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (kind) {
      'fdr' || 'investment' => dark ? blue : const Color(0xFF086EB0),
      'certificate' || 'cash' => dark ? amber : const Color(0xFF936000),
      _ => AppColors.incomeFor(context),
    };
  }
  static IconData categoryIcon(String category) => switch (category.toLowerCase()) {
    'food' || 'bazar' || 'খাবার' || 'বাজার' => Icons.restaurant_outlined,
    'transport' || 'যাতায়াত' => Icons.directions_bus_outlined,
    'bills' || 'বিল' => Icons.bolt_outlined,
    'shopping' || 'কেনাকাটা' => Icons.shopping_bag_outlined,
    'health' => Icons.favorite_border,
    'education' => Icons.school_outlined,
    _ => Icons.category_outlined,
  };
}

class HealthCard extends StatelessWidget {
  final int income, expense;
  final Portfolio portfolio;
  const HealthCard({super.key, required this.income, required this.expense,
    required this.portfolio});
  @override
  Widget build(BuildContext context) {
    final score = FinanceMath.health(income: income, expense: expense,
      liquid: portfolio.total('cash') + portfolio.total('bank'),
      debt: portfolio.liabilities, assets: portfolio.assets);
    final hasData = income > 0 || expense > 0 || portfolio.holdings.isNotEmpty;
    final color = AppColors.incomeFor(context);
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
      Semantics(label: hasData ? 'হিসাবের স্কোর $score / ১০০' : 'এখনও হিসাব নেই',
        child: SizedBox(width: 62, height: 62, child: CircularProgressIndicator(
          value: hasData ? score / 100 : 0, strokeWidth: 6,
          strokeCap: StrokeCap.round, color: color,
          backgroundColor: Theme.of(context).colorScheme.outlineVariant))),
      const SizedBox(width: 18),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('আর্থিক অবস্থা', style: Theme.of(context).textTheme.bodySmall),
        Text(hasData ? '${toBangla('$score')} / ১০০' : 'হিসাব যোগ করুন',
          style: Theme.of(context).textTheme.titleLarge),
        Text(hasData ? 'সঞ্চয়, নগদ ও দায়ের নিজস্ব সূচক' : 'আপনার তথ্য থেকে হিসাব হবে',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ])),
      IconButton(tooltip: 'স্কোর কীভাবে হয়', icon: const Icon(Icons.info_outline, size: 18),
        onPressed: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('হিসাবের স্কোর'),
          content: const Text('নির্বাচিত মাসের সঞ্চয়ের হার ৪০, ছয় মাসের খরচের সমান নগদ সুরক্ষা ৩৫ এবং সম্পদের তুলনায় দায় ২৫ নম্বর। এটি অ্যাপের নিজস্ব সূচক; ব্যাংকের ক্রেডিট স্কোর নয়।'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ঠিক আছে'))]))),
    ])));
  }
}

class AllocationCard extends StatelessWidget {
  final Portfolio portfolio;
  final VoidCallback onOpen;
  const AllocationCard({super.key, required this.portfolio, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final groups = <({String name, int value, Color color})>[
      (name: 'ব্যাংক', value: portfolio.total('bank'), color: WealthStyle.green),
      (name: 'DPS ও FDR', value: portfolio.total('dps') + portfolio.total('fdr'), color: WealthStyle.teal),
      (name: 'বিনিয়োগ', value: portfolio.total('investment'), color: WealthStyle.blue),
      (name: 'ক্যাশ', value: portfolio.total('cash'), color: WealthStyle.amber),
      (name: 'সঞ্চয়পত্র', value: portfolio.total('certificate'), color: const Color(0xFFB69CF7)),
      (name: 'পাওনা', value: portfolio.total('lent'), color: const Color(0xFFEB8CA8)),
    ].where((g) => g.value > 0).toList();
    final total = groups.fold<int>(0, (sum, g) => sum + g.value);
    return Card(child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(20),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('আপনার টাকা কোথায়', style: Theme.of(context).textTheme.titleMedium)),
            const Icon(Icons.chevron_right, size: 18)]),
          const SizedBox(height: 14),
          if (total == 0) Text('ব্যাংক, ক্যাশ বা সঞ্চয়ের হিসাব যোগ করুন।', style: Theme.of(context).textTheme.bodySmall)
          else ...[
            Semantics(label: 'সম্পদের অনুপাত', child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Row(children: groups.map((g) => Expanded(flex: g.value,
                child: Container(height: 8, color: g.color))).toList()))),
            const SizedBox(height: 14),
            Wrap(spacing: 16, runSpacing: 8, children: groups.map((g) => Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: g.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${g.name} ${toBangla((100 * g.value / total).toStringAsFixed(0))}%',
                style: Theme.of(context).textTheme.bodySmall),
            ])).toList()),
          ],
        ]))));
  }
}

class SavingSummary extends StatelessWidget {
  final Record record;
  const SavingSummary({super.key, required this.record});
  @override
  Widget build(BuildContext context) {
    final kind = field(record, 'kind');
    final color = WealthStyle.accent(context, kind);
    final dps = kind == 'dps';
    final term = FinanceMath.termMonths(record);
    final paid = number(record, 'months_paid');
    final active = number(record, 'active') == 1;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 4, children: [
          Text(financeLabels[kind] ?? kind, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          Text(dps ? '${formatMinor(number(record, 'amount_minor'))} / মাস' : field(record, 'subtype'),
            style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 8),
        Text(field(record, 'title'), style: Theme.of(context).textTheme.bodySmall),
        Text(formatMinor(active ? FinanceMath.principal(record) : 0),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 25)),
        const SizedBox(height: 8),
        if (!active) Text('বন্ধ হিসাব', style: Theme.of(context).textTheme.bodySmall)
        else if (dps) ...[
          LinearProgressIndicator(value: term > 0 ? (paid / term).clamp(0.0, 1.0) : 0,
            color: color, minHeight: 6, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 7),
          Text('${toBangla('$paid')} / ${toBangla('$term')} কিস্তি জমা', style: Theme.of(context).textTheme.bodySmall),
        ] else Text('আনুমানিক লাভ ${formatMinor(FinanceMath.accrued(record, DateTime.now()) - number(record, 'amount_minor'))}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ]));
  }
}
