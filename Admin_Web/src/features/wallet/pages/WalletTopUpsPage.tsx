import { useSearchParams } from 'react-router-dom';
import { PageHeader } from '../../../shared/components/PageHeader';
import { BankTransferTopUpPanel } from '../components/BankTransferTopUpPanel';
import { BankCardTopUpPanel } from '../components/BankCardTopUpPanel';

type TopUpTab = 'transfer' | 'card';

const TABS: { id: TopUpTab; label: string }[] = [
  { id: 'transfer', label: 'تحويل بنكي' },
  { id: 'card', label: 'بطاقة بنكية' },
];

export default function WalletTopUpsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const tabParam = searchParams.get('tab');
  const activeTab: TopUpTab = tabParam === 'card' ? 'card' : 'transfer';

  const setTab = (tab: TopUpTab) => {
    setSearchParams(tab === 'transfer' ? {} : { tab }, { replace: true });
  };

  return (
    <div>
      <PageHeader
        title="طلبات شحن المحفظة"
        subtitle="مراجعة التحويلات البنكية وتأكيد شحن البطاقة عند الحاجة"
      />

      <div className="flex gap-2 mb-6 border-b border-gray-200">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setTab(tab.id)}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors ${
              activeTab === tab.id
                ? 'border-bareq-600 text-bareq-700'
                : 'border-transparent text-gray-600 hover:text-gray-900'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'transfer' ? <BankTransferTopUpPanel /> : <BankCardTopUpPanel />}
    </div>
  );
}
