using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;

namespace MarsDcNocMVC.Scripts
{
    public class AddSampleBackupData
    {
        private readonly ApplicationDbContext _context;

        public AddSampleBackupData(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task AddSampleDataAsync()
        {
            Console.WriteLine("Backup ve DCP Online Folders için örnek veri ekleme işlemi başlıyor...");

            // Mevcut lokasyonları al
            var locations = await _context.Locations
                .Where(l => l.Name.StartsWith("Mars"))
                .Take(8) // İlk 8 lokasyonu al
                .ToListAsync();

            if (!locations.Any())
            {
                Console.WriteLine("Hiç Mars lokasyonu bulunamadı! Önce lokasyonları ekleyin.");
                return;
            }

            Console.WriteLine($"Bulunan lokasyonlar: {string.Join(", ", locations.Select(l => l.Name))}");

            // BackupLogs verilerini ekle
            await AddBackupLogsAsync(locations);

            // DcpOnlineFolderTracking verilerini ekle
            await AddDcpOnlineFolderTrackingAsync(locations);

            Console.WriteLine("Örnek veriler başarıyla eklendi!");
            Console.WriteLine("Backup sayfası: http://localhost:5032/Backup");
            Console.WriteLine("DCP Online Folders sayfası: http://localhost:5032/Backup/DcpOnlineFolders");
        }

        private async Task AddBackupLogsAsync(List<Location> locations)
        {
            Console.WriteLine("BackupLogs verilerini ekleniyor...");

            var backupLogs = new List<BackupLog>();
            var random = new Random();

            foreach (var location in locations)
            {
                var locationShortName = location.Name.Replace("Mars ", "").ToUpper();
                
                // Her lokasyon için 2-4 backup log'u ekle
                var logCount = random.Next(2, 5);
                
                for (int i = 1; i <= logCount; i++)
                {
                    var folderName = $"{locationShortName}_BACKUP_{i:D3}";
                    var baseTime = DateTime.Now.AddHours(-random.Next(1, 48));
                    var isSuccess = random.Next(0, 10) > 1; // %90 başarı oranı
                    var fileSize = Math.Round(random.NextDouble() * 4 + 0.5, 1); // 0.5-4.5 GB
                    var speed = Math.Round(random.NextDouble() * 15 + 5, 1); // 5-20 MB/s
                    var downloadSpeed = Math.Round(speed + random.NextDouble() * 5, 1);
                    var duration = TimeSpan.FromMinutes(random.Next(5, 30));

                    // Başlangıç log'u
                    backupLogs.Add(new BackupLog
                    {
                        FolderName = folderName,
                        Action = random.Next(0, 2) == 0 ? "Yedekleme başladı" : "Geri yükleme başladı",
                        Timestamp = baseTime,
                        Status = 1, // Başlangıç her zaman başarılı
                        Duration = duration.ToString(@"hh\:mm\:ss"),
                        FileSize = $"{fileSize} GB",
                        LocationName = location.Name,
                        AverageSpeed = $"{speed} MB/s",
                        DownloadSpeed = $"{downloadSpeed} MB/s",
                        TotalFileSize = $"{fileSize} GB"
                    });

                    // Bitiş log'u (sadece başarılı olanlar için)
                    if (isSuccess)
                    {
                        backupLogs.Add(new BackupLog
                        {
                            FolderName = folderName,
                            Action = backupLogs.Last().Action.Replace("başladı", "tamamlandı"),
                            Timestamp = baseTime.Add(duration),
                            Status = 1,
                            Duration = duration.ToString(@"hh\:mm\:ss"),
                            FileSize = $"{fileSize} GB",
                            LocationName = location.Name,
                            AverageSpeed = $"{speed} MB/s",
                            DownloadSpeed = $"{downloadSpeed} MB/s",
                            TotalFileSize = $"{fileSize} GB"
                        });
                    }
                }
            }

            // Mevcut verileri kontrol et ve sadece yeni olanları ekle
            foreach (var log in backupLogs)
            {
                var exists = await _context.BackupLogs
                    .AnyAsync(bl => bl.FolderName == log.FolderName && 
                                   bl.Action == log.Action && 
                                   bl.LocationName == log.LocationName);
                
                if (!exists)
                {
                    _context.BackupLogs.Add(log);
                }
            }

            await _context.SaveChangesAsync();
            Console.WriteLine($"BackupLogs: {backupLogs.Count} kayıt eklendi.");
        }

        private async Task AddDcpOnlineFolderTrackingAsync(List<Location> locations)
        {
            Console.WriteLine("DcpOnlineFolderTracking verilerini ekleniyor...");

            var folderTrackings = new List<DcpOnlineFolderTracking>();
            var random = new Random();

            foreach (var location in locations)
            {
                var locationShortName = location.Name.Replace("Mars ", "").ToUpper();
                
                // Her lokasyon için 2-5 klasör ekle
                var folderCount = random.Next(2, 6);
                
                for (int i = 1; i <= folderCount; i++)
                {
                    var folderName = $"{locationShortName}_DCP_FOLDER_{i:D3}";
                    var isProcessed = random.Next(0, 10) > 3; // %70 işlenmiş oranı
                    var firstSeenDate = DateTime.Now.AddDays(-random.Next(1, 10));
                    var lastCheckDate = DateTime.Now.AddMinutes(-random.Next(10, 120));
                    var fileSize = (long)(random.NextDouble() * 4294967296 + 536870912); // 0.5-4.5 GB in bytes
                    var processCount = isProcessed ? random.Next(1, 7) : 0;

                    folderTrackings.Add(new DcpOnlineFolderTracking
                    {
                        FolderName = folderName,
                        FirstSeenDate = firstSeenDate,
                        LastCheckDate = lastCheckDate,
                        LastProcessedDate = isProcessed ? lastCheckDate.AddMinutes(-random.Next(1, 60)) : null,
                        ProcessCount = processCount,
                        FileSize = fileSize,
                        Status = isProcessed ? "Processed" : "New",
                        IsProcessed = isProcessed,
                        LocationName = location.Name
                    });
                }
            }

            // Mevcut verileri kontrol et ve sadece yeni olanları ekle
            foreach (var folder in folderTrackings)
            {
                var exists = await _context.DcpOnlineFolderTracking
                    .AnyAsync(dcp => dcp.FolderName == folder.FolderName && 
                                    dcp.LocationName == folder.LocationName);
                
                if (!exists)
                {
                    _context.DcpOnlineFolderTracking.Add(folder);
                }
            }

            await _context.SaveChangesAsync();
            Console.WriteLine($"DcpOnlineFolderTracking: {folderTrackings.Count} kayıt eklendi.");
        }

        public async Task ShowSummaryAsync()
        {
            Console.WriteLine("\n=== VERİ ÖZETİ ===");
            
            var backupCount = await _context.BackupLogs
                .Where(bl => bl.LocationName.StartsWith("Mars"))
                .CountAsync();
            
            var dcpCount = await _context.DcpOnlineFolderTracking
                .Where(dcp => dcp.LocationName.StartsWith("Mars"))
                .CountAsync();
            
            var backupLocations = await _context.BackupLogs
                .Where(bl => bl.LocationName.StartsWith("Mars"))
                .Select(bl => bl.LocationName)
                .Distinct()
                .CountAsync();
            
            var dcpLocations = await _context.DcpOnlineFolderTracking
                .Where(dcp => dcp.LocationName.StartsWith("Mars"))
                .Select(dcp => dcp.LocationName)
                .Distinct()
                .CountAsync();

            Console.WriteLine($"BackupLogs: {backupCount} kayıt, {backupLocations} lokasyon");
            Console.WriteLine($"DcpOnlineFolderTracking: {dcpCount} kayıt, {dcpLocations} lokasyon");
            Console.WriteLine("=================\n");
        }
    }
}

/*
Kullanım örneği Program.cs'de:

using MarsDcNocMVC.Data;
using MarsDcNocMVC.Scripts;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Services
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// Örnek veri ekleme (sadece development ortamında)
if (app.Environment.IsDevelopment())
{
    using (var scope = app.Services.CreateScope())
    {
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var dataAdder = new AddSampleBackupData(context);
        
        await dataAdder.AddSampleDataAsync();
        await dataAdder.ShowSummaryAsync();
    }
}

app.Run();
*/

