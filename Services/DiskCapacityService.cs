using System.IO;
using MarsDcNocMVC.Models;

namespace MarsDcNocMVC.Services
{
    public interface IDiskCapacityService
    {
        DiskCapacityInfo GetDiskCapacity(string driveLetter = "D");
        bool IsLowDiskSpace(string driveLetter = "D");
    }

    public class DiskCapacityService : IDiskCapacityService
    {
        private const double LowSpacePercentageThreshold = 10.0; // %10
        private const long LowSpaceGBThreshold = 300L * 1024 * 1024 * 1024; // 300GB in bytes

        public DiskCapacityInfo GetDiskCapacity(string driveLetter = "D")
        {
            try
            {
                var driveInfo = new DriveInfo(driveLetter);
                
                if (!driveInfo.IsReady)
                {
                    return new DiskCapacityInfo
                    {
                        DriveLetter = driveLetter,
                        IsReady = false,
                        ErrorMessage = "Disk hazır değil"
                    };
                }

                var totalSizeGB = (double)driveInfo.TotalSize / (1024 * 1024 * 1024);
                var freeSpaceGB = (double)driveInfo.TotalFreeSpace / (1024 * 1024 * 1024);
                var usedSpaceGB = totalSizeGB - freeSpaceGB;
                var usagePercentage = (usedSpaceGB / totalSizeGB) * 100;
                var freeSpacePercentage = (freeSpaceGB / totalSizeGB) * 100;

                return new DiskCapacityInfo
                {
                    DriveLetter = driveLetter,
                    IsReady = true,
                    TotalSizeGB = Math.Round(totalSizeGB, 2),
                    FreeSpaceGB = Math.Round(freeSpaceGB, 2),
                    UsedSpaceGB = Math.Round(usedSpaceGB, 2),
                    UsagePercentage = Math.Round(usagePercentage, 2),
                    FreeSpacePercentage = Math.Round(freeSpacePercentage, 2),
                    IsLowSpace = freeSpaceGB < (LowSpaceGBThreshold / (1024.0 * 1024.0 * 1024.0)) || 
                                freeSpacePercentage < LowSpacePercentageThreshold
                };
            }
            catch (Exception ex)
            {
                return new DiskCapacityInfo
                {
                    DriveLetter = driveLetter,
                    IsReady = false,
                    ErrorMessage = ex.Message
                };
            }
        }

        public bool IsLowDiskSpace(string driveLetter = "D")
        {
            var capacity = GetDiskCapacity(driveLetter);
            return capacity.IsReady && capacity.IsLowSpace;
        }
    }

    public class DiskCapacityInfo
    {
        public string DriveLetter { get; set; } = "";
        public bool IsReady { get; set; }
        public double TotalSizeGB { get; set; }
        public double FreeSpaceGB { get; set; }
        public double UsedSpaceGB { get; set; }
        public double UsagePercentage { get; set; }
        public double FreeSpacePercentage { get; set; }
        public bool IsLowSpace { get; set; }
        public string? ErrorMessage { get; set; }

        public string StatusColor => IsLowSpace ? "danger" : FreeSpacePercentage < 20 ? "warning" : "success";
        public string StatusText => IsLowSpace ? "Kritik Seviye" : FreeSpacePercentage < 20 ? "Dikkat" : "Normal";
    }
} 