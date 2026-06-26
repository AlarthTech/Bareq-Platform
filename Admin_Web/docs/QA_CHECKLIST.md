# QA Checklist — Bareq Admin Dashboard

Production API: `http://102.203.200.55:5545`

## Platform fee

- [ ] Save platform fee at `/settings/platform-fee` (PUT body `{ "amount": N }`)
- [ ] New bookings show `servicePrice`, `platformFeeAmount`, `totalPrice` from API
- [ ] Legacy bookings (all prices 0) show badge «تسعير قديم — غير متوفر»

## Wallet settings

- [ ] Toggle wallet payment on/off at `/settings/wallet`
- [ ] Save wallet fee percentage (0–100%)
- [ ] Preview reflects fee on sample booking total

## Wallet top-ups (`/wallet/top-ups`)

- [ ] **تحويل بنكي** tab: list pending transfers, approve with custom `approvedAmount`, reject with reason
- [ ] Badge on sidebar = count of Pending + BankTransfer
- [ ] **بطاقة بنكية** tab: confirm / fail pending card top-ups (or wait for gateway callback)
- [ ] Do not credit bank transfer before approve API succeeds

## Manual wallet credit (`/wallet/manual-credit`)

- [ ] Single credit via `POST /api/v1/admin/wallet/wallets/{customerId}/credit`
- [ ] Bulk credit via `POST /api/v1/admin/wallet/wallets/bulk-credit`

## Bookings

- [ ] List column «الإجمالي» shows `totalPrice`
- [ ] Detail: pricing card + monthly badge when `isMonthlyPricing`
- [ ] Wallet badges: «محجوز من المحفظة», «تم الخصم من المحفظة», «تم تأكيد وصول العاملة»
- [ ] Admin cancel/reject wallet booking → backend refunds or releases hold (toast shown)

## Notifications

- [ ] Bell in top bar shows unread count
- [ ] SignalR hub connects with JWT at `/hubs/notifications`
- [ ] Mark read / mark all read works
- [ ] Live events: company pending, worker pending, health cert expired, reports

## Reports (`/reports`)

- [ ] List with pagination
- [ ] Detail view
- [ ] PATCH status workflow
- [ ] Delete report

## Reviews

- [ ] List shows booking id, worker, customer, rating, comment (no service fields)
