using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Models;
using MarsDcNocMVC.Data;
using System;
using System.Linq;
using System.Threading.Tasks;
using ClosedXML.Excel;
using System.IO;
using iTextSharp.text;
using iTextSharp.text.pdf;
using System.Collections.Generic;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;


namespace MarsDcNocMVC.Controllers
{
    public class BackupController : Controller
    {
        private readonly ApplicationDbContext _context;

        public BackupController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: Backup
        public async Task<IActionResult> Index(DateTime? startDate, DateTime? endDate, string searchString)
        {
            var query = _context.BackupLogs.AsQueryable();

            query = query.Where(x => x.FolderName != "TRACKER_SUMMARY");

            var userLocationName = await _context.Users
                .Where(u => u.Username == User.Identity.Name)
                .Select(u => u.LocationName)
                .FirstOrDefaultAsync();

            if (!User.IsInRole("Admin") && !string.IsNullOrEmpty(userLocationName))
            {
                query = query.Where(x => x.LocationName == userLocationName);
            }

            if (startDate.HasValue)
            {
                query = query.Where(x => x.Timestamp >= startDate.Value);
            }

            if (endDate.HasValue)
            {
                query = query.Where(x => x.Timestamp <= endDate.Value.AddDays(1).AddSeconds(-1));
            }

            if (!string.IsNullOrEmpty(searchString))
            {
                query = query.Where(x => x.FolderName.Contains(searchString) || 
                                        x.Action.Contains(searchString) || 
                                        x.LocationName.Contains(searchString));
            }

            var allLogs = await query.ToListAsync();

            var latestLogs = allLogs
                .GroupBy(x => x.FolderName)
                .Select(g => g.OrderByDescending(x => x.Timestamp).First())
                .OrderByDescending(x => x.Timestamp)
                .ToList();

            ViewBag.StartDate = startDate?.ToString("yyyy-MM-dd");
            ViewBag.EndDate = endDate?.ToString("yyyy-MM-dd");
            ViewBag.SearchString = searchString;

            return View(latestLogs);
        }

        // GET: Backup/DcpOnlineFolders
        public async Task<IActionResult> DcpOnlineFolders(DateTime? startDate, DateTime? endDate, string searchString)
        {
            var query = _context.DcpOnlineFolderTracking.AsQueryable();

            var userLocationName = await _context.Users
                .Where(u => u.Username == User.Identity.Name)
                .Select(u => u.LocationName)
                .FirstOrDefaultAsync();

            if (!User.IsInRole("Admin") && !string.IsNullOrEmpty(userLocationName))
            {
                query = query.Where(x => x.LocationName == userLocationName);
            }

            if (startDate.HasValue)
            {
                query = query.Where(x => x.FirstSeenDate >= startDate.Value);
            }

            if (endDate.HasValue)
            {
                query = query.Where(x => x.LastCheckDate <= endDate.Value.AddDays(1).AddSeconds(-1));
            }

            if (!string.IsNullOrEmpty(searchString))
            {
                query = query.Where(x => x.FolderName.Contains(searchString) || 
                                        x.Status.Contains(searchString) || 
                                        x.LocationName.Contains(searchString));
            }

            var folders = await query
                .OrderByDescending(x => x.LastCheckDate)
                .Select(f => new DTOs.DcpOnlineFolderTrackingDto
                {
                    ID = f.ID,
                    FolderName = f.FolderName,
                    FirstSeenDate = f.FirstSeenDate,
                    LastCheckDate = f.LastCheckDate,
                    LastProcessedDate = f.LastProcessedDate,
                    ProcessCount = f.ProcessCount,
                    FileSize = f.FileSize.HasValue ? (long)f.FileSize.Value : null,
                    Status = f.Status ?? "Unknown",
                    IsProcessed = f.IsProcessed,
                    LocationName = f.LocationName ?? "Unknown"
                })
                .ToListAsync();

            ViewBag.StartDate = startDate?.ToString("yyyy-MM-dd");
            ViewBag.EndDate = endDate?.ToString("yyyy-MM-dd");
            ViewBag.SearchString = searchString;

            return View(folders);
        }

