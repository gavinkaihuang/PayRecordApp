import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _payeeIcon;
  String? _payerIcon;

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
    _payeeIcon = bill?.payeeIcon;
    _payerIcon = bill?.payerIcon;

    _pendingAmountFocus.addListener(() {
      if (_pendingAmountFocus.hasFocus) _checkConflict(isPay: true);
    });
    _pendingReceiveAmountFocus.addListener(() {
      if (_pendingReceiveAmountFocus.hasFocus) _checkConflict(isPay: false);
    });
    _actualReceiveAmountFocus.addListener(() {
      if (_actualReceiveAmountFocus.hasFocus) _checkConflict(isPay: false);
    });
    
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

  Future<void> _checkConflict({required bool isPay}) async {
    if (isPay && _receiveInfoHasData()) {
      _log('Conflict detected: Entering Payment while Receivable exists');
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Conflict Detected'),
          content: const Text('You have entered Receivable data. Do you want to clear it to enter Payment data?'),
          actions: [
            TextButton(
              onPressed: () {
                _log('User chose: Keep Both (Payment & Receivable)');
                Navigator.pop(ctx, false);
              },
              child: const Text('Keep Both'),
            ),
            TextButton(
              onPressed: () {
                _log('User chose: Clear Receivable');
                Navigator.pop(ctx, true);
              },
              child: const Text('Clear Receivable', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) _clearReceiveInfo();
    } 
    
    if (!isPay && _payInfoHasData()) {
       _log('Conflict detected: Entering Receivable while Payment exists');
       await Future.delayed(const Duration(milliseconds: 100));
       if (!mounted) return;

       final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Conflict Detected'),
          content: const Text('You have entered Payment data. Do you want to clear it to enter Receivable data?'),
          actions: [
            TextButton(
               onPressed: () {
                _log('User chose: Keep Both (Payment & Receivable)');
                Navigator.pop(ctx, false);
              },
              child: const Text('Keep Both'),
            ),
            TextButton(
              onPressed: () {
                _log('User chose: Clear Payment');
                Navigator.pop(ctx, true);
              },
              child: const Text('Clear Payment', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) _clearPayInfo();
    }
  }

  Future<void> _pickDate(BuildContext context, {bool isActualPaid = false}) async {
    if (isActualPaid) {
      _checkConflict(isPay: true);
    }
    
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
    await _checkConflict(isPay: isPayee);
    
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
                  if (hasFocus) onFocusAction();
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
                        image: NetworkImage(
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
              
              // Payment Section
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
                        onFocusAction: () => _checkConflict(isPay: true),
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
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Is Paid?'),
                        value: _isPaid,
                        onChanged: (v) {
                           _checkConflict(isPay: true);
                           setState(() => _isPaid = v);
                        },
                      ),
                      if (_isPaid)
                        InkWell(
                          onTap: () => _pickDate(context, isActualPaid: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Actual Paid Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(_actualPaidDate == null 
                                ? 'Select Date' 
                                : DateFormat('yyyy-MM-dd').format(_actualPaidDate!)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Receivable Section
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
                        onFocusAction: () => _checkConflict(isPay: false),
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

              const SizedBox(height: 24),
              
              // Common Section
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
                title: const Text('Is Next Month Same Amount?'),
                value: _isNextMonthSame,
                onChanged: (v) => setState(() => _isNextMonthSame = v),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
