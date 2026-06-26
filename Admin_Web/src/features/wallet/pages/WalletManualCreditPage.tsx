import { useMemo, useState } from 'react';
import { PageHeader } from '../../../shared/components/PageHeader';
import { Button } from '../../../shared/ui/Button';
import { useToast } from '../../../shared/context/ToastContext';
import { getErrorMessage } from '../../../core/utils/getErrorMessage';
import { useWalletCreditActions } from '../hooks/useWalletTopUps';
import type { WalletCreditResponse } from '../types';
import { CustomerSelect, useCustomers } from '../components/CustomerSelect';
import type { AppUser } from '../../../types/api.types';

function creditSummary(result: WalletCreditResponse): string {
  const ids = result.creditedCustomerIds ?? [];
  return ids.length > 0 ? `تم شحن ${ids.length} محفظة (معرفات: ${ids.join('، ')})` : 'تمت العملية';
}

export default function WalletManualCreditPage() {
  const { showToast } = useToast();
  const { credit, bulkCredit } = useWalletCreditActions();
  const customers = useCustomers();

  const [customer, setCustomer] = useState<AppUser | null>(null);
  const [amount, setAmount] = useState('');
  const [notes, setNotes] = useState('');

  const [customerSearch, setCustomerSearch] = useState('');
  const [bulkSelected, setBulkSelected] = useState<Set<number>>(new Set());
  const [bulkAmount, setBulkAmount] = useState('');
  const [bulkNotes, setBulkNotes] = useState('');

  const filteredCustomers = useMemo(() => {
    const q = customerSearch.trim().toLowerCase();
    if (!q) return customers.slice(0, 20);
    return customers
      .filter(
        (c) =>
          c.phone.includes(q) ||
          c.fullName.toLowerCase().includes(q) ||
          c.email.toLowerCase().includes(q) ||
          String(c.id).includes(q)
      )
      .slice(0, 20);
  }, [customers, customerSearch]);

  const toggleBulkCustomer = (id: number) => {
    setBulkSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleSingleCredit = async (e: React.FormEvent) => {
    e.preventDefault();
    const amt = Number.parseFloat(amount);
    if (!customer || Number.isNaN(amt) || amt <= 0) {
      showToast('اختر العميل وأدخل مبلغاً صالحاً', 'error');
      return;
    }
    try {
      const result = await credit.mutateAsync({
        customerId: customer.id,
        amount: amt,
        notes: notes.trim() || undefined,
      });
      showToast(creditSummary(result), 'success');
      setCustomer(null);
      setAmount('');
      setNotes('');
    } catch (err) {
      showToast(getErrorMessage(err), 'error');
    }
  };

  const handleBulkCredit = async (e: React.FormEvent) => {
    e.preventDefault();
    const customerIds = [...bulkSelected];
    const amt = Number.parseFloat(bulkAmount);
    if (customerIds.length === 0 || Number.isNaN(amt) || amt <= 0) {
      showToast('اختر عملاء وأدخل مبلغاً صالحاً', 'error');
      return;
    }
    try {
      const result = await bulkCredit.mutateAsync({
        customerIds,
        amount: amt,
        notes: bulkNotes.trim() || undefined,
      });
      showToast(creditSummary(result), 'success');
      setBulkSelected(new Set());
      setBulkAmount('');
      setBulkNotes('');
      setCustomerSearch('');
    } catch (err) {
      showToast(getErrorMessage(err), 'error');
    }
  };

  return (
    <div className="max-w-2xl space-y-8">
      <PageHeader
        title="شحن محفظة يدوي"
        subtitle="إضافة رصيد لعميل أو مجموعة عملاء"
      />

      <form onSubmit={handleSingleCredit} className="bg-white rounded-xl border p-6 space-y-4">
        <h3 className="font-semibold">شحن عميل واحد</h3>
        <div>
          <label className="text-xs text-gray-500 block mb-1">العميل</label>
          <CustomerSelect value={customer} onChange={setCustomer} />
        </div>
        <input
          type="number"
          min={0.01}
          step={0.01}
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="المبلغ (د.ل)"
          className="w-full border rounded-lg px-3 py-2"
        />
        <input
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="ملاحظات (اختياري)"
          className="w-full border rounded-lg px-3 py-2"
        />
        <Button type="submit" disabled={credit.isPending}>
          {credit.isPending ? 'جاري الشحن...' : 'إضافة الرصيد'}
        </Button>
      </form>

      <form onSubmit={handleBulkCredit} className="bg-white rounded-xl border p-6 space-y-4">
        <h3 className="font-semibold">شحن جماعي</h3>
        <div>
          <label className="text-xs text-gray-500 block mb-1">اختر العملاء</label>
          <input
            value={customerSearch}
            onChange={(e) => setCustomerSearch(e.target.value)}
            placeholder="بحث بالاسم أو الهاتف أو المعرف"
            className="w-full border rounded-lg px-3 py-2 mb-2"
          />
          <div className="max-h-40 overflow-y-auto border rounded-lg divide-y">
            {filteredCustomers.length === 0 ? (
              <p className="p-3 text-sm text-gray-500">لا يوجد عملاء</p>
            ) : (
              filteredCustomers.map((c) => (
                <label
                  key={c.id}
                  className="flex items-center gap-3 px-3 py-2 hover:bg-gray-50 cursor-pointer text-sm"
                >
                  <input
                    type="checkbox"
                    checked={bulkSelected.has(c.id)}
                    onChange={() => toggleBulkCustomer(c.id)}
                  />
                  <span className="flex-1">{c.fullName}</span>
                  <span className="text-gray-500">#{c.id}</span>
                </label>
              ))
            )}
          </div>
        </div>

        {bulkSelected.size > 0 && (
          <p className="text-xs text-gray-600">{bulkSelected.size} عميل محدد</p>
        )}

        <input
          type="number"
          min={0.01}
          step={0.01}
          value={bulkAmount}
          onChange={(e) => setBulkAmount(e.target.value)}
          placeholder="المبلغ لكل عميل (د.ل)"
          className="w-full border rounded-lg px-3 py-2"
        />
        <input
          value={bulkNotes}
          onChange={(e) => setBulkNotes(e.target.value)}
          placeholder="ملاحظات (اختياري)"
          className="w-full border rounded-lg px-3 py-2"
        />
        <Button type="submit" disabled={bulkCredit.isPending}>
          {bulkCredit.isPending ? 'جاري الشحن...' : `شحن ${bulkSelected.size || ''} محفظة`}
        </Button>
      </form>
    </div>
  );
}
