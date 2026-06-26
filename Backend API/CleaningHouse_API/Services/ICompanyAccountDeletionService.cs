namespace CleaningHouse_API.Services;

public enum CompanyAccountDeletionResult
{
    Success,
    UserNotFound,
    NotCompanyUser,
    InvalidPassword,
    ActiveBookingsExist
}

public interface ICompanyAccountDeletionService
{
    Task<CompanyAccountDeletionResult> DeleteCompanyAccountAsync(
        int userId,
        string? password,
        bool requirePassword,
        CancellationToken cancellationToken = default);
}
