using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarsDcNocMVC.Models;
using MarsDcNocMVC.DTOs;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using System.Security.Claims;
using MarsDcNocMVC.Services;

namespace MarsDcNocMVC.Controllers;

[Authorize]
public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly ApplicationDbContext _context;
    private readonly IDiskCapacityService _diskCapacityService;

    public HomeController(ILogger<HomeController> logger, ApplicationDbContext context, IDiskCapacityService diskCapacityService)
    {
        _logger = logger;
        _context = context;
        _diskCapacityService = diskCapacityService;
    }

    public async Task<IActionResult> Index()
    {
        if (User.Identity.IsAuthenticated)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Login", "Account");
            }
            var user = await _context.Users.FindAsync(int.Parse(userId));

            if (user != null)
            {
                // Son 24 saatteki aktarımları hesapla
                var last24Hours = DateTime.Now.AddHours(-24);
                
                // 1. BackupLogs tablosundan son 24 saatteki kayıtları al
                IQueryable<BackupLog> logsQuery = _context.BackupLogs.Where(b => b.Timestamp >= last24Hours);

                // Admin değilse sadece kendi lokasyonunun loglarını al
                if (user.Role != "Admin")
                {
                    logsQuery = logsQuery.Where(b => b.LocationName == user.LocationName);
                }

                var recentLogs = await logsQuery.ToListAsync();
                
                // Her klasör için en son durumu al ve status=1 olanları say
                var latestLogs = recentLogs
                    .GroupBy(b => b.FolderName)
                    .Select(g => g.OrderByDescending(x => x.Timestamp).First())
                    .ToList();
                
                var backupLogsSuccessCount = latestLogs.Count(b => b.Status == 1);

                // 2. DcpOnlineFolderTracking tablosundan başarılı aktarım durumundaki kayıtları al (DTO kullanarak veri tipi sorununu çöz)
                // Son 24 saatteki başarılı aktarımlar için tarih kontrolü ekle
                var successfulStatusList = new[] { "MovedToWatchFolder", "Taşındı" };
                var last24HoursMovedQuery = _context.DcpOnlineFolderTracking
                    .Where(f => successfulStatusList.Contains(f.Status) && f.LastCheckDate >= last24Hours);
                
                if (user.Role != "Admin")
                {
                    last24HoursMovedQuery = last24HoursMovedQuery.Where(f => f.LocationName == user.LocationName);
                }

                // DTO projection kullanarak sadece gerekli alanları seç ve veri tipi sorununu çöz
                var allLast24HoursMovedFolders = await last24HoursMovedQuery
                    .Select(f => new DcpOnlineFolderTrackingDto
                    {
                        ID = f.ID,
                        FolderName = f.FolderName,
                        FirstSeenDate = f.FirstSeenDate,
                        LastCheckDate = f.LastCheckDate,
                        LastProcessedDate = f.LastProcessedDate,
                        ProcessCount = f.ProcessCount,
                        FileSize = f.FileSize.HasValue ? (long)f.FileSize.Value : 0, // double'dan long'a güvenli cast
                        Status = f.Status,
                        IsProcessed = f.IsProcessed,
                        LocationName = f.LocationName
                    })
                    .ToListAsync();
                
                // Her klasör için en son başarılı kaydını al (son 24 saat içinde)
                var last24HoursMovedFolders = allLast24HoursMovedFolders
                    .GroupBy(f => f.FolderName)
                    .Select(g => g.OrderByDescending(x => x.LastCheckDate).First())
                    .ToList();

                // Son 24 saatte gerçekleştirilen aktarım sayısı = BackupLogs(status=1) + DcpOnlineFolderTracking(son 24 saatteki başarılı durumlar)
                var last24HoursTransferCount = backupLogsSuccessCount + last24HoursMovedFolders.Count;

                // Toplam gerçekleştirilen aktarımları hesapla
                // 1. DcpOnlineFolderTracking tablosunda status="New" olanları sorgula (tüm zamanlar için) - DTO ile
                var newFoldersQuery = _context.DcpOnlineFolderTracking.Where(f => f.Status == "New");
                if (user.Role != "Admin")
                {
                    newFoldersQuery = newFoldersQuery.Where(f => f.LocationName == user.LocationName);
                }

                var allNewFolders = await newFoldersQuery
                    .Select(f => new DcpOnlineFolderTrackingDto
                    {
                        ID = f.ID,
                        FolderName = f.FolderName,
                        FirstSeenDate = f.FirstSeenDate,
                        LastCheckDate = f.LastCheckDate,
                        LastProcessedDate = f.LastProcessedDate,
                        ProcessCount = f.ProcessCount,
                        FileSize = f.FileSize.HasValue ? (long)f.FileSize.Value : 0,
                        Status = f.Status,
                        IsProcessed = f.IsProcessed,
                        LocationName = f.LocationName
                    })
                    .ToListAsync();
                
                // Her klasör için en son New kaydını al
                var newFolders = allNewFolders
                    .GroupBy(f => f.FolderName)
                    .Select(g => g.OrderByDescending(x => x.LastCheckDate).First())
                    .ToList();

                // 2. BackupLogs tablosunda her klasör için en son durumu kontrol et (tüm zamanlar için)
                IQueryable<BackupLog> allBackupLogsQuery = _context.BackupLogs;
                if (user.Role != "Admin")
                {
                    allBackupLogsQuery = allBackupLogsQuery.Where(b => b.LocationName == user.LocationName);
                }

                var allBackupLogs = await allBackupLogsQuery.ToListAsync();
                
                // Her klasör için en son kaydı bul
                var latestBackupLogs = allBackupLogs
                    .GroupBy(b => b.FolderName)
                    .Select(g => g.OrderByDescending(x => x.Timestamp).First())
                    .ToList();
                
                // En son durumu "indirme başladı" olan klasörleri filtrele
                var downloadStartedFolders = latestBackupLogs
                    .Where(log => log.Action.Contains("indirme başladı") || log.Action.Contains("Indirme Basladi"))
                    .ToList();
                
                var downloadStartedCount = downloadStartedFolders.Count;

                // Toplam gerçekleştirilen aktarım sayısı = DcpOnlineFolderTracking(New) + BackupLogs(son durumu indirme başladı)
                var totalTransferCount = newFolders.Count + downloadStartedCount;

                ViewBag.SuccessTransferCount = last24HoursTransferCount; // Son 24 saatte gerçekleştirilen
                ViewBag.RecentTransferCount = totalTransferCount; // Toplam gerçekleştirilen aktarımlar
                ViewBag.IsAdmin = user.Role == "Admin";

                // Admin olmayan kullanıcılar için disk kapasitesi uyarısı
                if (user.Role != "Admin")
                {
                    var diskCapacity = _diskCapacityService.GetDiskCapacity("D");
                    ViewBag.DiskCapacity = diskCapacity;
                    ViewBag.ShowDiskWarning = diskCapacity.IsLowSpace;
                }
            }
        }

        return View();
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
