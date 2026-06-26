using Microsoft.EntityFrameworkCore;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Models.Admin;
using CleaningHouse_API.Models.Wallet;

namespace CleaningHouse_API.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<AppUser> AppUsers { get; set; }
    public DbSet<UserType> UserTypes { get; set; }
    public DbSet<Company> Companies { get; set; }
    public DbSet<Worker> Workers { get; set; }
    public DbSet<CleaningService> CleaningServices { get; set; }
    public DbSet<Booking> Bookings { get; set; }
    public DbSet<Payment> Payments { get; set; }
    public DbSet<Review> Reviews { get; set; }
    public DbSet<WorkType> WorkTypes { get; set; }
    public DbSet<WorkerWorkType> WorkerWorkTypes { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<Language> Languages { get; set; }
    public DbSet<Nationality> Nationalities { get; set; }
    public DbSet<Favorite> Favorites { get; set; }
    public DbSet<UserLocation> UserLocations { get; set; }
    public DbSet<PasswordResetToken> PasswordResetTokens { get; set; }
    public DbSet<ExternalLogin> ExternalLogins { get; set; }
    public DbSet<Report> Reports { get; set; }
    public DbSet<BookingReport> BookingReports { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<CommissionSetting> CommissionSettings { get; set; }
    public DbSet<Wallet> Wallets { get; set; }
    public DbSet<WalletTransaction> WalletTransactions { get; set; }
    public DbSet<WalletTopUpRequest> WalletTopUpRequests { get; set; }
    public DbSet<WalletPaymentSettings> WalletPaymentSettings { get; set; }
    public DbSet<BankTransferAccount> BankTransferAccounts { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure AppUser
        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasIndex(e => e.Phone)
                .IsUnique()
                .HasFilter("[Phone] IS NOT NULL");
        });

        modelBuilder.Entity<ExternalLogin>(entity =>
        {
            entity.HasIndex(e => new { e.Provider, e.ProviderUserId }).IsUnique();
            entity.HasOne(e => e.AppUser)
                .WithMany(u => u.ExternalLogins)
                .HasForeignKey(e => e.AppUserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure Company
        modelBuilder.Entity<Company>(entity =>
        {
            entity.HasOne(c => c.OwnerAppUser)
                  .WithMany(u => u.OwnedCompanies)
                  .HasForeignKey(c => c.OwnerUserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(c => new { c.IsActive, c.IsVerified, c.CityId });
        });

        // Configure Worker
        modelBuilder.Entity<Worker>(entity =>
        {
            entity.HasOne(w => w.Company)
                  .WithMany(c => c.Workers)
                  .HasForeignKey(w => w.CompanyId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(w => new { w.CompanyId, w.IsAvailable, w.IsActive });
        });

        // Configure Booking
        modelBuilder.Entity<Booking>(entity =>
        {
            entity.HasOne(b => b.AppUser)
                  .WithMany(u => u.Bookings)
                  .HasForeignKey(b => b.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(b => b.Company)
                  .WithMany(c => c.Bookings)
                  .HasForeignKey(b => b.CompanyId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(b => b.Worker)
                  .WithMany(w => w.Bookings)
                  .HasForeignKey(b => b.WorkerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(b => b.WorkType)
                  .WithMany()
                  .HasForeignKey(b => b.WorkTypeId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(b => b.UserLocation)
                  .WithMany(l => l.Bookings)
                  .HasForeignKey(b => b.UserLocationId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(b => new { b.CompanyId, b.Status, b.CreatedAt });
            entity.HasIndex(b => new { b.UserId, b.Status, b.CreatedAt });
            entity.HasIndex(b => new { b.WorkerId, b.Status });
            entity.HasIndex(b => new { b.Status, b.BookingDate, b.WorkerId });

            entity.Property(b => b.ServicePrice).HasPrecision(18, 2);
            entity.Property(b => b.PlatformFeeAmount).HasPrecision(18, 2);
            entity.Property(b => b.TotalPrice).HasPrecision(18, 2);
        });

        modelBuilder.Entity<UserLocation>(entity =>
        {
            entity.HasOne(l => l.AppUser)
                  .WithMany(u => u.UserLocations)
                  .HasForeignKey(l => l.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(l => new { l.UserId, l.IsActive });
        });

        // Configure Payment
        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasOne(p => p.Booking)
                  .WithMany(b => b.Payments)
                  .HasForeignKey(p => p.BookingId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.Property(p => p.Amount).HasPrecision(18, 2);
            entity.Property(p => p.WalletFeeAmount).HasPrecision(18, 2);
            entity.Property(p => p.BookingTotalAmount).HasPrecision(18, 2);
        });

        // Configure Review
        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasOne(r => r.Booking)
                  .WithMany(b => b.Reviews)
                  .HasForeignKey(r => r.BookingId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.AppUser)
                  .WithMany(u => u.Reviews)
                  .HasForeignKey(r => r.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Worker)
                  .WithMany(w => w.Reviews)
                  .HasForeignKey(r => r.WorkerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(r => new { r.WorkerId, r.CreatedAt });
        });

        // Configure WorkType
        modelBuilder.Entity<WorkType>(entity =>
        {
            entity.HasOne(wt => wt.Company)
                  .WithMany(c => c.WorkTypes)
                  .HasForeignKey(wt => wt.CompanyId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // Configure WorkerWorkType (Many-to-Many)
        modelBuilder.Entity<WorkerWorkType>(entity =>
        {
            entity.HasOne(wwt => wwt.Worker)
                  .WithMany(w => w.WorkerWorkTypes)
                  .HasForeignKey(wwt => wwt.WorkerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(wwt => wwt.WorkType)
                  .WithMany(wt => wt.WorkerWorkTypes)
                  .HasForeignKey(wwt => wwt.WorkTypeId)
                  .OnDelete(DeleteBehavior.Restrict);

            // Prevent duplicate assignments
            entity.HasIndex(wwt => new { wwt.WorkerId, wwt.WorkTypeId }).IsUnique();
        });

        modelBuilder.Entity<PasswordResetToken>(entity =>
        {
            entity.HasOne(t => t.AppUser)
                  .WithMany()
                  .HasForeignKey(t => t.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(t => new { t.Email, t.CreatedAt });
            entity.HasIndex(t => new { t.UserId, t.UsedAt, t.CreatedAt });
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasOne(n => n.AppUser)
                  .WithMany(u => u.Notifications)
                  .HasForeignKey(n => n.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(n => new { n.UserId, n.IsRead, n.CreatedAt });
            entity.HasIndex(n => new { n.UserId, n.IsDeleted, n.CreatedAt });
            entity.HasIndex(n => new { n.NotificationType, n.RelatedEntityId, n.UserId });
        });

        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasOne(r => r.AppUser)
                  .WithMany(u => u.Reports)
                  .HasForeignKey(r => r.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Worker)
                  .WithMany()
                  .HasForeignKey(r => r.WorkerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Company)
                  .WithMany()
                  .HasForeignKey(r => r.CompanyId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(r => new { r.UserId, r.CreatedAt });
            entity.HasIndex(r => new { r.Status, r.CreatedAt });
            entity.HasIndex(r => new { r.TargetType, r.WorkerId });
            entity.HasIndex(r => new { r.TargetType, r.CompanyId });
        });

        modelBuilder.Entity<BookingReport>(entity =>
        {
            entity.HasOne(r => r.Booking)
                  .WithMany()
                  .HasForeignKey(r => r.BookingId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Customer)
                  .WithMany()
                  .HasForeignKey(r => r.CustomerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Company)
                  .WithMany()
                  .HasForeignKey(r => r.CompanyId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Worker)
                  .WithMany()
                  .HasForeignKey(r => r.WorkerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.ResolvedByAdmin)
                  .WithMany()
                  .HasForeignKey(r => r.ResolvedByAdminId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(r => r.BookingId);
            entity.HasIndex(r => r.CustomerId);
            entity.HasIndex(r => r.CompanyId);
            entity.HasIndex(r => r.WorkerId);
            entity.HasIndex(r => r.Status);
            entity.HasIndex(r => r.CreatedAt);
            entity.HasIndex(r => new { r.Status, r.CreatedAt });

            entity.HasIndex(r => new { r.BookingId, r.CustomerId })
                  .IsUnique()
                  .HasFilter("[Status] IN (0, 1)");
        });

        modelBuilder.Entity<CommissionSetting>(entity =>
        {
            entity.Property(s => s.FixedPlatformFeeAmount).HasPrecision(18, 2);

            entity.HasOne(s => s.UpdatedByAdmin)
                  .WithMany()
                  .HasForeignKey(s => s.UpdatedByAdminId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(s => s.IsActive);
        });

        modelBuilder.Entity<Wallet>(entity =>
        {
            entity.Property(w => w.Balance).HasPrecision(18, 2);
            entity.Property(w => w.ReservedBalance).HasPrecision(18, 2);

            entity.HasOne(w => w.Customer)
                  .WithOne(u => u.Wallet)
                  .HasForeignKey<Wallet>(w => w.CustomerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(w => w.CustomerId).IsUnique();
        });

        modelBuilder.Entity<WalletTransaction>(entity =>
        {
            entity.Property(t => t.Amount).HasPrecision(18, 2);

            entity.HasOne(t => t.CreatedByAdmin)
                  .WithMany()
                  .HasForeignKey(t => t.CreatedByAdminId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(t => t.ReferenceNumber)
                  .IsUnique()
                  .HasFilter("[ReferenceNumber] IS NOT NULL");

            entity.HasOne(t => t.Wallet)
                  .WithMany(w => w.Transactions)
                  .HasForeignKey(t => t.WalletId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(t => t.Customer)
                  .WithMany()
                  .HasForeignKey(t => t.CustomerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(t => t.Booking)
                  .WithMany()
                  .HasForeignKey(t => t.BookingId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(t => new { t.CustomerId, t.CreatedAt });
            entity.HasIndex(t => new { t.BookingId, t.Type })
                  .IsUnique()
                  .HasFilter("[BookingId] IS NOT NULL");
        });

        modelBuilder.Entity<BankTransferAccount>(entity =>
        {
            entity.HasIndex(a => a.IsActive);
        });

        modelBuilder.Entity<WalletTopUpRequest>(entity =>
        {
            entity.Property(r => r.RequestedAmount).HasPrecision(18, 2);
            entity.Property(r => r.ApprovedAmount).HasPrecision(18, 2);

            entity.HasIndex(r => r.GatewayPaymentReference)
                  .IsUnique()
                  .HasFilter("[GatewayPaymentReference] IS NOT NULL");

            entity.HasOne(r => r.Customer)
                  .WithMany()
                  .HasForeignKey(r => r.CustomerId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.Wallet)
                  .WithMany()
                  .HasForeignKey(r => r.WalletId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(r => new { r.Status, r.CreatedAt });
            entity.HasIndex(r => new { r.CustomerId, r.CreatedAt });

            entity.HasOne(r => r.WalletTransaction)
                  .WithMany()
                  .HasForeignKey(r => r.WalletTransactionId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<WalletPaymentSettings>(entity =>
        {
            entity.Property(s => s.WalletPaymentFeePercentage).HasPrecision(5, 2);

            entity.HasOne(s => s.UpdatedByAdmin)
                  .WithMany()
                  .HasForeignKey(s => s.UpdatedByAdminId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // Configure Favorite
        modelBuilder.Entity<Favorite>(entity =>
        {
            entity.HasOne(f => f.AppUser)
                  .WithMany(u => u.Favorites)
                  .HasForeignKey(f => f.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(f => f.Worker)
                  .WithMany(w => w.Favorites)
                  .HasForeignKey(f => f.WorkerId)
                  .OnDelete(DeleteBehavior.Restrict);

            // Prevent duplicate favorites (same user can't favorite same worker twice)
            entity.HasIndex(f => new { f.UserId, f.WorkerId }).IsUnique();
        });
    }
}



