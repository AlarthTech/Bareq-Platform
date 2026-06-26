using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingRejectionReason : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "RejectionReason",
                table: "Bookings",
                type: "nvarchar(2000)",
                maxLength: 2000,
                nullable: true);

            // Legacy status codes: 2 = completed, 3 = canceled. New: 3 = completed, 4 = canceled.
            migrationBuilder.Sql(
                """
                UPDATE Bookings SET Status = 4 WHERE Status = 3;
                UPDATE Bookings SET Status = 3 WHERE Status = 2;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RejectionReason",
                table: "Bookings");
        }
    }
}
