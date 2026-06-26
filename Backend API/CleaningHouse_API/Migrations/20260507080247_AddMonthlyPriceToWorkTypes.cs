using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CleaningHouse_API.Migrations
{
    /// <inheritdoc />
    public partial class AddMonthlyPriceToWorkTypes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "MonthlyPrice",
                table: "WorkTypes",
                type: "decimal(18,2)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MonthlyPrice",
                table: "WorkTypes");
        }
    }
}
