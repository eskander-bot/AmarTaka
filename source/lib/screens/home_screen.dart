import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import '../utils/formatters.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DbHelper.instance;
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final totals = await _db.getMonthTotals();
    final recent = await _db.getTransactions(limit: 30);
    return _HomeData(totals: totals, recent: recent);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amar Taka'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
          if (mounted) setState(_refresh);
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final income = data.totals['income']!;
          final expense = data.totals['expense']!;
          final balance = income - expense;
          return RefreshIndicator(
            onRefresh: () async => setState(_refresh),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This month balance',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          formatAmount(balance),
                          style: TextStyle(
                            color: balance >= 0
                                ? const Color(0xFF1FA97C)
                                : const Color(0xFFE4572E),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _mini('Income', income, const Color(0xFF1FA97C)),
                            const SizedBox(width: 24),
                            _mini('Expense', expense, const Color(0xFFE4572E)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Recent transactions',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (data.recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No transactions yet.\nTap + to add one.'),
                    ),
                  ),
                ...data.recent.map(
                  (t) => TransactionTile(
                    txn: t,
                    onDelete: () async {
                      await _db.deleteTransaction(t.id!);
                      if (mounted) setState(_refresh);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mini(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          formatAmount(value),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }
}

class _HomeData {
  final Map<String, double> totals;
  final List<Txn> recent;
  _HomeData({required this.totals, required this.recent});
}
