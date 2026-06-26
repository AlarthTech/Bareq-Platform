using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class UpdateWalletTopUpBankCardAndTransfer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ReferenceNumber",
                table: "WalletTopUpRequests",
                newName: "TransferReferenceNumber");

            migrationBuilder.RenameColumn(
                name: "Amount",
                table: "WalletTopUpRequests",
                newName: "RequestedAmount");

            migrationBuilder.AddColumn<int>(
                name: "CreatedByAdminId",
                table: "WalletTransactions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AdminNotes",
                table: "WalletTopUpRequests",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ApprovedAmount",
                table: "WalletTopUpRequests",
                type: "decimal(18,2)",
                precision: 18,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "GatewayPaymentReference",
                table: "WalletTopUpRequests",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TransferReceiptImageUrl",
                table: "WalletTopUpRequests",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "BankTransferAccounts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BankName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    AccountHolderName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    AccountNumber = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Iban = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    BranchName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Instructions = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BankTransferAccounts", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WalletTransactions_CreatedByAdminId",
                table: "WalletTransactions",
                column: "CreatedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_WalletTransactions_ReferenceNumber",
                table: "WalletTransactions",
                column: "ReferenceNumber",
                unique: true,
                filter: "[ReferenceNumber] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_WalletTopUpRequests_GatewayPaymentReference",
                table: "WalletTopUpRequests",
                column: "GatewayPaymentReference",
                unique: true,
                filter: "[GatewayPaymentReference] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_BankTransferAccounts_IsActive",
                table: "BankTransferAccounts",
                column: "IsActive");

            migrationBuilder.AddForeignKey(
                name: "FK_WalletTransactions_AppUsers_CreatedByAdminId",
                table: "WalletTransactions",
                column: "CreatedByAdminId",
                principalTable: "AppUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_WalletTransactions_AppUsers_CreatedByAdminId",
                table: "WalletTransactions");

            migrationBuilder.DropTable(
                name: "BankTransferAccounts");

            migrationBuilder.DropIndex(
                name: "IX_WalletTransactions_CreatedByAdminId",
                table: "WalletTransactions");

            migrationBuilder.DropIndex(
                name: "IX_WalletTransactions_ReferenceNumber",
                table: "WalletTransactions");

            migrationBuilder.DropIndex(
                name: "IX_WalletTopUpRequests_GatewayPaymentReference",
                table: "WalletTopUpRequests");

            migrationBuilder.DropColumn(
                name: "CreatedByAdminId",
                table: "WalletTransactions");

            migrationBuilder.DropColumn(
                name: "AdminNotes",
                table: "WalletTopUpRequests");

            migrationBuilder.DropColumn(
                name: "ApprovedAmount",
                table: "WalletTopUpRequests");

            migrationBuilder.DropColumn(
                name: "GatewayPaymentReference",
                table: "WalletTopUpRequests");

            migrationBuilder.DropColumn(
                name: "TransferReceiptImageUrl",
                table: "WalletTopUpRequests");

            migrationBuilder.RenameColumn(
                name: "TransferReferenceNumber",
                table: "WalletTopUpRequests",
                newName: "ReferenceNumber");

            migrationBuilder.RenameColumn(
                name: "RequestedAmount",
                table: "WalletTopUpRequests",
                newName: "Amount");
        }
    }
}
