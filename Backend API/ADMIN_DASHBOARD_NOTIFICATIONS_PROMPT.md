# Admin Dashboard — Notifications Bell & Panel (Copy-Paste Prompt)

Copy everything below the line into Cursor / your **Bareq Admin Dashboard** web front-end agent.

---

## PROMPT START

Implement the **In-App Notification System** in the **Bareq Admin Dashboard** top navigation bar.

**API Base URL:** `http://102.203.200.55:5545`  
**SignalR Hub:** `http://102.203.200.55:5545/hubs/notifications`  
**Backend reference:** `NOTIFICATIONS_IMPLEMENTATION.md`

Admin receives notifications for: new company pending approval, new worker pending approval, worker health certificate expired, customer reports (company/worker).

---

## 1. Top navigation — notification bell

Add a **bell icon** in the top-right navbar (next to user menu / logout).

### Unread badge

- On mount: `GET /api/Notifications/GetUnreadCount` → show red badge with count (hide if 0; show `99+` if > 99).
- Update badge when SignalR receives `ReceiveNotification`.

### Dropdown panel

Click bell → open dropdown (not full page):

- Header: **"الإشعارات"** + **"تعليم الكل كمقروء"** link (calls `PATCH /api/Notifications/MarkAllAsRead`).
- Scrollable list with **infinite scroll** or **Load more** pagination (`page`, `pageSize=20`).
- Group items into sections by date (use `createdAt` UTC, convert to local):
  - **Today** — same calendar day
  - **Yesterday**
  - **Earlier**
- Each row:
  - Title (Arabic if UI locale is `ar`, else English — use `titleAr`/`title` fields)
  - Message preview (truncate ~2 lines)
  - Relative time (e.g. "منذ 5 دقائق")
  - Unread dot / bold styling if `isRead === false`
- Click row:
  1. If unread → `PATCH /api/Notifications/MarkAsRead/{id}`
  2. Navigate to related entity (see routing table below)
  3. Close dropdown

Empty state: **"لا توجد إشعارات"**

---

## 2. REST API

All requests: `Authorization: Bearer {adminToken}`

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/Notifications/GetMyNotifications?page=1&pageSize=20` | Paginated list |
| GET | `/api/Notifications/GetUnreadCount` | Badge count |
| PATCH | `/api/Notifications/MarkAsRead/{id}` | Mark one read |
| PATCH | `/api/Notifications/MarkAllAsRead` | Mark all read |
| DELETE | `/api/Notifications/DeleteNotification/{id}` | Optional dismiss |

### Response shape

```typescript
interface NotificationDTO {
  id: number;
  userId: number;
  title: string;
  titleAr: string;
  message: string;
  messageAr: string;
  notificationType: number;
  notificationTypeName: string;
  relatedEntityId: number | null;
  isRead: boolean;
  createdAt: string; // ISO UTC
}

interface PagedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
}
```

---

## 3. SignalR real-time

Use `@microsoft/signalr`:

```typescript
import * as signalR from "@microsoft/signalr";

const connection = new signalR.HubConnectionBuilder()
  .withUrl(`${API_BASE}/hubs/notifications?access_token=${token}`, {
    withCredentials: true, // required when CORS AllowCredentials
  })
  .withAutomaticReconnect()
  .build();

connection.on("ReceiveNotification", (notification: NotificationDTO, unreadCount: number) => {
  // 1. Update badge to unreadCount
  // 2. Prepend notification to dropdown list (if panel open or cache)
  // 3. Optional: toast/snackbar for new notification
});

await connection.start();
```

- Connect after admin login; disconnect on logout.
- Reconnect with fresh token on token refresh.
- Fallback: if SignalR fails, poll `GetUnreadCount` every 60s and refresh list when dropdown opens.

---

## 4. Navigation on click

| notificationTypeName | Navigate to |
|---------------------|-------------|
| NewCompanyPendingApproval | `/companies/{relatedEntityId}` |
| NewWorkerPendingApproval | `/workers/{relatedEntityId}` |
| WorkerHealthCertificateExpired | `/workers/{relatedEntityId}` |
| CompanyReportedByCustomer | `/reports/{relatedEntityId}` |
| WorkerReportedByCustomer | `/reports/{relatedEntityId}` |
| BookingCreated, BookingConfirmed, BookingAssigned, BookingInProgress, BookingCompleted, BookingCancelled, BookingRejected | `/bookings/{relatedEntityId}` |

If `relatedEntityId` is null, only mark as read — no navigation.

---

## 5. Suggested React structure

```
src/
  features/
    notifications/
      api/notificationsApi.ts       // axios calls
      hooks/useNotifications.ts     // TanStack Query + SignalR
      hooks/useNotificationHub.ts   // SignalR connection lifecycle
      components/NotificationBell.tsx
      components/NotificationDropdown.tsx
      components/NotificationItem.tsx
      utils/groupByDate.ts
      utils/getNotificationRoute.ts
```

Use **TanStack Query** for `GetMyNotifications` (infinite query) and `GetUnreadCount`.

---

## 6. UI / UX requirements

- RTL support for Arabic admin UI
- Bell accessible (aria-label: "Notifications")
- Dropdown closes on outside click / Escape
- Loading skeleton while fetching first page
- Error state with retry button
- Do not block login if notification fetch fails

---

## 7. Acceptance checklist

- [ ] Bell shows correct unread count on dashboard load
- [ ] New company registration → admin sees notification without refresh (SignalR)
- [ ] New worker pending → notification appears
- [ ] Customer report → notification with report id; click opens report detail
- [ ] Mark as read updates styling and decrements badge
- [ ] Mark all as read clears badge
- [ ] Pagination / infinite scroll loads older notifications
- [ ] Sections: Today / Yesterday / Earlier
- [ ] Arabic and English text based on locale

## PROMPT END
