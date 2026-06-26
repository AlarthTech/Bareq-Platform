# Flutter Customer App — Notifications (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

Implement the **In-App Notification System** in the **Bareq Customer** Flutter app using **Clean Architecture** (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**SignalR Hub:** `http://102.203.200.55:5545/hubs/notifications`  
**Backend reference:** `NOTIFICATIONS_IMPLEMENTATION.md`

Customers receive notifications when **booking status changes** (confirmed, worker assigned, on the way, completed, cancelled, rejected).

---

## User flows

### Flow A — Notification icon (home / app bar)

1. App bar shows bell icon with unread badge
2. Tap → **Notifications screen**
3. Badge updates in real time via SignalR

### Flow B — Notifications list

1. Paginated list (pull-to-refresh + scroll to load more)
2. Group: **Today** / **Yesterday** / **Earlier**
3. Tap notification → mark as read → navigate to **Booking detail** (`relatedEntityId`)
4. App bar action: **"تعليم الكل كمقروء"**

### Flow C — Real-time

1. On login → connect SignalR with JWT
2. On `ReceiveNotification` → update badge + prepend to list if screen open
3. Optional local notification / in-app banner when app is foreground

---

## API endpoints (Customer JWT)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/Notifications/GetMyNotifications?page=1&pageSize=20` | List |
| GET | `/api/Notifications/GetUnreadCount` | Badge |
| PATCH | `/api/Notifications/MarkAsRead/{id}` | Mark read |
| PATCH | `/api/Notifications/MarkAllAsRead` | Mark all |
| DELETE | `/api/Notifications/DeleteNotification/{id}` | Optional swipe dismiss |

---

## Clean Architecture structure

```
lib/features/notifications/
├── data/
│   ├── models/notification_model.dart
│   ├── datasources/
│   │   ├── notification_remote_datasource.dart
│   │   └── notification_signalr_datasource.dart
│   └── repositories/notification_repository_impl.dart
├── domain/
│   ├── entities/notification_entity.dart
│   ├── repositories/notification_repository.dart
│   └── usecases/
│       ├── get_notifications.dart
│       ├── get_unread_count.dart
│       ├── mark_notification_read.dart
│       ├── mark_all_notifications_read.dart
│       └── watch_realtime_notifications.dart
└── presentation/
    ├── state/notifications_cubit.dart (or bloc)
    ├── pages/notifications_page.dart
    └── widgets/
        ├── notification_bell_icon.dart
        ├── notification_list_item.dart
        └── notification_date_section.dart
```

---

## Domain entity

```dart
class NotificationEntity {
  final int id;
  final String title;
  final String titleAr;
  final String message;
  final String messageAr;
  final int notificationType;
  final int? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  String localizedTitle(Locale locale) =>
      locale.languageCode == 'ar' ? titleAr : title;

  String localizedMessage(Locale locale) =>
      locale.languageCode == 'ar' ? messageAr : message;
}
```

---

## SignalR (Flutter)

Use `signalr_netcore` or equivalent:

```dart
final hub = HubConnectionBuilder()
  .withUrl(
    '$baseUrl/hubs/notifications?access_token=$token',
    options: HttpConnectionOptions(
      transport: HttpTransportType.WebSockets,
      skipNegotiation: false,
    ),
  )
  .withAutomaticReconnect()
  .build();

hub.on('ReceiveNotification', (args) {
  final notification = NotificationModel.fromJson(args![0]);
  final unreadCount = args[1] as int;
  // emit to cubit
});
```

Connect after login; disconnect on logout.

---

## Booking notification types (customer)

| Type | Title (EN) | Title (AR) |
|------|------------|------------|
| BookingConfirmed | Booking Confirmed | تم تأكيد الحجز |
| BookingAssigned | Worker Assigned | تم تعيين العاملة |
| BookingInProgress | Worker On The Way | العاملة في الطريق |
| BookingCompleted | Service Completed | تم إكمال الخدمة |
| BookingCancelled | Booking Cancelled | تم إلغاء الحجز |
| BookingRejected | Booking Rejected | تم رفض الحجز |

All booking notifications: navigate to `/bookings/{relatedEntityId}`.

---

## UI requirements

- Unread items: bold title + dot indicator
- Pull-to-refresh reloads page 1
- Infinite scroll: increment `page` until `items.length >= totalCount`
- Empty state illustration + **"لا توجد إشعارات"**
- Error state with retry
- RTL layout for Arabic

---

## DI registration

Register in `core/di/injection.dart`:

- `NotificationRemoteDataSource`
- `NotificationSignalRDataSource`
- `NotificationRepositoryImpl`
- All use cases
- `NotificationsCubit`

---

## Acceptance checklist

- [ ] Bell badge shows unread count on home
- [ ] Booking status change → notification without app restart (SignalR)
- [ ] Tap notification opens booking detail
- [ ] Mark as read + mark all as read work
- [ ] Pull to refresh works
- [ ] Arabic/English text follows app locale
- [ ] Offline: notifications load from API on next open

## PROMPT END
