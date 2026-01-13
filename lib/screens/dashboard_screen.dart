import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../models/bill.dart';
import '../widgets/bill_item.dart';
import '../services/api_service.dart';
import 'bill_form_screen.dart';
import 'settings_screen.dart';
import '../services/log_service.dart';
import '../widgets/monthly_statistics_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _showUnpaidOnly = false;
  bool _showStats = false; // Toggle state for Calendar vs Stats
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    if (ApiService.isDevMode) print('DashboardScreen initState called');
    _selectedDay = _focusedDay;
    // Delay fetch to avoid setState during build
    Future.microtask(() => _fetchBills());
  }

  Future<void> _fetchBills() async {
    await Provider.of<BillProvider>(context, listen: false)
          .fetchBills(_focusedDay.year, _focusedDay.month);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      // Scroll to the first bill of the selected date
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      final index = billProvider.bills.indexWhere((bill) => isSameDay(bill.date, selectedDay));
      if (index != -1) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _cloneToNextMonth() async {
    if (ApiService.isDevMode) {
      LogService().addLog('UserOp: Clicked Clone to Next Month');
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clone to Next Month'),
        content: Text(
          'Are you sure you want to clone the monthly plan from ${DateFormat('MMMM').format(_focusedDay)} to the next period?'
        ),
        actions: [
          TextButton(
            onPressed: () {
               if (ApiService.isDevMode) LogService().addLog('UserOp: Clone Cancelled');
               Navigator.pop(ctx, false);
            }, 
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () {
               if (ApiService.isDevMode) LogService().addLog('UserOp: Clone Confirmed');
               Navigator.pop(ctx, true);
            }, 
            child: const Text('Clone')
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      
      if (ApiService.isDevMode) LogService().addLog('UserOp: Submitting Clone Request...');
      
      // Calculate next month
      final nextMonthDate = DateTime(_focusedDay.year, _focusedDay.month + 1);
      await billProvider.cloneBillsClientSide(nextMonthDate.year, nextMonthDate.month);
      
      // Navigate to next month to see results
      setState(() {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
        _selectedDay = _focusedDay;
      });
      _fetchBills();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloned successfully!')),
      );
      if (ApiService.isDevMode) LogService().addLog('UserOp: Clone Success');
    }
  }

  Future<void> _onQuickPay(Bill bill) async {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    
    // Create updated bill object
    final updatedBill = Bill(
      id: bill.id,
      date: bill.date,
      payTarget: bill.payTarget,
      pendingAmount: bill.pendingAmount,
      isPaid: true,
      actualPaidDate: DateTime.now(), // Set to now
      payer: bill.payer,
      receiver: bill.receiver,
      pendingReceiveAmount: bill.pendingReceiveAmount,
      actualReceiveAmount: bill.actualReceiveAmount,
      note: bill.note,
      isNextMonthSame: bill.isNextMonthSame,
    );

    final success = await billProvider.updateBill(bill.id!, updatedBill);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as paid!')),
      );
      _fetchBills(); // Refresh list to update UI
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bill')),
      );
    }
  }

  Future<void> _onExitApp() async {
    if (Platform.isIOS) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swipe up to close app on iOS')),
      );
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);
    
    // Filter bills if needed
    final visibleBills = _showUnpaidOnly 
        ? billProvider.bills.where((b) => !b.isPaid).toList()
        : billProvider.bills;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          tooltip: 'Exit App',
          onPressed: () {
            LogService().addLog('UserOp: Exit App Clicked');
            _onExitApp();
          },
        ),
        title: const Text(
          'PayRecord',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showUnpaidOnly ? Icons.filter_alt : Icons.filter_alt_off, 
              color: _showUnpaidOnly ? Colors.blue : Colors.black54
            ),
            tooltip: 'Filter Unpaid',
            onPressed: () {
              setState(() {
                _showUnpaidOnly = !_showUnpaidOnly;
              });
              if (ApiService.isDevMode) {
                 LogService().addLog('UserOp: Toggled Unpaid Filter: $_showUnpaidOnly');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_week, color: Colors.black54),
            tooltip: 'Toggle View',
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0EAFC), // Light blueish
              Color(0xFFCFDEF3), // Light purpleish
              Color(0xFFF5F7FA), // Light greyish
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight), 
            
            // Month Switcher moved here
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black54),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () {
                       setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                        _fetchBills();
                      });
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _calendarFormat = _calendarFormat == CalendarFormat.month
                            ? CalendarFormat.week
                            : CalendarFormat.month;
                      });
                    },
                    child: Text(
                      DateFormat('MMM yyyy').format(_focusedDay), 
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.black54),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                        _fetchBills();
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Toggle for View Mode (Calendar vs Overview)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 8.0),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _buildToggleOption(
                      title: 'Calendar', 
                      isSelected: !_showStats,
                      onTap: () {
                         if (_showStats) {
                           setState(() => _showStats = false);
                           if (ApiService.isDevMode) LogService().addLog('UserOp: Switched to Calendar View');
                         }
                      }
                    ),
                    _buildToggleOption(
                      title: 'Overview', 
                      isSelected: _showStats,
                      onTap: () {
                        if (!_showStats) {
                          setState(() => _showStats = true);
                          if (ApiService.isDevMode) LogService().addLog('UserOp: Switched to Stats View');
                        }
                      }
                    ),
                  ],
                ),
              ),
            ),

            if (_showStats)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: MonthlyStatisticsWidget(bills: visibleBills),
              )
            else
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _fetchBills();
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                headerVisible: false, // We use custom AppBar title
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(color: Colors.black87),
                  weekendTextStyle: TextStyle(color: Colors.black87),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFD6E4FF), // Light blue selection circle
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: Color(0xFF2B5CFF), fontWeight: FontWeight.bold),
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent, 
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.blue, width: 1)),
                  ),
                  todayTextStyle: TextStyle(color: Colors.blue),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.black54),
                  weekendStyle: TextStyle(color: Colors.black54),
                ),
                calendarBuilders: CalendarBuilders(
                  // Custom background for payment status
                  defaultBuilder: (context, date, focusedDay) {
                    final bills = visibleBills.where((b) => isSameDay(b.date, date)).toList();
                    if (bills.isEmpty) return null;

                    Color? bgColor;
                    if (bills.every((b) => b.isPaid)) {
                      bgColor = const Color(0xFFE8F5E9); // Green tint for all paid
                    } else if (bills.every((b) => !b.isPaid)) {
                      bgColor = const Color(0xFFFFEBEE); // Red tint for all unpaid
                    } else {
                      bgColor = const Color(0xFFFFFDE7); // Yellow tint for mixed
                    }

                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  },
                  
                  // Keep selected day distinctive but maybe hint at status? 
                  // For now, standard selection blue circle as per previous design compliance
                  selectedBuilder: (context, date, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD6E4FF), 
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(color: Color(0xFF2B5CFF), fontWeight: FontWeight.bold),
                      ),
                    );
                  },

                  // Marker: Show number if bills exist
                  markerBuilder: (context, date, events) {
                    final bills = visibleBills.where((b) => isSameDay(b.date, date)).toList();
                    if (bills.isNotEmpty) {
                      final isAllPaid = bills.every((b) => b.isPaid);
                      final isAllUnpaid = bills.every((b) => !b.isPaid);
                      
                      // Use a more legible marker count
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            // Marker color logic: 
                            // If background is colored, maybe use contrasting marker?
                            // Let's stick to Blue for standard, or match status?
                            // User requested "change dot to number". 
                            // I'll use a small badge.
                            color: isAllPaid ? Colors.green : (isAllUnpaid ? Colors.red : Colors.orange),
                            shape: BoxShape.circle,
                          ),
                          width: 14.0,
                          height: 14.0,
                          child: Center(
                            child: Text(
                              '${bills.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: billProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : visibleBills.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.inbox, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No bills for this month',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ScrollablePositionedList.separated(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            itemCount: visibleBills.length,
                            padding: const EdgeInsets.only(top: 16, bottom: 80), // Padding for FAB prevention
                            // separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)), // Removed for card style
                            separatorBuilder: (context, index) => const SizedBox(height: 0),
                            itemBuilder: (context, index) {
                              final bill = visibleBills[index];
                              return BillItem(
                                bill: bill,
                                isSelected: isSameDay(bill.date, _selectedDay),
                                onPayClick: () => _onQuickPay(bill),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BillFormScreen(bill: bill),
                                    ),
                                  ).then((_) => _fetchBills());
                                },
                              );
                            },
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF5B8CFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          onPressed: () {
            LogService().addLog('UserOp: Opened Main Menu');
            showModalBottomSheet(
              context: context, 
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.blue),
                      title: const Text('Add New Bill'),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillFormScreen(initialDate: _selectedDay ?? DateTime.now()),
                          ),
                        ).then((_) => _fetchBills());
                      },
                    ),
                    const Divider(),
                    if (billProvider.bills.isNotEmpty)
                      ListTile(
                         leading: const Icon(Icons.copy, color: Colors.indigo),
                         title: const Text('Clone to Next Month'),
                         onTap: () {
                           Navigator.pop(ctx);
                           _cloneToNextMonth();
                         },
                      ),
                    if (billProvider.bills.isNotEmpty) const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.grey),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title, 
    required bool isSelected, 
    required VoidCallback onTap
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B8CFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
