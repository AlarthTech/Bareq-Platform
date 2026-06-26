using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class RemoveServiceIdFromReviews : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_CleaningServices_ServiceId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_ServiceId",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "ServiceId",
                table: "Reviews");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ServiceId",
                table: "Reviews",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_ServiceId",
                table: "Reviews",
                column: "ServiceId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_CleaningServices_ServiceId",
                table: "Reviews",
                column: "ServiceId",
                principalTable: "CleaningServices",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
