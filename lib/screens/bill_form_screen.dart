import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../services/api_service.dart';
import '../services/log_service.dart';

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
  late TextEditingController _payerController;
  late TextEditingController _pendingReceiveAmountController;
  late TextEditingController _actualReceiveAmountController;
  late TextEditingController _noteController;

  // FocusNodes
  final FocusNode _pendingAmountFocus = FocusNode();
  final FocusNode _pendingReceiveAmountFocus = FocusNode();
  final FocusNode _actualReceiveAmountFocus = FocusNode();

  late DateTime _date;
  bool _isPaid = false;
  DateTime? _actualPaidDate;
  bool _isNextMonthSame = false;
  int _recurringInterval = 1;
  String? _payeeIcon;
  String? _payerIcon;
  
  bool _isIncomeMode = false;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _date = bill?.date ?? widget.initialDate ?? DateTime.now();
    _payTargetController = TextEditingController(text: bill?.payTarget ?? '');
    _pendingAmountController = TextEditingController(text: bill?.pendingAmount?.toString() ?? '');
    _payerController = TextEditingController(text: bill?.payer ?? '');
    _pendingReceiveAmountController = TextEditingController(text: bill?.pendingReceiveAmount?.toString() ?? '');
    _actualReceiveAmountController = TextEditingController(text: bill?.actualReceiveAmount?.toString() ?? '');
    _noteController = TextEditingController(text: bill?.note ?? '');
    
    _isPaid = bill?.isPaid ?? false;
    _actualPaidDate = bill?.actualPaidDate;
    _isNextMonthSame = bill?.isNextMonthSame ?? false;
    _recurringInterval = bill?.recurringInterval ?? 1;
    _payeeIcon = bill?.payeeIcon;
    _payerIcon = bill?.payerIcon;

    // Determine initial mode based on existing data
    if (bill != null && (bill.payer != null || bill.pendingReceiveAmount != null)) {
       _isIncomeMode = true;
    }
    
    // We can effectively remove the listener if we rely on explicit mode, 
    // but keeping it doesn't hurt, though we rely on _isIncomeMode for UI labels now.
    // _payerController.addListener(() {
    //   if (mounted) setState(() {});
    // });
    
    _log('Opened ${widget.bill == null ? "Add" : "Edit"} Bill Form');
  }

  void _log(String message) {
    if (ApiService.isDevMode) {
      LogService().addLog('UserOp: $message');
    }
  }

  @override
  void dispose() {
    _log('Form closed');
    _payTargetController.dispose();
    _pendingAmountController.dispose();
    _payerController.dispose();
    _pendingReceiveAmountController.dispose();
    _actualReceiveAmountController.dispose();
    _noteController.dispose();
    _pendingAmountFocus.dispose();
    _pendingReceiveAmountFocus.dispose();
    _actualReceiveAmountFocus.dispose();
    super.dispose();
  }

  bool _payInfoHasData() {
    return _payTargetController.text.isNotEmpty || 
           _pendingAmountController.text.isNotEmpty ||
           _payeeIcon != null ||
           _isPaid;
  }

  bool _receiveInfoHasData() {
    return _payerController.text.isNotEmpty ||
           _pendingReceiveAmountController.text.isNotEmpty ||
           _actualReceiveAmountController.text.isNotEmpty ||
           _payerIcon != null;
  }

  void _clearPayInfo() {
    setState(() {
      _payTargetController.clear();
      _pendingAmountController.clear();
      _payeeIcon = null;
      _isPaid = false;
      _actualPaidDate = null;
    });
  }

  void _clearReceiveInfo() {
    setState(() {
      _payerController.clear();
      _pendingReceiveAmountController.clear();
      _actualReceiveAmountController.clear();
      _payerIcon = null;
    });
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
      _log('Picked Date: ${DateFormat('yyyy-MM-dd').format(picked)} (For: ${isActualPaid ? "Actual Paid" : "Bill Date"})');
      setState(() {
        if (isActualPaid) {
          _actualPaidDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  Future<void> _pickAndUploadIcon(bool isPayee) async {

    
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        _log('Icon selection cancelled');
        return;
      }
      _log('Icon selected: ${image.path}. Uploading...');
      setState(() => _isLoading = true);

      // Upload via ApiService
      // We need access to ApiService directly or via Provider. 
      // Provider logic usually manages state, but simple upload can be utility.
      // Assuming we can create a temporary instance or add upload method to BillProvider.
      // Since I added uploadFile to ApiService, let's use it.
      // But ApiService instance in provider is private. 
      // I'll instantiate one here or expose it. Instantiating is fine for now as it handles its own dio.
      // Actually, better to add upload method to BillProvider to keep auth token logic if needed (though upload might not need it, usually it does).
      // ApiService handles token internally with SharedPreferences intercepter. So safe to new it.
      
      final apiService = ApiService();
      final url = await apiService.uploadFile(File(image.path));

      if (url != null) {
        setState(() {
          if (isPayee) {
            _payeeIcon = url;
          } else {
            _payerIcon = url;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Icon uploaded!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed.')));
        }
      }
    } catch (e) {
      print('Pick icon error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    bool hasPay = _payTargetController.text.isNotEmpty;
    bool hasReceive = _payerController.text.isNotEmpty;
    
    // Relaxed validation: at least one side should present or follow existing validation
    if (!hasPay && !hasReceive) {
        // If neither is present, and we have default validators, let it fail there or show snackbar
        _log('Save attempted with empty Pay and Receive fields');
    }

    if (hasPay && hasReceive) {
        _log('Save conflict: Both Pay and Receive data present');
        await showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: const Text('Data Conflict'),
            content: const Text('You have entered data for both Expense and Income. Please clear one side before saving.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          )
        );
        return;
    }
    
    if (!_formKey.currentState!.validate()) {
      _log('Save validation failed');
      return;
    }
    
    _log('Saving Bill...');
    setState(() => _isLoading = true);

    final billData = Bill(
      id: widget.bill?.id, 
      date: _date,
      payTarget: _payTargetController.text,
      pendingAmount: double.tryParse(_pendingAmountController.text),
      isPaid: _isPaid,
      actualPaidDate: _actualPaidDate,
      payer: _payerController.text.isEmpty ? null : _payerController.text,
      receiver: null, // Receiver is implicit (User), or unused for now
      pendingReceiveAmount: double.tryParse(_pendingReceiveAmountController.text),
      actualReceiveAmount: double.tryParse(_actualReceiveAmountController.text),
      note: _noteController.text,
      isNextMonthSame: _isNextMonthSame,
      recurringInterval: _recurringInterval,
      payeeIcon: _payeeIcon,
      payerIcon: _payerIcon,
    );

    final provider = Provider.of<BillProvider>(context, listen: false);
    
    // Attempt to link icons to merchants before saving bill
    // We use a temporary ApiService instance or add logic to provider. 
    // Using ApiService directly here as it is a specific utility operation.
    final apiService = ApiService();
    
    if (_payeeIcon != null && _payTargetController.text.isNotEmpty) {
      await apiService.setMerchantIcon(_payTargetController.text, _payeeIcon!);
    }
    
    if (_payerIcon != null && _payerController.text.isNotEmpty) {
      await apiService.setMerchantIcon(_payerController.text, _payerIcon!);
    }

    bool success;
    if (widget.bill != null) {
       success = await provider.updateBill(widget.bill!.id!, billData);
    } else {
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

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    required VoidCallback onIconPressed,
    required Function() onFocusAction,
    String? currentIconUrl,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: controller.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return options.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              controller.text = selection;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              if (controller.text != textEditingController.text) {
                textEditingController.text = controller.text;
                textEditingController.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              }

              return Focus(
                onFocusChange: (hasFocus) {
                  // if (hasFocus) onFocusAction(); // Removed conflict check on focus
                },
                child: TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (isRequired && (v == null || v.isEmpty)) {
                        // If we are in conflict mode, maybe validation should be relaxed?
                        // For now stick to standard Validator
                       return 'Please enter value';
                    }
                    return null;
                  },
                  onChanged: (val) => controller.text = val,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: GestureDetector(
            onTap: onIconPressed,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: currentIconUrl != null 
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                            currentIconUrl.startsWith('http') 
                            ? currentIconUrl 
                            : '${ApiService.serverUrl}/${currentIconUrl.startsWith('/') ? currentIconUrl.substring(1) : currentIconUrl}'
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: currentIconUrl == null 
                  ? const Icon(Icons.add_photo_alternate, color: Colors.grey)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BillProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                contentPadding: EdgeInsets.zero,
                title: const Text('Bill Date', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_date), style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                onTap: () => _pickDate(context),
              ),
              const SizedBox(height: 16),
              
              // Mode Toggle
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncomeMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isIncomeMode ? Colors.blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !_isIncomeMode ? [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ] : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '支出 (Expense)',
                            style: TextStyle(
                              color: !_isIncomeMode ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncomeMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isIncomeMode ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _isIncomeMode ? [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ] : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '收入 (Income)',
                            style: TextStyle(
                              color: _isIncomeMode ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              
              // Payment Section
              if (!_isIncomeMode)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 16),
                        _buildAutocompleteField(
                          controller: _payTargetController,
                          label: 'Pay Target',
                          options: provider.uniquePayees,
                          onIconPressed: () => _pickAndUploadIcon(true),
                          onFocusAction: () {},
                          currentIconUrl: _payeeIcon,
                          isRequired: false, 
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pendingAmountController,
                          focusNode: _pendingAmountFocus,
                          decoration: const InputDecoration(
                            labelText: 'Pending Amount',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                      ],
                    ),
                  ),
                ),

              if (!_isIncomeMode) const SizedBox(height: 24),

              // Receivable Section
              if (_isIncomeMode)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Receivable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 16),
                        _buildAutocompleteField(
                          controller: _payerController,
                          label: 'Payer',
                          options: provider.uniquePayers,
                          onIconPressed: () => _pickAndUploadIcon(false),
                          onFocusAction: () {},
                          currentIconUrl: _payerIcon,
                          isRequired: false,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pendingReceiveAmountController,
                          focusNode: _pendingReceiveAmountFocus,
                          decoration: const InputDecoration(
                            labelText: 'Pending Receive Amount',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _actualReceiveAmountController,
                          focusNode: _actualReceiveAmountFocus,
                          decoration: const InputDecoration(
                            labelText: 'Actual Receive Amount',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.check_circle_outline),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (_isIncomeMode) const SizedBox(height: 24),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_isIncomeMode ? '已接收' : '已支付'),
                value: _isPaid,
                onChanged: (v) {
                   setState(() {
                     _isPaid = v;
                     if (_isPaid && _actualPaidDate == null) {
                       _actualPaidDate = DateTime.now();
                     }
                   });
                },
              ),
              if (_isPaid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () => _pickDate(context, isActualPaid: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _isIncomeMode ? '实际到账日期' : '实际支付日期',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(_actualPaidDate == null 
                          ? 'Select Date' 
                          : DateFormat('yyyy-MM-dd').format(_actualPaidDate!)),
                    ),
                  ),
                ),
              
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                 contentPadding: EdgeInsets.zero,
                title: const Text('Is Recurring Bill?'),
                value: _isNextMonthSame,
                onChanged: (v) => setState(() => _isNextMonthSame = v),
              ),
              if (_isNextMonthSame)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Row(
                    children: [
                      const Text('Recurring Interval: '),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _recurringInterval,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Monthly')),
                          DropdownMenuItem(value: 2, child: Text('Every 2 Months')),
                          DropdownMenuItem(value: 3, child: Text('Quarterly (3 Mo)')),
                          DropdownMenuItem(value: 6, child: Text('Every 6 Months')),
                          DropdownMenuItem(value: 12, child: Text('Annually')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _recurringInterval = v);
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              


            ],
          ),
        ),
      ),
    );
  }
}
