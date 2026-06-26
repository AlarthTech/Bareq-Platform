using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingReports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "BookingReports",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BookingId = table.Column<int>(type: "int", nullable: false),
                    CustomerId = table.Column<int>(type: "int", nullable: false),
                    CompanyId = table.Column<int>(type: "int", nullable: false),
                    WorkerId = table.Column<int>(type: "int", nullable: true),
                    Reason = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    AdminResolutionNotes = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ResolvedByAdminId = table.Column<int>(type: "int", nullable: true),
                    ResolvedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BookingReports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BookingReports_AppUsers_CustomerId",
                        column: x => x.CustomerId,
                        principalTable: "AppUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BookingReports_AppUsers_ResolvedByAdminId",
                        column: x => x.ResolvedByAdminId,
                        principalTable: "AppUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_BookingReports_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BookingReports_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BookingReports_Workers_WorkerId",
                        column: x => x.WorkerId,
                        principalTable: "Workers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_BookingId",
                table: "BookingReports",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_BookingId_CustomerId",
                table: "BookingReports",
                columns: new[] { "BookingId", "CustomerId" },
                unique: true,
                filter: "[Status] IN (0, 1)");

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_CompanyId",
                table: "BookingReports",
                column: "CompanyId");

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_CreatedAt",
                table: "BookingReports",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_CustomerId",
                table: "BookingReports",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_ResolvedByAdminId",
                table: "BookingReports",
                column: "ResolvedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_Status",
                table: "BookingReports",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_Status_CreatedAt",
                table: "BookingReports",
                columns: new[] { "Status", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_BookingReports_WorkerId",
                table: "BookingReports",
                column: "WorkerId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BookingReports");
        }
    }
}
