import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../services/api_service.dart';

class BillItem extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  final VoidCallback? onPayClick;
  final bool isSelected;

  const BillItem({
    super.key, 
    required this.bill, 
    required this.onTap,
    this.onPayClick,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Formatters
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2, name: '¥ '); 
    final dateFormat = DateFormat('MM-dd');

    // Determine display properties based on Pay vs Receive
    String displayName = bill.payTarget;
    String? displayIcon = bill.payeeIcon;
    
    if (bill.payTarget.isEmpty && bill.payer != null && bill.payer!.isNotEmpty) {
      displayName = bill.payer!;
      displayIcon = bill.payerIcon;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: isSelected 
          ? Border.all(color: const Color(0xFF2B5CFF), width: 1.5) 
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left Icon
                SizedBox(
                  width: 50,
                  height: 50,
                  child: displayIcon != null && displayIcon.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            displayIcon.startsWith('http') 
                                ? displayIcon 
                                : '${ApiService.serverUrl}/${displayIcon.startsWith('/') ? displayIcon.substring(1) : displayIcon}',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 24)
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.attach_money, color: Colors.white, size: 30),
                        ),
                ),
                const SizedBox(width: 16),
                
                // Middle Section (Target & Amount)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bill.pendingAmount != null ? currencyFormat.format(bill.pendingAmount) : '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right Section (Dates & Button)
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '日期: ${dateFormat.format(bill.date)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '实际支付: ${bill.actualPaidDate != null ? dateFormat.format(bill.actualPaidDate!) : 'N/A'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: bill.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B),
                        ),
                         textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: bill.isPaid ? null : onPayClick,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: bill.isPaid ? Colors.grey[300] : const Color(0xFF2B5CFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            bill.isPaid ? '已支付' : '支付',
                            style: TextStyle(
                              color: bill.isPaid ? Colors.black54 : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