        // GET: Backup/DcpOnlineFolderDetails/{id}
        public async Task<IActionResult> DcpOnlineFolderDetails(int id)
        {
            var folder = await _context.DcpOnlineFolderTracking
                .FirstOrDefaultAsync(x => x.ID == id);

            if (folder == null)
            {
                return NotFound();
            }

            ViewBag.Folder = folder;
            return View(new List<BackupLog>());
        }

        // GET: Backup/ExportDcpOnlineFolders
        public async Task<IActionResult> ExportDcpOnlineFolders()
        {
            var folders = await _context.DcpOnlineFolderTracking
                .OrderByDescending(x => x.LastCheckDate)
                .ToListAsync();

            using (var workbook = new XLWorkbook())
            {
                var worksheet = workbook.Worksheets.Add("DCP Online Aktarımları");
                
                worksheet.Cell(1, 1).Value = "Klasör Adı";
                worksheet.Cell(1, 2).Value = "İlk Görülme Tarihi";
                worksheet.Cell(1, 3).Value = "Son Kontrol Tarihi";
                worksheet.Cell(1, 4).Value = "Dosya Boyutu (B)";
                worksheet.Cell(1, 5).Value = "Durum";
                worksheet.Cell(1, 6).Value = "İşlendi";

                // Verileri ekle
                for (int i = 0; i < folders.Count; i++)
                {
                    worksheet.Cell(i + 2, 1).Value = folders[i].FolderName;
                    worksheet.Cell(i + 2, 2).Value = folders[i].FirstSeenDate;
                    worksheet.Cell(i + 2, 3).Value = folders[i].LastCheckDate;
                    worksheet.Cell(i + 2, 4).Value = folders[i].FileSize?.ToString() ?? "-";
                    worksheet.Cell(i + 2, 5).Value = folders[i].Status ?? "-";
                    worksheet.Cell(i + 2, 6).Value = folders[i].IsProcessed.ToString();
                }

                var range = worksheet.Range(1, 1, folders.Count + 1, 6);
                range.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                range.Style.Border.InsideBorder = XLBorderStyleValues.Thin;
                worksheet.Columns().AdjustToContents();

                using (var stream = new MemoryStream())
                {
                    workbook.SaveAs(stream);
                    var content = stream.ToArray();
                    return File(content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
                        $"DcpOnlineFolders_{DateTime.Now:yyyyMMdd}.xlsx");
                }
            }
        }

        // GET: Backup/ExportPdf
        public async Task<IActionResult> ExportPdf(DateTime? startDate, DateTime? endDate)
        {
            var query = _context.BackupLogs.AsQueryable();

            query = query.Where(x => x.FolderName != "TRACKER_SUMMARY");

            if (startDate.HasValue)
            {
                query = query.Where(x => x.Timestamp >= startDate.Value);
            }

            if (endDate.HasValue)
            {
                query = query.Where(x => x.Timestamp <= endDate.Value.AddDays(1).AddSeconds(-1));
            }

            var logs = await query
                .OrderByDescending(x => x.Timestamp)
                .ToListAsync();

            using (MemoryStream ms = new MemoryStream())
            {
                Document document = new Document(PageSize.A4, 10f, 10f, 10f, 10f);
                PdfWriter writer = PdfWriter.GetInstance(document, ms);
                document.Open();

                var titleFont = FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 16);
                var title = new Paragraph("Backup Logları", titleFont);
                title.Alignment = Element.ALIGN_CENTER;
                title.SpacingAfter = 20f;
                document.Add(title);

                if (startDate.HasValue || endDate.HasValue)
                {
                    var dateRange = new Paragraph($"Tarih Aralığı: {startDate?.ToString("dd.MM.yyyy")} - {endDate?.ToString("dd.MM.yyyy")}");
                    dateRange.SpacingAfter = 10f;
                    document.Add(dateRange);
                }

                // Tablo
                PdfPTable table = new PdfPTable(8);
                table.WidthPercentage = 100;

                string[] headers = { "Klasör Adı", "İşlem", "Tarih", "Durum", "Süre", "Dosya Boyutu", "İndirme Hızı", "İlerleme" };
                foreach (string header in headers)
                {
                    table.AddCell(new PdfPCell(new Phrase(header)) { BackgroundColor = BaseColor.LightGray });
                }

                // Veriler
                foreach (var log in logs)
                {
                    table.AddCell(log.FolderName);
                    table.AddCell(log.Action);
                    table.AddCell(log.Timestamp.ToString("dd.MM.yyyy HH:mm:ss"));
                    table.AddCell(log.Status == 1 ? "Başarılı" : "Başarısız");
                    table.AddCell(log.Duration ?? "-");
                    table.AddCell(log.FileSize ?? "-");
                    table.AddCell(log.AverageSpeed ?? "-");
                    table.AddCell(log.TotalFileSize ?? "-");
                }

                document.Add(table);
                document.Close();

                return File(ms.ToArray(), "application/pdf", $"BackupLogs_{DateTime.Now:yyyyMMdd}.pdf");
            }
        }

