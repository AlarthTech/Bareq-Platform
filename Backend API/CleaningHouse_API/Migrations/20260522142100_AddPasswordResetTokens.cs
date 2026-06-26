using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddPasswordResetTokens : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PasswordResetTokens",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    CodeHash = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    ResetTokenHash = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    CodeExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ResetTokenExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    VerifiedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UsedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    FailedAttempts = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    UserAgent = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PasswordResetTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PasswordResetTokens_AppUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AppUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PasswordResetTokens_Email_CreatedAt",
                table: "PasswordResetTokens",
                columns: new[] { "Email", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_PasswordResetTokens_UserId_UsedAt_CreatedAt",
                table: "PasswordResetTokens",
                columns: new[] { "UserId", "UsedAt", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PasswordResetTokens");
        }
    }
}
