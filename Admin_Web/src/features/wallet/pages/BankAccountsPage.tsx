import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Plus, Pencil, CheckCircle, XCircle } from 'lucide-react';
import { ROUTES } from '../../../core/constants';
import { PageHeader } from '../../../shared/components/PageHeader';
import { DataTable } from '../../../shared/tables/DataTable';
import { FormModal } from '../../../shared/forms/FormModal';
import { Button } from '../../../shared/ui/Button';
import { ConfirmModal } from '../../../shared/components/ConfirmModal';
import { useToast } from '../../../shared/context/ToastContext';
import { getErrorMessage } from '../../../core/utils/getErrorMessage';
import { useBankAccounts, useBankAccountMutations } from '../hooks/useBankAccounts';
import type { BankAccountDTO, CreateBankAccountDTO } from '../types';

const emptyForm: CreateBankAccountDTO = {
  bankName: '',
  accountHolderName: '',
  accountNumber: '',
  iban: '',
  branchName: '',
  instructions: '',
  isActive: false,
};

export default function BankAccountsPage() {
  const { showToast } = useToast();
  const { data: accounts = [], isLoading } = useBankAccounts();
  const { create, update, activate, deactivate } = useBankAccountMutations();

  const [modalOpen, setModalOpen] = useState(false);
  const [editItem, setEditItem] = useState<BankAccountDTO | null>(null);
  const [form, setForm] = useState<CreateBankAccountDTO>(emptyForm);
  const [activateId, setActivateId] = useState<number | null>(null);

  const openCreate = () => {
    setEditItem(null);
    setForm(emptyForm);
    setModalOpen(true);
  };

  const openEdit = (item: BankAccountDTO) => {
    setEditItem(item);
    setForm({
      bankName: item.bankName,
      accountHolderName: item.accountHolderName,
      accountNumber: item.accountNumber,
      iban: item.iban,
      branchName: item.branchName ?? '',
      instructions: item.instructions ?? '',
      isActive: item.isActive,
    });
    setModalOpen(true);
  };

  const handleSave = async () => {
    if (!form.bankName.trim() || !form.accountHolderName.trim() || !form.accountNumber.trim() || !form.iban.trim()) {
      showToast('يرجى تعبئة الحقول المطلوبة', 'error');
      return;
    }
    try {
      if (editItem) {
        await update.mutateAsync({ id: editItem.id, payload: form });
        showToast('تم تحديث الحساب البنكي', 'success');
      } else {
        await create.mutateAsync(form);
        showToast('تم إضافة الحساب البنكي', 'success');
      }
      setModalOpen(false);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const handleActivate = async () => {
    if (activateId == null) return;
    try {
      await activate.mutateAsync(activateId);
      showToast('تم تفعيل الحساب (سيتم تعطيل الحسابات الأخرى)', 'success');
      setActivateId(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  return (
    <div>
      <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
        <Link to={ROUTES.WALLET_SETTINGS} className="hover:text-bareq-600">إعدادات المحفظة</Link>
        <span>/</span>
        <span>حسابات التحويل البنكي</span>
      </div>

      <PageHeader
        title="حسابات التحويل البنكي"
        subtitle="حساب واحد نشط للعملاء في كل مرة"
        actions={
          <Button type="button" onClick={openCreate}>
            <Plus className="w-4 h-4 ml-1" />
            إضافة حساب
          </Button>
        }
      />

      <DataTable<BankAccountDTO>
        isLoading={isLoading}
        data={accounts}
        emptyMessage="لا توجد حسابات بنكية"
        columns={[
          { key: 'bankName', header: 'البنك' },
          { key: 'accountHolderName', header: 'صاحب الحساب' },
          { key: 'accountNumber', header: 'رقم الحساب' },
          { key: 'iban', header: 'IBAN' },
          {
            key: 'isActive',
            header: 'الحالة',
            render: (a) =>
              a.isActive ? (
                <span className="text-xs font-medium text-green-700 bg-green-100 px-2 py-0.5 rounded-full">نشط</span>
              ) : (
                <span className="text-xs text-gray-500">غير نشط</span>
              ),
          },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (a) => (
              <div className="flex gap-2 justify-end">
                <button type="button" onClick={() => openEdit(a)} className="p-1.5 text-gray-600 hover:text-bareq-600" title="تعديل">
                  <Pencil className="w-4 h-4" />
                </button>
                {!a.isActive && (
                  <button
                    type="button"
                    onClick={() => setActivateId(a.id)}
                    className="p-1.5 text-green-600 hover:bg-green-50 rounded"
                    title="تفعيل"
                  >
                    <CheckCircle className="w-4 h-4" />
                  </button>
                )}
                {a.isActive && (
                  <button
                    type="button"
                    onClick={() => deactivate.mutate(a.id)}
                    className="p-1.5 text-red-600 hover:bg-red-50 rounded"
                    title="تعطيل"
                  >
                    <XCircle className="w-4 h-4" />
                  </button>
                )}
              </div>
            ),
          },
        ]}
      />

      <FormModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editItem ? 'تعديل حساب بنكي' : 'إضافة حساب بنكي'}
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>إلغاء</Button>
            <Button type="button" disabled={create.isPending || update.isPending} onClick={() => void handleSave()}>
              حفظ
            </Button>
          </>
        }
      >
        <div className="space-y-3 text-right">
          {(['bankName', 'accountHolderName', 'accountNumber', 'iban', 'branchName'] as const).map((field) => (
            <div key={field}>
              <label className="text-xs text-gray-500 block mb-1">
                {field === 'bankName' && 'اسم البنك *'}
                {field === 'accountHolderName' && 'صاحب الحساب *'}
                {field === 'accountNumber' && 'رقم الحساب *'}
                {field === 'iban' && 'IBAN *'}
                {field === 'branchName' && 'الفرع'}
              </label>
              <input
                value={form[field] ?? ''}
                onChange={(e) => setForm((f) => ({ ...f, [field]: e.target.value }))}
                className="w-full border rounded-lg px-3 py-2 text-sm"
              />
            </div>
          ))}
          <div>
            <label className="text-xs text-gray-500 block mb-1">تعليمات للعميل</label>
            <textarea
              value={form.instructions ?? ''}
              onChange={(e) => setForm((f) => ({ ...f, instructions: e.target.value }))}
              className="w-full border rounded-lg px-3 py-2 text-sm min-h-[80px]"
            />
          </div>
        </div>
      </FormModal>

      <ConfirmModal
        isOpen={activateId != null}
        onClose={() => setActivateId(null)}
        onConfirm={handleActivate}
        title="تفعيل الحساب"
        message="تفعيل هذا الحساب سيعطّل الحسابات الأخرى. هل تريد المتابعة؟"
        confirmText="تفعيل"
        variant="info"
        isLoading={activate.isPending}
      />
    </div>
  );
}
