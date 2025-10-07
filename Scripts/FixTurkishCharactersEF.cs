using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;

namespace MarsDcNocMVC.Scripts
{
    public class FixTurkishCharactersEF
    {
        public static async Task FixCharacters(ApplicationDbContext context)
        {
            try
            {
                Console.WriteLine("Türkçe karakter düzeltme işlemi başlıyor...");

                // Mevcut Mars lokasyonlarındaki bozuk verileri bul
                var brokenLogs = await context.BackupLogs
                    .Where(x => x.LocationName.Contains("Mars") && 
                               (x.Action.Contains("ba_Ylad") || 
                                x.Action.Contains("tamamland") ||
                                x.Action.Contains("yǬkleme") ||
                                x.LocationName.Contains("��")))
                    .ToListAsync();

                Console.WriteLine($"Düzeltilecek {brokenLogs.Count} kayıt bulundu.");

                // Action sütunundaki bozuk karakterleri düzelt
                foreach (var log in brokenLogs)
                {
                    if (log.Action.Contains("ba_Ylad") || log.Action.Contains("başlad"))
                    {
                        if (log.Action.Contains("Yedek"))
                            log.Action = "Yedekleme başladı";
                        else if (log.Action.Contains("yǬkleme") || log.Action.Contains("Geri"))
                            log.Action = "Geri yükleme başladı";
                    }
                    else if (log.Action.Contains("tamamland"))
                    {
                        if (log.Action.Contains("Yedek"))
                            log.Action = "Yedekleme tamamlandı";
                        else if (log.Action.Contains("yǬkleme") || log.Action.Contains("Geri"))
                            log.Action = "Geri yükleme tamamlandı";
                    }

                    // LocationName sütunundaki bozuk karakterleri düzelt
                    if (log.LocationName.Contains("��stanbul"))
                        log.LocationName = "Mars İstanbul";
                    else if (log.LocationName.Contains("��zmir"))
                        log.LocationName = "Mars İzmir";
                }

                await context.SaveChangesAsync();
                Console.WriteLine("Türkçe karakterler başarıyla düzeltildi!");

                // Kontrol için düzeltilmiş verileri göster
                var distinctActions = await context.BackupLogs
                    .Where(x => x.LocationName.Contains("Mars"))
                    .Select(x => x.Action)
                    .Distinct()
                    .ToListAsync();

                var distinctLocations = await context.BackupLogs
                    .Where(x => x.LocationName.Contains("Mars"))
                    .Select(x => x.LocationName)
                    .Distinct()
                    .ToListAsync();

                Console.WriteLine("\nDüzeltilmiş Action değerleri:");
                foreach (var action in distinctActions)
                {
                    Console.WriteLine($"- {action}");
                }

                Console.WriteLine("\nDüzeltilmiş LocationName değerleri:");
                foreach (var location in distinctLocations)
                {
                    Console.WriteLine($"- {location}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Hata: {ex.Message}");
            }
        }
    }
}

