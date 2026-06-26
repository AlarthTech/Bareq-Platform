using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkerHomeBookingIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Bookings_Status_BookingDate_WorkerId",
                table: "Bookings",
                columns: new[] { "Status", "BookingDate", "WorkerId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Bookings_Status_BookingDate_WorkerId",
                table: "Bookings");
        }
    }
}
