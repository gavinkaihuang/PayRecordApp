import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';

class BillItem extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final bool isSelected;

  const BillItem({
    super.key, 
    required this.bill, 
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      color: isSelected ? const Color(0xFFF0F5FF) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bill.payTarget, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18, 
                    color: Colors.black87
                  )
                ),
                // Optional: Arrow icon can go here or be removed as per design
                // Icon(Icons.chevron_right, color: Colors.grey[400], size: 20), 
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Due Date', dateFormat.format(bill.date)),
            _buildInfoRow('Payer', bill.payer != null && bill.payer!.isNotEmpty ? bill.payer! : "Unknown"),
            _buildInfoRow('Amount', bill.pendingAmount != null ? currencyFormat.format(bill.pendingAmount) : '-'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Is Paid: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(width: 4),
                Icon(
                  Icons.circle,
                  color: bill.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  bill.isPaid ? 'Yes' : 'No', 
                  style: TextStyle(
                    color: bill.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFEF5350), 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  )
                ),
              ],
            ),
             if (bill.isPaid) ...[
                const SizedBox(height: 4),
                _buildInfoRow('Paid Date', bill.actualPaidDate != null ? dateFormat.format(bill.actualPaidDate!) : '-'),
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }
}
