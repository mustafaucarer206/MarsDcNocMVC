using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace MarsDcNocMVC.Migrations
{
    /// <inheritdoc />
    public partial class CreateDatabase : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "BackupLogs",
                columns: new[] { "ID", "Action", "FolderName", "Status", "Timestamp" },
                values: new object[,]
                {
                    { 1, "Yedekleme", "Cevahir", 1, new DateTime(2024, 5, 7, 10, 0, 0, 0, DateTimeKind.Unspecified) },
                    { 2, "Geri Yükleme", "Cevahir", 1, new DateTime(2024, 5, 7, 11, 0, 0, 0, DateTimeKind.Unspecified) },
                    { 3, "Yedekleme", "Hiltown", 0, new DateTime(2024, 5, 7, 9, 0, 0, 0, DateTimeKind.Unspecified) },
                    { 4, "Geri Yükleme", "Hiltown", 1, new DateTime(2024, 5, 7, 8, 0, 0, 0, DateTimeKind.Unspecified) }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 4);
        }
    }
}
