namespace CleaningHouse_API.Models.Common;

public enum NotificationType
{
    NewCompanyPendingApproval = 1,
    NewWorkerPendingApproval = 2,
    WorkerHealthCertificateExpired = 3,
    CompanyReportedByCustomer = 4,
    WorkerReportedByCustomer = 5,
    BookingCreated = 10,
    BookingAssigned = 11,
    BookingConfirmed = 12,
    BookingInProgress = 13,
    BookingCompleted = 14,
    BookingCancelled = 15,
    BookingRejected = 16,
    WorkerArrivalConfirmed = 17,
    WalletAmountCaptured = 18,
    WalletReservationReleased = 19,
    WalletAmountRefunded = 20,
    BookingReportSubmitted = 21,
    BookingReportStatusUpdated = 22,
    BookingReportSubmittedForCompany = 23
}
