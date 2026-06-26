using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddExternalLoginsAndSocialAuth : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_AppUsers_Phone",
                table: "AppUsers");

            migrationBuilder.AlterColumn<string>(
                name: "Phone",
                table: "AppUsers",
                type: "nvarchar(450)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AlterColumn<string>(
                name: "PasswordHash",
                table: "AppUsers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.CreateTable(
                name: "ExternalLogins",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AppUserId = table.Column<int>(type: "int", nullable: false),
                    Provider = table.Column<int>(type: "int", nullable: false),
                    ProviderUserId = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExternalLogins", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExternalLogins_AppUsers_AppUserId",
                        column: x => x.AppUserId,
                        principalTable: "AppUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AppUsers_Phone",
                table: "AppUsers",
                column: "Phone",
                unique: true,
                filter: "[Phone] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_ExternalLogins_AppUserId",
                table: "ExternalLogins",
                column: "AppUserId");

            migrationBuilder.CreateIndex(
                name: "IX_ExternalLogins_Provider_ProviderUserId",
                table: "ExternalLogins",
                columns: new[] { "Provider", "ProviderUserId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExternalLogins");

            migrationBuilder.DropIndex(
                name: "IX_AppUsers_Phone",
                table: "AppUsers");

            migrationBuilder.AlterColumn<string>(
                name: "Phone",
                table: "AppUsers",
                type: "nvarchar(450)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(450)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "PasswordHash",
                table: "AppUsers",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_AppUsers_Phone",
                table: "AppUsers",
                column: "Phone",
                unique: true);
        }
    }
}
