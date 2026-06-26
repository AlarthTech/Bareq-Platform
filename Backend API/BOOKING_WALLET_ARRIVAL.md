# Booking wallet reserve/capture and worker arrival confirmation

## Booking statuses (unchanged)

| Value | Name |
|------:|------|
| 0 | Pending |
| 1 | Approved |
| 2 | OnTheWay |
| 3 | Completed |
| 4 | Canceled |
| 5 | Rejected |

Arrival is **not** a status. Use `IsWorkerArrivalConfirmed` / `WorkerArrivalConfirmedAt` on the booking.

## New booking fields

- `IsWorkerArrivalConfirmed`, `WorkerArrivalConfirmedAt`
- `WalletAmountReserved`, `WalletAmountCaptured`, `WalletCapturedAt`
- Wallet: `ReservedBalance` (hold; reduces spendable `Balance`)

## Wallet payment on create

`POST /api/Bookings/CreateBooking` with `paymentMethod: "Wallet"`:

1. Validates pricing and wallet balance (available = `Balance`).
2. Reserves total + fee into `ReservedBalance` (ledger type `WalletReserve`).
3. Payment row stays `Pending`; booking stays `Pending`.
4. Does **not** capture until arrival confirm or completion.

## Confirm arrival

`PATCH /api/Bookings/{id}/ConfirmArrival` — **Customer**, booking owner only.

- Status must be **OnTheWay** (2).
- `IsWorkerArrivalConfirmed` must be false.
- Wallet: `WalletAmountReserved` true and `WalletAmountCaptured` false → capture (`WalletCapture`).

## Status transitions and wallet

| New status | Wallet effect |
|------------|----------------|
| **Completed** | Auto-capture if reserved and not captured |
| **Canceled** / **Rejected** | Release reservation if not captured; refund if already captured |

Capture always checks `WalletAmountCaptured == false` to prevent double deduction.

## Notifications (Arabic)

- Worker arrival: تم تأكيد وصول العاملة إلى موقع الخدمة.
- Capture: تم خصم قيمة الحجز من المحفظة.
- Release: تم إرجاع المبلغ المحجوز إلى المحفظة.
- Refund: تم استرداد قيمة الحجز إلى المحفظة.

## Database migration

Apply `20260604180000_AddBookingWalletArrivalAndReservation` on `CleaningHouseDB`.

```bash
dotnet ef database update --project CleaningHouse_API/CleaningHouse_API.csproj
```

## API responses

`BookingDTO` includes all arrival and wallet flag fields listed above.

`GET /api/v1/wallet` summary includes `reservedBalance` and `availableBalance` (= spendable balance).
