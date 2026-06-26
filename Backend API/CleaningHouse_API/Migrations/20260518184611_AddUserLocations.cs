using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddUserLocations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "UserLocationId",
                table: "Bookings",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "UserLocations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    LocationName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Lat = table.Column<double>(type: "float", nullable: false),
                    Lng = table.Column<double>(type: "float", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserLocations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserLocations_AppUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AppUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_UserLocationId",
                table: "Bookings",
                column: "UserLocationId");

            migrationBuilder.CreateIndex(
                name: "IX_UserLocations_UserId",
                table: "UserLocations",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_UserLocations_UserLocationId",
                table: "Bookings",
                column: "UserLocationId",
                principalTable: "UserLocations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_UserLocations_UserLocationId",
                table: "Bookings");

            migrationBuilder.DropTable(
                name: "UserLocations");

            migrationBuilder.DropIndex(
                name: "IX_Bookings_UserLocationId",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "UserLocationId",
                table: "Bookings");
        }
    }
}
