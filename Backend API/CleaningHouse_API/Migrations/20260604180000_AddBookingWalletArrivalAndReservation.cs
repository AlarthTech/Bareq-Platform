using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations;

public class AddBookingWalletArrivalAndReservation : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<bool>(
            name: "IsWorkerArrivalConfirmed",
            table: "Bookings",
            type: "bit",
            nullable: false,
            defaultValue: false);

        migrationBuilder.AddColumn<DateTime>(
            name: "WorkerArrivalConfirmedAt",
            table: "Bookings",
            type: "datetime2",
            nullable: true);

        migrationBuilder.AddColumn<bool>(
            name: "WalletAmountReserved",
            table: "Bookings",
            type: "bit",
            nullable: false,
            defaultValue: false);

        migrationBuilder.AddColumn<bool>(
            name: "WalletAmountCaptured",
            table: "Bookings",
            type: "bit",
            nullable: false,
            defaultValue: false);

        migrationBuilder.AddColumn<DateTime>(
            name: "WalletCapturedAt",
            table: "Bookings",
            type: "datetime2",
            nullable: true);

        migrationBuilder.AddColumn<decimal>(
            name: "ReservedBalance",
            table: "Wallets",
            type: "decimal(18,2)",
            precision: 18,
            scale: 2,
            nullable: false,
            defaultValue: 0m);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "IsWorkerArrivalConfirmed", table: "Bookings");
        migrationBuilder.DropColumn(name: "WorkerArrivalConfirmedAt", table: "Bookings");
        migrationBuilder.DropColumn(name: "WalletAmountReserved", table: "Bookings");
        migrationBuilder.DropColumn(name: "WalletAmountCaptured", table: "Bookings");
        migrationBuilder.DropColumn(name: "WalletCapturedAt", table: "Bookings");
        migrationBuilder.DropColumn(name: "ReservedBalance", table: "Wallets");
    }
}
