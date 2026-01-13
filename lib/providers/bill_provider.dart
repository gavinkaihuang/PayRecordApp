import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bill.dart';

class BillProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Bill> _bills = [];
  bool _isLoading = false;

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;

  List<String> get uniquePayees => _bills
      .map((b) => b.payTarget)
      .toSet()
      .toList();

  List<String> get uniquePayers => _bills
      .map((b) => b.payer)
      .where((p) => p != null && p.isNotEmpty)
      .map((p) => p!)
      .toSet()
      .toList();

  Future<void> fetchBills(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getBills(year, month);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _bills = data.map((json) => Bill.fromJson(json)).toList();
      }
    } catch (e) {
      print('Fetch bills error: $e');
      _bills = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBill(Bill bill) async {
    try {
      final response = await _apiService.addBill(bill.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Optimistically add or refresh
        // For now, simpler to just return true and let UI trigger refresh
        return true;
      }
    } catch (e) {
      print('Add bill error: $e');
    }
    return false;
  }

  Future<bool> updateBill(String id, Bill bill) async {
    try {
      final response = await _apiService.updateBill(id, bill.toJson());
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Update bill error: $e');
    }
    return false;
  }

  Future<void> cloneBillsClientSide(int targetYear, int targetMonth) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (ApiService.isDevMode) {
        print('====== [UserOp] Running Client-Side Clone for Target: $targetYear-$targetMonth ======');
      }
      
      List<Bill> billsToClone = [];
      
      // 1. Server Side Clone for Monthly (Interval 1)
      // The server API clones FROM the given year/month TO the next month.
      // So if we want bills in TargetMonth, we tell server to clone from TargetMonth - 1.
      final sourceDateForMonthly = DateTime(targetYear, targetMonth - 1, 1);
      if (ApiService.isDevMode) {
        print('====== [UserOp] calling Server Clone for Monthly bills from: ${sourceDateForMonthly.year}-${sourceDateForMonthly.month} ======');
      }
      await _apiService.cloneBills(sourceDateForMonthly.year, sourceDateForMonthly.month);

      // 2. Client Side Clone for Custom Intervals (Intervals > 1)
      final intervals = [2, 3, 6, 12]; // Skip 1, server handled it
      
      for (final interval in intervals) {
        // Calculate source date: target - interval months
        // DateTime handles year rollover automatically
        // using day 1 to avoid overflow issues during month math
        final sourceDate = DateTime(targetYear, targetMonth - interval, 1);
        
        if (ApiService.isDevMode) {
          print('Checking source: ${sourceDate.year}-${sourceDate.month} for interval $interval');
        }

        final response = await _apiService.getBills(sourceDate.year, sourceDate.month);
        if (response.statusCode == 200) {
           final List<dynamic> data = response.data;
           final sourceBills = data.map((json) => Bill.fromJson(json)).toList();
           
           // Filter
           final matching = sourceBills.where((b) => 
              b.isNextMonthSame && b.recurringInterval == interval
           ).toList();
           
           if (ApiService.isDevMode) {
             print('Found ${matching.length} matching bills for interval $interval');
           }
           
           billsToClone.addAll(matching);
        }
      }
      
      // Add all identified bills to target month
      int addedCount = 0;
      for (final b in billsToClone) {
        // Handle day overflow (e.g., Jan 31 -> Feb 28)
        int day = b.date.day;
        int lastDayOfTarget = DateTime(targetYear, targetMonth + 1, 0).day;
        if (day > lastDayOfTarget) day = lastDayOfTarget;

        final newBill = Bill(
          date: DateTime(targetYear, targetMonth, day),
          payTarget: b.payTarget,
          pendingAmount: b.pendingAmount,
          isPaid: false, // Reset status
          payer: b.payer,
          receiver: b.receiver,
          pendingReceiveAmount: b.pendingReceiveAmount,
          note: b.note,
          isNextMonthSame: true, // Keep recurring
          recurringInterval: b.recurringInterval, // Keep interval
          payeeIcon: b.payeeIcon,
          payerIcon: b.payerIcon,
        );
        
        bool success = await addBill(newBill);
        if (success) addedCount++;
      }
      
       if (ApiService.isDevMode) {
         print('====== [UserOp] Client-Side Clone Complete. Added $addedCount bills. ======');
       }
      
    } catch (e) {
      print('Client-side clone error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  String? getMostRecentPayeeIcon(String name) {
    try {
      final match = _bills.firstWhere((b) => b.payTarget == name && b.payeeIcon != null && b.payeeIcon!.isNotEmpty);
      return match.payeeIcon;
    } catch (e) {
      return null;
    }
  }

  String? getMostRecentPayerIcon(String name) {
    try {
      final match = _bills.firstWhere((b) => b.payer == name && b.payerIcon != null && b.payerIcon!.isNotEmpty);
      return match.payerIcon;
    } catch (e) {
      return null;
    }
  }
}
