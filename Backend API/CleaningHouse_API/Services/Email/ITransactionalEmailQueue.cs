namespace CleaningHouse_API.Services.Email;

public interface ITransactionalEmailQueue
{
    void Enqueue(Func<IEmailSender, Task> sendAction, string purpose, string toEmail);
}
