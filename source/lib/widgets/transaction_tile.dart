import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final Txn txn;
  final VoidCallback onDelete;

  const TransactionTile({super.key, required this.txn, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == TxnType.income;
    final color = isIncome ? const Color(0xFF1FA97C) : const Color(0xFFE4572E);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            isIncome ? Icons.south_west : Icons.north_east,
            color: color,
          ),
        ),
        title: Text(
          txn.category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(txn.note.isEmpty ? _formatDate(txn.date) : txn.note),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'} ${formatAmount(txn.amount)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete?'),
                    content: const Text('This transaction will be removed.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
                if (ok == true) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${toBangla(d.day.toString())}/${toBangla(d.month.toString())}/${toBangla(d.year.toString())}';
}
