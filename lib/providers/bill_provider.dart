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

  Future<void> cloneBillstToNextMonth(int currentYear, int currentMonth) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (ApiService.isDevMode) {
        print('====== [UserOp] Calling Backend Clone API for $currentYear-$currentMonth ======');
      }
      final response = await _apiService.cloneBills(currentYear, currentMonth);
      if (response.statusCode == 200 || response.statusCode == 201) {
         if (ApiService.isDevMode) {
           print('====== [UserOp] Backend Clone Successful ======');
         }
      } else {
         if (ApiService.isDevMode) {
           print('====== [UserOp] Backend Clone Failed: ${response.statusCode} ======');
         }
      }
    } catch (e) {
      print('Clone error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