        // GET: Backup/Statistics
        public IActionResult Statistics()
        {
            var dailyStats = _context.BackupLogs
                .Where(x => x.FolderName != "TRACKER_SUMMARY")
                .GroupBy(x => x.Timestamp.Date)
                .Select(g => new
                {
                    Date = g.Key,
                    Count = g.Count(),
                    SuccessCount = g.Count(x => x.Status == 1)
                })
                .OrderBy(x => x.Date)
                .ToList();

            var hourlyStats = _context.BackupLogs
                .Where(x => x.FolderName != "TRACKER_SUMMARY")
                .GroupBy(x => new { x.Timestamp.Date, x.Timestamp.Hour })
                .Select(g => new
                {
                    Date = g.Key.Date,
                    Hour = g.Key.Hour,
                    Count = g.Count()
                })
                .OrderBy(x => x.Date)
                .ThenBy(x => x.Hour)
                .ToList();

            var logs = _context.BackupLogs
                .Where(x => x.FolderName != "TRACKER_SUMMARY")
                .ToList();

            var speedData = logs
                .Where(x => !string.IsNullOrEmpty(x.DownloadSpeed))
                .Select(x => new { x = x.Timestamp.Ticks, y = double.Parse(x.DownloadSpeed ?? "0") })
                .Where(x => x.y > 0)
                .ToList();

            ViewBag.DailyStatsDates = dailyStats.Select(x => x.Date.ToString("dd.MM.yyyy")).ToList();
            ViewBag.DailyStatsCounts = dailyStats.Select(x => x.Count).ToList();
            ViewBag.DailyStatsSuccessCounts = dailyStats.Select(x => x.SuccessCount).ToList();

            ViewBag.HourlyStatsLabels = hourlyStats.Select(x => $"{x.Date.ToString("dd.MM")} {x.Hour}:00").ToList();
            ViewBag.HourlyStatsCounts = hourlyStats.Select(x => x.Count).ToList();

            ViewBag.SpeedData = speedData;

            ViewBag.TotalFolders = _context.DcpOnlineFolderTracking.Count();
            ViewBag.SuccessRate = _context.BackupLogs.Any(x => x.FolderName != "TRACKER_SUMMARY")
                ? (double)_context.BackupLogs.Count(x => x.Status == 1 && x.FolderName != "TRACKER_SUMMARY") / _context.BackupLogs.Count(x => x.FolderName != "TRACKER_SUMMARY")
                : 0;

            // Ortalama hız hesaplama
            var downloadSpeeds = logs
                .Where(x => !string.IsNullOrEmpty(x.DownloadSpeed))
                .Select(x => double.Parse(x.DownloadSpeed ?? "0"))
                .ToList();
            ViewBag.AverageSpeed = downloadSpeeds.Any() ? downloadSpeeds.Average() : 0;

            // Toplam veri hesaplama
            var fileSizes = logs
                .Where(x => !string.IsNullOrEmpty(x.FileSize))
                .Select(x => double.Parse(x.FileSize ?? "0"))
                .ToList();
            ViewBag.TotalDataTransferred = fileSizes.Any() ? fileSizes.Sum() : 0;

            ViewBag.RecentLogs = logs
                .OrderByDescending(x => x.Timestamp)
                .Take(10)
                .ToList();

            return View();
        }

