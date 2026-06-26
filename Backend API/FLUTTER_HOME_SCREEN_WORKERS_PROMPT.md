# Flutter — Home Screen Workers (Backend-Driven)

Use these endpoints only. **Do not** compute worker availability from booking lists on the client.

## Available Workers section

```http
GET /api/v1/workers/available?date=2026-06-01&page=1&pageSize=20
```

- `date` optional — defaults to today (UTC).
- Anonymous; rate-limited (`search` policy).
- Display `availabilityLabel` as returned (e.g. `Available Today`, `Available on Jun 15, 2026`).

## Top Rated Workers section

```http
GET /api/v1/workers/top-rated?page=1&pageSize=20
```

- Sorted server-side: rating DESC → reviewCount DESC → name ASC.
- Use `isAvailableToday`, `nextAvailableDate`, and `availabilityLabel` from the response.

## Response shape (`WorkerCardDto`)

| Field | Available endpoint | Top-rated endpoint |
|-------|-------------------|-------------------|
| `id`, `name`, `companyId`, `companyName`, `profileImageUrl`, `rating`, `reviewCount` | ✓ | ✓ |
| `isAvailable` | `true` | — |
| `availableDate` | selected date | — |
| `isAvailableToday` | — | ✓ |
| `nextAvailableDate` | — | ✓ |
| `availabilityLabel` | ✓ | ✓ |

Pagination: `items`, `page`, `pageSize`, `totalCount`, `totalPages`, `hasNextPage`, `hasPreviousPage`.

## Availability rules (server)

Worker is **busy** on a day if they have a booking with status **Pending**, **Approved**, or **On The Way** whose schedule covers that day.

**Completed**, **Canceled**, and **Rejected** do not block availability.

## UI

- Bind cards directly to API fields.
- Refresh available list when the user changes the selected date.
- Pull-to-refresh / infinite scroll using `page` + `hasNextPage`.
