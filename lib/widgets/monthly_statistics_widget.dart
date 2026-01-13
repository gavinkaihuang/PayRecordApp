import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';

class MonthlyStatisticsWidget extends StatelessWidget {
  final List<Bill> bills;

  const MonthlyStatisticsWidget({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Statistics
    double totalExpenses = 0.0;
    int unpaidCount = 0;
    double unpaidAmount = 0.0;
    double totalIncome = 0.0;

    for (var bill in bills) {
      // Expenses (assuming pendingAmount tracks expense)
      if (bill.pendingAmount != null) {
        totalExpenses += bill.pendingAmount!;
        
        if (!bill.isPaid) {
          unpaidCount++;
          unpaidAmount += bill.pendingAmount!;
        }
      }

      // Income
      if (bill.pendingReceiveAmount != null) {
        totalIncome += bill.pendingReceiveAmount!;
      }
    }

    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Est. Total Expenses',
                  value: currencyFormat.format(totalExpenses),
                  icon: Icons.money_off,
                  color: const Color(0xFF5B8CFF), // Blue
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Income',
                  value: currencyFormat.format(totalIncome),
                  icon: Icons.attach_money,
                  color: const Color(0xFF4CAF50), // Green
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Unpaid Bills',
                  value: '$unpaidCount',
                  icon: Icons.receipt_long,
                  color: const Color(0xFFFF9800), // Orange
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Unpaid Amount',
                  value: currencyFormat.format(unpaidAmount),
                  icon: Icons.pending_actions,
                  color: const Color(0xFFF44336), // Red
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