        // GET: Backup/ActiveDownloads
        public async Task<IActionResult> ActiveDownloads()
        {
            var allLogs = await _context.BackupLogs
                .Where(x => x.FolderName != "TRACKER_SUMMARY")
                .ToListAsync();

            // Her dosya için en son durumu kontrol et
            var activeDownloads = allLogs
                .GroupBy(x => x.FolderName)
                .Select(g => g.OrderByDescending(x => x.Timestamp).First())
                .Where(x => x.Status == 0 && x.Action.Contains("Indirme Basladi"))
                .OrderByDescending(x => x.Timestamp)
                .ToList();

            return View(activeDownloads);
        }

        // GET: Backup/ErrorLogs
        public async Task<IActionResult> ErrorLogs()
        {
            var errorLogs = await _context.BackupLogs
                .Where(x => x.Status == 0 && x.FolderName != "TRACKER_SUMMARY")
                .OrderByDescending(x => x.Timestamp)
                .Take(100)
                .ToListAsync();

            return View(errorLogs);
        }

        // GET: Backup/ExportExcel
        public async Task<IActionResult> ExportExcel(DateTime? startDate, DateTime? endDate)
        {
            var query = _context.BackupLogs.AsQueryable();

            query = query.Where(x => x.FolderName != "TRACKER_SUMMARY");

            if (startDate.HasValue)
            {
                query = query.Where(x => x.Timestamp >= startDate.Value);
            }

            if (endDate.HasValue)
            {
                query = query.Where(x => x.Timestamp <= endDate.Value.AddDays(1).AddSeconds(-1));
            }

            var logs = await query
                .OrderByDescending(x => x.Timestamp)
                .ToListAsync();

            using (var workbook = new XLWorkbook())
            {
                var worksheet = workbook.Worksheets.Add("Backup Logları");
                
                worksheet.Cell(1, 1).Value = "Klasör Adı";
                worksheet.Cell(1, 2).Value = "İşlem";
                worksheet.Cell(1, 3).Value = "Tarih";
                worksheet.Cell(1, 4).Value = "Durum";
                worksheet.Cell(1, 5).Value = "Süre";
                worksheet.Cell(1, 6).Value = "Dosya Boyutu";
                worksheet.Cell(1, 7).Value = "Lokasyon";

                // Verileri ekle
                for (int i = 0; i < logs.Count; i++)
                {
                    worksheet.Cell(i + 2, 1).Value = logs[i].FolderName;
                    worksheet.Cell(i + 2, 2).Value = logs[i].Action;
                    worksheet.Cell(i + 2, 3).Value = logs[i].Timestamp.ToString("dd.MM.yyyy HH:mm:ss");
                    worksheet.Cell(i + 2, 4).Value = logs[i].Status == 1 ? "Başarılı" : "Başarısız";
                    worksheet.Cell(i + 2, 5).Value = logs[i].Duration;
                    worksheet.Cell(i + 2, 6).Value = logs[i].FileSize;
                    worksheet.Cell(i + 2, 7).Value = logs[i].LocationName;
                }

                var range = worksheet.Range(1, 1, logs.Count + 1, 7);
                range.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                range.Style.Border.InsideBorder = XLBorderStyleValues.Thin;
                worksheet.Columns().AdjustToContents();

                using (var stream = new MemoryStream())
                {
                    workbook.SaveAs(stream);
                    var content = stream.ToArray();
                    return File(content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
                        $"BackupLogs_{DateTime.Now:yyyyMMdd}.xlsx");
                }
            }
        }

