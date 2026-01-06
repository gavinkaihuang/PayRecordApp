import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    bool isIncome = false;
    String displayName = bill.payTarget;
    String? displayIcon = bill.payeeIcon;
    double? displayAmount = bill.pendingAmount;
    
    // Check if it is an income (Payer exists, PayTarget empty)
    if (bill.payTarget.isEmpty && bill.payer != null && bill.payer!.isNotEmpty) {
      isIncome = true;
      displayName = bill.payer!;
      displayIcon = bill.payerIcon;
      displayAmount = bill.pendingReceiveAmount;
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
                          child: CachedNetworkImage(
                            imageUrl: displayIcon.startsWith('http') 
                                ? displayIcon 
                                : '${ApiService.serverUrl}/${displayIcon.startsWith('/') ? displayIcon.substring(1) : displayIcon}',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 24)),
                            ),
                            errorWidget: (context, url, error) => Container(
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
                            gradient: LinearGradient(
                              colors: isIncome 
                                  ? [const Color(0xFF66BB6A), const Color(0xFF43A047)] // Green for Income
                                  : [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Blue for Expense
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isIncome ? Icons.input : Icons.attach_money, // Different icon for income default
                            color: Colors.white, 
                            size: 30
                          ),
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
                        displayAmount != null 
                            ? '${isIncome ? '+' : '-'} ${currencyFormat.format(displayAmount)}' 
                            : '-',
                        style: TextStyle(
                          fontSize: 15, // Slightly larger
                          fontWeight: FontWeight.w500,
                          color: isIncome ? Colors.green[700] : Colors.red[700], // Color coding
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
                        '${isIncome ? "实际到账" : "实际支付"}: ${bill.actualPaidDate != null ? dateFormat.format(bill.actualPaidDate!) : 'N/A'}',
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
                            color: bill.isPaid 
                                ? Colors.grey[300] 
                                : (isIncome ? Colors.green : const Color(0xFF2B5CFF)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            bill.isPaid 
                                ? (isIncome ? '已到账' : '已支付') 
                                : (isIncome ? '接收' : '支付'),
                            style: TextStyle(
                              color: bill.isPaid ? Colors.black54 : Colors.white,
                              fontSize: 10, // Slightly smaller text to fit
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
