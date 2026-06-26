import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/company/company_monthly_fee_store.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/domain/usecases/get_companies_usecase.dart';

/// Company dashboard: set monthly accommodation/residency fee for bookings.
class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  final _feeController = TextEditingController();
  final _feeStore = CompanyMonthlyFeeStore.instance;
  List<Company> _companies = [];
  String? _selectedCompanyId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final companies = await sl<GetCompaniesUseCase>()();
    final savedId = await _feeStore.getSelectedCompanyId();
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _selectedCompanyId =
          savedId != null && companies.any((c) => c.id == savedId)
              ? savedId
              : (companies.isNotEmpty ? companies.first.id : null);
      _loading = false;
    });
    if (_selectedCompanyId != null) {
      await _loadFeeForCompany(_selectedCompanyId!);
    }
  }

  Future<void> _loadFeeForCompany(String companyId) async {
    final company = _companies.firstWhere(
      (c) => c.id == companyId,
      orElse: () => _companies.first,
    );
    final stored = await _feeStore.getFee(companyId);
    final fee = company.monthlyAccommodationFee ?? stored ?? 0.0;
    if (mounted) {
      _feeController.text =
          fee > 0 ? fee.toStringAsFixed(0) : '';
    }
  }

  Future<void> _saveFee() async {
    final companyId = _selectedCompanyId;
    if (companyId == null) return;
    final parsed = double.tryParse(_feeController.text.trim());
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.translate(context, 'enterValidFee'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await _feeStore.setFee(companyId, parsed);
    await _feeStore.setSelectedCompanyId(companyId);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.translate(context, 'monthlyFeeSaved')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('companyDashboard') ?? 'Company Dashboard',
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _companies.isEmpty
              ? Center(
                child: Text(
                  l10n?.translate('noCompaniesFound') ?? 'No companies found',
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n?.translate('monthlyAccommodationFeeTitle') ??
                          'Monthly accommodation fee',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.translate('monthlyAccommodationFeeHint') ??
                          'Added to monthly worker bookings for your company.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _selectedCompanyId,
                      decoration: InputDecoration(
                        labelText: l10n?.translate('company') ?? 'Company',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          _companies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                      onChanged: (id) async {
                        if (id == null) return;
                        setState(() => _selectedCompanyId = id);
                        await _feeStore.setSelectedCompanyId(id);
                        await _loadFeeForCompany(id);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText:
                            l10n?.translate('monthlyAccommodationFeeLabel') ??
                            'Fee amount (LYD / month)',
                        suffixText: l10n?.translate('lyd') ?? 'LYD',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _saveFee,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child:
                          _saving
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(l10n?.translate('save') ?? 'Save'),
                    ),
                  ],
                ),
              ),
    );
  }
}
