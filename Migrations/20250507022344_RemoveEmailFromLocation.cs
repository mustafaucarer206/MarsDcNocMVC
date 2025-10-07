using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarsDcNocMVC.Migrations
{
    /// <inheritdoc />
    public partial class RemoveEmailFromLocation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Email",
                table: "Locations");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "Locations",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
