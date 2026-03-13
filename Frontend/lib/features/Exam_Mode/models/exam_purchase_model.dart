class ExamPurchaseModel {
  final String uid;
  final String authorId;
  final String subjectCode;
  final String productId;
  final String purchaseId;
  final String status;
  final String priceLabel;
  final DateTime createdAt;

  const ExamPurchaseModel({
    required this.uid,
    required this.authorId,
    required this.subjectCode,
    required this.productId,
    required this.purchaseId,
    required this.status,
    required this.priceLabel,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'authorId': authorId,
      'subjectCode': subjectCode,
      'productId': productId,
      'purchaseId': purchaseId,
      'status': status,
      'priceLabel': priceLabel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamPurchaseModel.fromMap(Map<String, dynamic> map) {
    return ExamPurchaseModel(
      uid: map['uid']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      purchaseId: map['purchaseId']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      priceLabel: map['priceLabel']?.toString() ?? 'Rs 0',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
