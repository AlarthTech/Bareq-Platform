import type { WalletTopUpStatus } from '../types';
import { WALLET_TOP_UP_STATUS_COLORS, WALLET_TOP_UP_STATUS_LABELS } from '../types';

export function WalletTopUpStatusBadge({ status }: { status: WalletTopUpStatus }) {
  return (
    <span
      className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${WALLET_TOP_UP_STATUS_COLORS[status]}`}
    >
      {WALLET_TOP_UP_STATUS_LABELS[status]}
    </span>
  );
}
