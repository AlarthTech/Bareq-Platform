import 'package:equatable/equatable.dart';

/// Active bank account for wallet top-up transfers (GET /api/v1/wallet/bank-transfer-account).
class BankTransferAccount extends Equatable {
  final int id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String? iban;
  final String? branchName;
  final String? instructions;
  final bool isActive;

  const BankTransferAccount({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    this.iban,
    this.branchName,
    this.instructions,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        bankName,
        accountHolderName,
        accountNumber,
        iban,
        branchName,
        instructions,
        isActive,
      ];
}
