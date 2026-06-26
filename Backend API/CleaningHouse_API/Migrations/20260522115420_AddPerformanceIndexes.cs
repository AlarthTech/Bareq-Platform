using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddPerformanceIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Workers_CompanyId",
                table: "Workers");

            migrationBuilder.DropIndex(
                name: "IX_UserLocations_UserId",
                table: "UserLocations");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_WorkerId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_CompanyId",
                table: "Bookings");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_UserId",
                table: "Bookings");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_WorkerId",
                table: "Bookings");

            migrationBuilder.CreateIndex(
                name: "IX_Workers_CompanyId_IsAvailable_IsActive",
                table: "Workers",
                columns: new[] { "CompanyId", "IsAvailable", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_UserLocations_UserId_IsActive",
                table: "UserLocations",
                columns: new[] { "UserId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_WorkerId_CreatedAt",
                table: "Reviews",
                columns: new[] { "WorkerId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Companies_IsActive_IsVerified_CityId",
                table: "Companies",
                columns: new[] { "IsActive", "IsVerified", "CityId" });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_CompanyId_Status_CreatedAt",
                table: "Bookings",
                columns: new[] { "CompanyId", "Status", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_UserId_Status_CreatedAt",
                table: "Bookings",
                columns: new[] { "UserId", "Status", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_WorkerId_Status",
                table: "Bookings",
                columns: new[] { "WorkerId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Workers_CompanyId_IsAvailable_IsActive",
                table: "Workers");

            migrationBuilder.DropIndex(
                name: "IX_UserLocations_UserId_IsActive",
                table: "UserLocations");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_WorkerId_CreatedAt",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Companies_IsActive_IsVerified_CityId",
                table: "Companies");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_CompanyId_Status_CreatedAt",
                table: "Bookings");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_UserId_Status_CreatedAt",
                table: "Bookings");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_WorkerId_Status",
                table: "Bookings");

            migrationBuilder.CreateIndex(
                name: "IX_Workers_CompanyId",
                table: "Workers",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_UserLocations_UserId",
                table: "UserLocations",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_WorkerId",
                table: "Reviews",
                column: "WorkerId");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_CompanyId",
                table: "Bookings",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_UserId",
                table: "Bookings",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_WorkerId",
                table: "Bookings",
                column: "WorkerId");
        }
    }
}