        // GET: Backup/ExportDcpOnlineFoldersPdf
        public async Task<IActionResult> ExportDcpOnlineFoldersPdf()
        {
            var folders = await _context.DcpOnlineFolderTracking
                .OrderByDescending(x => x.LastCheckDate)
                .ToListAsync();

            using (MemoryStream ms = new MemoryStream())
            {
                Document document = new Document(PageSize.A4, 10f, 10f, 10f, 10f);
                PdfWriter writer = PdfWriter.GetInstance(document, ms);
                document.Open();

                var titleFont = FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 16);
                var title = new Paragraph("DCP Online Aktarımları", titleFont);
                title.Alignment = Element.ALIGN_CENTER;
                title.SpacingAfter = 20f;
                document.Add(title);

                // Tablo
                PdfPTable table = new PdfPTable(7);
                table.WidthPercentage = 100;

                string[] headers = { "Klasör Adı", "İlk Görülme Tarihi", "Son Kontrol Tarihi", "Dosya Boyutu", "Durum", "İşlendi", "Lokasyon" };
                foreach (string header in headers)
                {
                    table.AddCell(new PdfPCell(new Phrase(header)) { BackgroundColor = BaseColor.LightGray });
                }

                // Veriler
                foreach (var folder in folders)
                {
                    table.AddCell(folder.FolderName);
                    table.AddCell(folder.FirstSeenDate.ToString("dd.MM.yyyy HH:mm"));
                    table.AddCell(folder.LastCheckDate.ToString("dd.MM.yyyy HH:mm"));
                    table.AddCell(folder.FileSize?.ToString() ?? "N/A");
                    table.AddCell(folder.Status ?? "-");
                    table.AddCell(folder.IsProcessed ? "Evet" : "Hayır");
                    table.AddCell(folder.LocationName ?? "-");
                }

                document.Add(table);
                document.Close();

                return File(ms.ToArray(), "application/pdf", $"DcpOnlineFolders_{DateTime.Now:yyyyMMdd}.pdf");
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetBackupLogData(DateTime? startDate, DateTime? endDate, string searchString)
        {
            try
            {
                var query = _context.BackupLogs.AsQueryable();

                query = query.Where(x => x.FolderName != "TRACKER_SUMMARY");

                var userLocationName = await _context.Users
                    .Where(u => u.Username == User.Identity.Name)
                    .Select(u => u.LocationName)
                    .FirstOrDefaultAsync();

                if (!User.IsInRole("Admin") && !string.IsNullOrEmpty(userLocationName))
                {
                    query = query.Where(x => x.LocationName == userLocationName);
                }

                if (startDate.HasValue)
                {
                    query = query.Where(x => x.Timestamp >= startDate.Value);
                }

                if (endDate.HasValue)
                {
                    query = query.Where(x => x.Timestamp <= endDate.Value.AddDays(1).AddSeconds(-1));
                }

                if (!string.IsNullOrEmpty(searchString))
                {
                    query = query.Where(x => x.FolderName.Contains(searchString) || 
                                            x.Action.Contains(searchString) || 
                                            x.LocationName.Contains(searchString));
                }

                var allLogs = await query.ToListAsync();

                var latestLogs = allLogs
                    .GroupBy(x => x.FolderName)
                    .Select(g => g.OrderByDescending(x => x.Timestamp).First())
                    .OrderByDescending(x => x.Timestamp)
                    .Select(x => new
                    {
                        folderName = x.FolderName,
                        action = x.Action,
                        timestamp = x.Timestamp,
                        status = x.Status,
                        duration = x.Duration,
                        fileSize = x.FileSize,
                        locationName = x.LocationName
                    })
                    .ToList();

                return Json(latestLogs);
            }
            catch (Exception ex)
            {
                return Json(new { error = "Backup log verileri yüklenirken bir hata oluştu: " + ex.Message });
            }
        }
    }
} 