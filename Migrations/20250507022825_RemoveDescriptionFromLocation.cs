using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarsDcNocMVC.Migrations
{
    /// <inheritdoc />
    public partial class RemoveDescriptionFromLocation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Description",
                table: "Locations");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Locations",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
