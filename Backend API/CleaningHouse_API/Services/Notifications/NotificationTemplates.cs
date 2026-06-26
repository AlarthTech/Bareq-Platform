using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Services.Notifications;

public record NotificationPayload(
    string Title,
    string TitleAr,
    string Message,
    string MessageAr,
    NotificationType NotificationType,
    int? RelatedEntityId = null);

public static class NotificationTemplates
{
    public static NotificationPayload NewCompanyPendingApproval(int companyId, string companyName) =>
        new(
            "New Company Waiting Approval",
            "شركة جديدة بانتظار الاعتماد",
            $"A new company \"{companyName}\" has registered and requires approval.",
            $"تم تسجيل شركة جديدة \"{companyName}\" وتحتاج إلى الاعتماد.",
            NotificationType.NewCompanyPendingApproval,
            companyId);

    public static NotificationPayload NewWorkerPendingApproval(int workerId, string workerName, string companyName) =>
        new(
            "New Worker Waiting Approval",
            "عاملة جديدة بانتظار الاعتماد",
            $"A new worker \"{workerName}\" at \"{companyName}\" requires approval.",
            $"تم إ添加افة عاملة جديدة \"{workerName}\" في \"{companyName}\" وتحتاج إلى الاعتماد.",
            NotificationType.NewWorkerPendingApproval,
            workerId);

    public static NotificationPayload WorkerHealthCertificateExpiredAdmin(int workerId, string workerName) =>
        new(
            "Worker Health Certificate Expired",
            "انتهاء الشهادة الصحية لعاملة",
            $"The health certificate for worker \"{workerName}\" has expired and requires review.",
            $"انتهت الشهادة الصحية للعاملة \"{workerName}\" وتحتاج إلى مراجعة.",
            NotificationType.WorkerHealthCertificateExpired,
            workerId);

    public static NotificationPayload WorkerHealthCertificateExpiredOwner(int workerId, string workerName) =>
        new(
            "Worker Health Certificate Expired",
            "انتهاء الشهادة الصحية لعاملة",
            $"The health certificate of worker \"{workerName}\" has expired.",
            $"انتهت الشهادة الصحية للعاملة \"{workerName}\" التابعة لشركتكم.",
            NotificationType.WorkerHealthCertificateExpired,
            workerId);

    public static NotificationPayload CompanyReportedByCustomer(int reportId, string companyName) =>
        new(
            "New Company Report",
            "بلاغ جديد على شركة",
            $"A customer reported company \"{companyName}\". The report requires admin review.",
            $"قام أحد العملاء بتقديم بلاغ على شركة \"{companyName}\" ويحتاج البلاغ إلى مراجعة الإدارة.",
            NotificationType.CompanyReportedByCustomer,
            reportId);

    public static NotificationPayload WorkerReportedByCustomer(int reportId, string workerName) =>
        new(
            "New Worker Report",
            "بلاغ جديد على عاملة",
            $"A customer reported worker \"{workerName}\". The report requires admin review.",
            $"قام أحد العملاء بتقديم بلاغ على عاملة \"{workerName}\" ويحتاج البلاغ إلى مراجعة الإدارة.",
            NotificationType.WorkerReportedByCustomer,
            reportId);

    public static NotificationPayload BookingCreatedForCompany(int bookingId, string customerName, string workerName) =>
        new(
            "New Booking Created",
            "حجز جديد",
            $"New booking #{bookingId} from {customerName}. Worker: {workerName}.",
            $"حجز جديد #{bookingId} من {customerName}. العاملة: {workerName}.",
            NotificationType.BookingCreated,
            bookingId);

    public static NotificationPayload BookingStatusForCustomer(
        int bookingId,
        NotificationType type,
        string titleEn,
        string titleAr,
        string messageEn,
        string messageAr) =>
        new(titleEn, titleAr, messageEn, messageAr, type, bookingId);

    public static NotificationPayload BookingStatusForCompanyOwner(
        int bookingId,
        NotificationType type,
        string customerName,
        string workerName,
        string statusLabelEn,
        string statusLabelAr) =>
        new(
            $"Booking {statusLabelEn}",
            $"حجز — {statusLabelAr}",
            $"Booking #{bookingId} — {statusLabelEn}. Customer: {customerName}. Worker: {workerName}.",
            $"الحجز #{bookingId} — {statusLabelAr}. العميل: {customerName}. العاملة: {workerName}.",
            type,
            bookingId);

