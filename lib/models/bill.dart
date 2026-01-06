class Bill {
  final String? id;
  final DateTime date;
  final String payTarget; // Maps to 'payee'
  final double? pendingAmount; // Maps to 'payAmount'
  final bool isPaid;
  final DateTime? actualPaidDate; // Maps to 'paidDate'
  final String? payer; // New field
  final String? receiver;
  final double? pendingReceiveAmount;
  final double? actualReceiveAmount;
  final String? note; // Maps to 'notes'
  final bool isNextMonthSame; // Maps to 'isRecurring'
  final String? payeeIcon;
  final String? payerIcon;

  Bill({
    this.id,
    required this.date,
    required this.payTarget,
    this.pendingAmount,
    this.isPaid = false,
    this.actualPaidDate,
    this.payer,
    this.receiver,
    this.pendingReceiveAmount,
    this.actualReceiveAmount,
    this.note,
    this.isNextMonthSame = false,
    this.payeeIcon,
    this.payerIcon,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? json['id'],
      date: DateTime.parse(json['date']).toLocal(),
      payTarget: json['payee'] ?? json['payTarget'] ?? '',
      pendingAmount: (json['payAmount'] ?? json['pendingAmount'])?.toDouble(),
      isPaid: json['isPaid'] ?? false,
      actualPaidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']).toLocal() : (json['actualPaidDate'] != null ? DateTime.parse(json['actualPaidDate']).toLocal() : null),
      payer: json['payer'],
      receiver: json['receiver'],
      pendingReceiveAmount: (json['receiveAmount'] ?? json['pendingReceiveAmount'])?.toDouble(),
      actualReceiveAmount: json['actualReceiveAmount']?.toDouble(),
      note: json['notes'] ?? json['note'],
      isNextMonthSame: json['isRecurring'] ?? json['isNextMonthSame'] ?? false,
      payeeIcon: json['payeeIcon'],
      payerIcon: json['payerIcon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'payee': payTarget,
      'payAmount': pendingAmount,
      'isPaid': isPaid,
      'paidDate': actualPaidDate?.toIso8601String(),
      'payer': payer,
      'receiver': receiver,
      'receiveAmount': pendingReceiveAmount,
      'actualReceiveAmount': actualReceiveAmount,
      'notes': note,
      'isRecurring': isNextMonthSame,
      'payeeIcon': payeeIcon,
      'payerIcon': payerIcon,
    };
  }
}
