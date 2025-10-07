using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarsDcNocMVC.Migrations
{
    /// <inheritdoc />
    public partial class AddBackupLogAndDcpOnlineFolderTrackingColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Username",
                table: "Users",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "LocationName",
                table: "Users",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Locations",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "Timestamp",
                table: "BackupLogs",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "GETDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<string>(
                name: "FolderName",
                table: "BackupLogs",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Action",
                table: "BackupLogs",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<string>(
                name: "AverageSpeed",
                table: "BackupLogs",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DownloadSpeed",
                table: "BackupLogs",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Duration",
                table: "BackupLogs",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FileSize",
                table: "BackupLogs",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LocationName",
                table: "BackupLogs",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TotalFileSize",
                table: "BackupLogs",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "DcpOnlineFolderTracking",
                columns: table => new
                {
                    ID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FolderName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    FirstSeenDate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()"),
                    LastCheckDate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()"),
                    LastProcessedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ProcessCount = table.Column<int>(type: "int", nullable: false),
                    FileSize = table.Column<long>(type: "bigint", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    IsProcessed = table.Column<bool>(type: "bit", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DcpOnlineFolderTracking", x => x.ID);
                });

            migrationBuilder.UpdateData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 1,
                columns: new[] { "AverageSpeed", "DownloadSpeed", "Duration", "FileSize", "LocationName", "TotalFileSize" },
                values: new object[] { null, null, null, null, null, null });

            migrationBuilder.UpdateData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 2,
                columns: new[] { "AverageSpeed", "DownloadSpeed", "Duration", "FileSize", "LocationName", "TotalFileSize" },
                values: new object[] { null, null, null, null, null, null });

            migrationBuilder.UpdateData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 3,
                columns: new[] { "AverageSpeed", "DownloadSpeed", "Duration", "FileSize", "LocationName", "TotalFileSize" },
                values: new object[] { null, null, null, null, null, null });

            migrationBuilder.UpdateData(
                table: "BackupLogs",
                keyColumn: "ID",
                keyValue: 4,
                columns: new[] { "AverageSpeed", "DownloadSpeed", "Duration", "FileSize", "LocationName", "TotalFileSize" },
                values: new object[] { null, null, null, null, null, null });

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username",
                table: "Users",
                column: "Username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Locations_Name",
                table: "Locations",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DcpOnlineFolderTracking_FolderName",
                table: "DcpOnlineFolderTracking",
                column: "FolderName");

            migrationBuilder.CreateIndex(
                name: "IX_DcpOnlineFolderTracking_LastCheckDate",
                table: "DcpOnlineFolderTracking",
                column: "LastCheckDate");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DcpOnlineFolderTracking");

            migrationBuilder.DropIndex(
                name: "IX_Users_Username",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Locations_Name",
                table: "Locations");

            migrationBuilder.DropColumn(
                name: "AverageSpeed",
                table: "BackupLogs");

            migrationBuilder.DropColumn(
                name: "DownloadSpeed",
                table: "BackupLogs");

            migrationBuilder.DropColumn(
                name: "Duration",
                table: "BackupLogs");

            migrationBuilder.DropColumn(
                name: "FileSize",
                table: "BackupLogs");

            migrationBuilder.DropColumn(
                name: "LocationName",
                table: "BackupLogs");

            migrationBuilder.DropColumn(
                name: "TotalFileSize",
                table: "BackupLogs");

            migrationBuilder.AlterColumn<string>(
                name: "Username",
                table: "Users",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AlterColumn<string>(
                name: "LocationName",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Locations",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "Timestamp",
                table: "BackupLogs",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "GETDATE()");

            migrationBuilder.AlterColumn<string>(
                name: "FolderName",
                table: "BackupLogs",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldMaxLength: 255);

            migrationBuilder.AlterColumn<string>(
                name: "Action",
                table: "BackupLogs",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(255)",
                oldMaxLength: 255);
        }
    }
}