    public static (NotificationType Type, string TitleEn, string TitleAr, string MsgEn, string MsgAr) MapBookingStatusForCustomer(int status) =>
        status switch
        {
            BookingStatuses.Approved => (
                NotificationType.BookingConfirmed,
                "Booking Confirmed",
                "تم تأكيد الحجز",
                "Your booking has been confirmed.",
                "تم تأكيد الحجز الخاص بك."),
            BookingStatuses.OnTheWay => (
                NotificationType.BookingInProgress,
                "Worker On The Way",
                "العاملة في الطريق",
                "Your assigned worker is on the way.",
                "العاملة المعينة في طريقها إليك."),
            BookingStatuses.Completed => (
                NotificationType.BookingCompleted,
                "Service Completed",
                "تم إكمال الخدمة",
                "Your service has been completed successfully.",
                "تم إكمال الخدمة بنجاح."),
            BookingStatuses.Canceled => (
                NotificationType.BookingCancelled,
                "Booking Cancelled",
                "تم إلغاء الحجز",
                "Your booking has been cancelled.",
                "تم إلغاء حجزك."),
            BookingStatuses.Rejected => (
                NotificationType.BookingRejected,
                "Booking Rejected",
                "تم رفض الحجز",
                "Your booking has been rejected.",
                "تم رفض حجزك."),
            _ => (
                NotificationType.BookingAssigned,
                "Worker Assigned",
                "تم تعيين العاملة",
                "A worker has been assigned to your booking.",
                "تم تعيين عاملة لحجزك.")
        };

    public static NotificationPayload WorkerArrivalConfirmed(int bookingId) =>
        new(
            "Worker Arrived",
            "تأكيد وصول العاملة",
            $"Worker arrival confirmed for booking #{bookingId}.",
            "تم تأكيد وصول العاملة إلى موقع الخدمة.",
            NotificationType.WorkerArrivalConfirmed,
            bookingId);

    public static NotificationPayload WalletAmountCaptured(int bookingId) =>
        new(
            "Wallet Charged",
            "خصم من المحفظة",
            $"Booking #{bookingId} amount was captured from your wallet.",
            "تم خصم قيمة الحجز من المحفظة.",
            NotificationType.WalletAmountCaptured,
            bookingId);

    public static NotificationPayload WalletReservationReleased(int bookingId) =>
        new(
            "Wallet Hold Released",
            "إرجاع المبلغ المحجوز",
            $"Reserved amount for booking #{bookingId} was released to your wallet.",
            "تم إرجاع المبلغ المحجوز إلى المحفظة.",
            NotificationType.WalletReservationReleased,
            bookingId);

    public static NotificationPayload WalletAmountRefunded(int bookingId) =>
        new(
            "Wallet Refunded",
            "استرداد إلى المحفظة",
            $"Booking #{bookingId} amount was refunded to your wallet.",
            "تم استرداد قيمة الحجز إلى المحفظة.",
            NotificationType.WalletAmountRefunded,
            bookingId);

    public static NotificationPayload BookingReportSubmittedForAdmin(int reportId) =>
        new(
            "New Booking Report",
            "بلاغ جديد على حجز",
            "A new booking report has been submitted.",
            "تم تقديم بلاغ جديد على حجز.",
            NotificationType.BookingReportSubmitted,
            reportId);

    public static NotificationPayload BookingReportStatusUpdatedForCustomer(int reportId) =>
        new(
            "Booking Report Updated",
            "تحديث بلاغ الحجز",
            "Your booking report status has been updated.",
            "تم تحديث حالة البلاغ الخاص بالحجز.",
            NotificationType.BookingReportStatusUpdated,
            reportId);

    public static NotificationPayload BookingReportSubmittedForCompany(int reportId) =>
        new(
            "Booking Report Submitted",
            "بلاغ على حجز",
            "A report was submitted for one of your company bookings.",
            "تم تقديم بلاغ على أحد حجوزات الشركة.",
            NotificationType.BookingReportSubmittedForCompany,
            reportId);

    public static (NotificationType Type, string StatusEn, string StatusAr) MapBookingStatusForCompany(int status) =>
        status switch
        {
            BookingStatuses.Approved => (NotificationType.BookingConfirmed, "Confirmed", "مؤكد"),
            BookingStatuses.OnTheWay => (NotificationType.BookingInProgress, "In Progress", "قيد التنفيذ"),
            BookingStatuses.Completed => (NotificationType.BookingCompleted, "Completed", "مكتمل"),
            BookingStatuses.Canceled => (NotificationType.BookingCancelled, "Cancelled", "ملغي"),
            BookingStatuses.Rejected => (NotificationType.BookingRejected, "Rejected", "مرفوض"),
            BookingStatuses.Pending => (NotificationType.BookingCreated, "Pending", "قيد الانتظار"),
            _ => (NotificationType.BookingAssigned, "Updated", "محدّث")
        };
}
