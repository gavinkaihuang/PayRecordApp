import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';

class BillFormScreen extends StatefulWidget {
  final Bill? bill;
  final DateTime? initialDate;

  const BillFormScreen({super.key, this.bill, this.initialDate});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _payTargetController;
  late TextEditingController _pendingAmountController;
  late TextEditingController _receiverController;
  late TextEditingController _pendingReceiveAmountController;
  late TextEditingController _actualReceiveAmountController;
  late TextEditingController _noteController;

  late DateTime _date;
  bool _isPaid = false;
  DateTime? _actualPaidDate;
  bool _isNextMonthSame = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _date = bill?.date ?? widget.initialDate ?? DateTime.now();
    _payTargetController = TextEditingController(text: bill?.payTarget ?? '');
    _pendingAmountController = TextEditingController(text: bill?.pendingAmount?.toString() ?? '');
    _receiverController = TextEditingController(text: bill?.receiver ?? '');
    _pendingReceiveAmountController = TextEditingController(text: bill?.pendingReceiveAmount?.toString() ?? '');
    _actualReceiveAmountController = TextEditingController(text: bill?.actualReceiveAmount?.toString() ?? '');
    _noteController = TextEditingController(text: bill?.note ?? '');
    
    _isPaid = bill?.isPaid ?? false;
    _actualPaidDate = bill?.actualPaidDate;
    _isNextMonthSame = bill?.isNextMonthSame ?? false;
  }

  @override
  void dispose() {
    _payTargetController.dispose();
    _pendingAmountController.dispose();
    _receiverController.dispose();
    _pendingReceiveAmountController.dispose();
    _actualReceiveAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {bool isActualPaid = false}) async {
    final initial = isActualPaid 
        ? (_actualPaidDate ?? DateTime.now())
        : _date;
        
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isActualPaid) {
          _actualPaidDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final billData = Bill(
      id: widget.bill?.id, // Should check if ID is used in update
      date: _date,
      payTarget: _payTargetController.text,
      pendingAmount: double.tryParse(_pendingAmountController.text),
      isPaid: _isPaid,
      actualPaidDate: _actualPaidDate,
      receiver: _receiverController.text.isEmpty ? null : _receiverController.text,
      pendingReceiveAmount: double.tryParse(_pendingReceiveAmountController.text),
      actualReceiveAmount: double.tryParse(_actualReceiveAmountController.text),
      note: _noteController.text,
      isNextMonthSame: _isNextMonthSame,
    );

    final provider = Provider.of<BillProvider>(context, listen: false);
    bool success;
    if (widget.bill != null) {
       // Update
       success = await provider.updateBill(widget.bill!.id!, billData);
    } else {
       // Add
       success = await provider.addBill(billData);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed. Check connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bill == null ? 'Add Bill' : 'Edit Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Date
              ListTile(
                title: const Text('Bill Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context),
              ),
              const Divider(),
              TextFormField(
                controller: _payTargetController,
                decoration: const InputDecoration(labelText: 'Pay Target (Required)'),
                validator: (v) => v == null || v.isEmpty ? 'Please enter pay target' : null,
              ),
              TextFormField(
                controller: _pendingAmountController,
                decoration: const InputDecoration(labelText: 'Pending Amount'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('Is Paid?'),
                value: _isPaid,
                onChanged: (v) => setState(() => _isPaid = v),
              ),
              if (_isPaid)
                ListTile(
                  title: const Text('Actual Paid Date'),
                  subtitle: Text(_actualPaidDate == null 
                      ? 'Select Date' 
                      : DateFormat('yyyy-MM-dd').format(_actualPaidDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(context, isActualPaid: true),
                ),
              const Divider(),
              TextFormField(
                controller: _receiverController,
                decoration: const InputDecoration(labelText: 'Receiver'),
              ),
              TextFormField(
                controller: _pendingReceiveAmountController,
                decoration: const InputDecoration(labelText: 'Pending Receive Amount'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _actualReceiveAmountController,
                decoration: const InputDecoration(labelText: 'Actual Receive Amount'),
                keyboardType: TextInputType.number,
              ),
              const Divider(),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 3,
              ),
              SwitchListTile(
                title: const Text('Is Next Month Same Amount?'),
                value: _isNextMonthSame,
                onChanged: (v) => setState(() => _isNextMonthSame = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
