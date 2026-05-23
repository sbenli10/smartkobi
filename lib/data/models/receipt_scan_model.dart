class ReceiptScanModel {
  final String id;
  final String userId;
  final String? businessId;
  final String? businessDocumentId;
  final String? transactionId;
  final String scanStatus;
  final String sourceType;
  final String? fileName;
  final String? filePath;
  final String? fileMimeType;
  final int? fileSizeBytes;
  final String? extractedVendorName;
  final String? extractedTaxNumber;
  final String? extractedDocumentNumber;
  final DateTime? extractedDocumentDate;
  final double? extractedTotalAmount;
  final double? extractedTaxAmount;
  final double? extractedNetAmount;
  final String extractedCurrency;
  final String? suggestedCategory;
  final String? suggestedDescription;
  final int confidenceScore;
  final String? rawOcrText;
  final Map<String, dynamic> aiResult;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReceiptScanModel({
    required this.id,
    required this.userId,
    this.businessId,
    this.businessDocumentId,
    this.transactionId,
    required this.scanStatus,
    required this.sourceType,
    this.fileName,
    this.filePath,
    this.fileMimeType,
    this.fileSizeBytes,
    this.extractedVendorName,
    this.extractedTaxNumber,
    this.extractedDocumentNumber,
    this.extractedDocumentDate,
    this.extractedTotalAmount,
    this.extractedTaxAmount,
    this.extractedNetAmount,
    required this.extractedCurrency,
    this.suggestedCategory,
    this.suggestedDescription,
    required this.confidenceScore,
    this.rawOcrText,
    required this.aiResult,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => scanStatus == 'pending';
  bool get isProcessing => scanStatus == 'processing';
  bool get isCompleted => scanStatus == 'completed';
  bool get isFailed => scanStatus == 'failed';
  bool get isSaved => scanStatus == 'saved';

  factory ReceiptScanModel.fromJson(Map<String, dynamic> json) {
    return ReceiptScanModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String?,
      businessDocumentId: json['business_document_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      scanStatus: json['scan_status'] as String,
      sourceType: json['source_type'] as String,
      fileName: json['file_name'] as String?,
      filePath: json['file_path'] as String?,
      fileMimeType: json['file_mime_type'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      extractedVendorName: json['extracted_vendor_name'] as String?,
      extractedTaxNumber: json['extracted_tax_number'] as String?,
      extractedDocumentNumber: json['extracted_document_number'] as String?,
      extractedDocumentDate: json['extracted_document_date'] != null
          ? DateTime.parse(json['extracted_document_date'].toString())
          : null,
      extractedTotalAmount: json['extracted_total_amount'] != null
          ? double.parse(json['extracted_total_amount'].toString())
          : null,
      extractedTaxAmount: json['extracted_tax_amount'] != null
          ? double.parse(json['extracted_tax_amount'].toString())
          : null,
      extractedNetAmount: json['extracted_net_amount'] != null
          ? double.parse(json['extracted_net_amount'].toString())
          : null,
      extractedCurrency: json['extracted_currency'] as String? ?? 'TRY',
      suggestedCategory: json['suggested_category'] as String?,
      suggestedDescription: json['suggested_description'] as String?,
      confidenceScore: json['confidence_score'] as int? ?? 0,
      rawOcrText: json['raw_ocr_text'] as String?,
      aiResult: json['ai_result'] as Map<String, dynamic>? ?? {},
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }
}