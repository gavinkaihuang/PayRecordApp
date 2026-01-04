import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bill_item.dart';
import 'bill_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchBills();
  }

  void _fetchBills() {
    Future.microtask(() =>
      Provider.of<BillProvider>(context, listen: false)
          .fetchBills(_focusedDay.year, _focusedDay.month)
    );
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clone to Next Month'),
        content: Text(
          'This will clone bills from ${DateFormat('MMMM').format(_focusedDay)} to next month. Continue?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clone')),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      await billProvider.cloneBillstToNextMonth(_focusedDay.year, _focusedDay.month);
      
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          tooltip: 'Logout',
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black54),
              onPressed: () {
                 setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  _fetchBills();
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(_focusedDay), 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black54),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  _fetchBills();
                });
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.black54),
            tooltip: 'Clone to Next Month',
            onPressed: billProvider.bills.isEmpty ? null : _cloneToNextMonth,
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
            const SizedBox(height: 100), // Spacing for AppBar
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
              calendarFormat: CalendarFormat.month,
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
                markerBuilder: (context, date, events) {
                  final count = billProvider.bills.where((b) => isSameDay(b.date, date)).length;
                  if (count > 0) {
                    return Positioned(
                      right: 6,
                      bottom: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2B5CFF), // Blue dot
                          shape: BoxShape.circle,
                        ),
                        width: 6.0,
                        height: 6.0,
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
                    : billProvider.bills.isEmpty
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
                            itemCount: billProvider.bills.length,
                            padding: const EdgeInsets.only(top: 16, bottom: 80), // Padding for FAB prevention
                            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
                            itemBuilder: (context, index) {
                              final bill = billProvider.bills[index];
                              return BillItem(
                                bill: bill,
                                isSelected: isSameDay(bill.date, _selectedDay),
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
          color: const Color(0xFF5B8CFF), // Blue FAB
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
          icon: const Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Pass selected date as default for new bill
                builder: (context) => BillFormScreen(initialDate: _selectedDay ?? DateTime.now()),
              ),
            ).then((_) => _fetchBills());
          },
        ),
      ),
    );
  }
}
