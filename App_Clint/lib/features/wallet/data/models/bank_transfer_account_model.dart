import '../../domain/entities/bank_transfer_account.dart';

class BankTransferAccountModel extends BankTransferAccount {
  const BankTransferAccountModel({
    required super.id,
    required super.bankName,
    required super.accountHolderName,
    required super.accountNumber,
    super.iban,
    super.branchName,
    super.instructions,
    required super.isActive,
  });

  factory BankTransferAccountModel.fromJson(Map<String, dynamic> json) {
    return BankTransferAccountModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bankName: json['bankName']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      iban: json['iban']?.toString(),
      branchName: json['branchName']?.toString(),
      instructions: json['instructions']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}
