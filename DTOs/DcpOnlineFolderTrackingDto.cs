using System;

namespace MarsDcNocMVC.DTOs
{
    public class DcpOnlineFolderTrackingDto
    {
        public int ID { get; set; }
        public string FolderName { get; set; } = string.Empty;
        public DateTime FirstSeenDate { get; set; }
        public DateTime LastCheckDate { get; set; }
        public DateTime? LastProcessedDate { get; set; }
        public int ProcessCount { get; set; }
        
        // Nullable long for file size to handle cases where file size is not available
        public long? FileSize { get; set; }
        public string FormattedFileSize => FileSize.HasValue ? FormatFileSize(FileSize.Value) : "N/A";
        
        public string Status { get; set; } = string.Empty;
        public bool IsProcessed { get; set; }
        public string LocationName { get; set; } = string.Empty;
        
        // Computed properties
        public string FormattedFirstSeenDate => FirstSeenDate.ToString("dd.MM.yyyy HH:mm");
        public string FormattedLastCheckDate => LastCheckDate.ToString("dd.MM.yyyy HH:mm");
        public string FormattedLastProcessedDate => LastProcessedDate?.ToString("dd.MM.yyyy HH:mm") ?? "-";
        public string StatusBadgeColor => Status switch
        {
            "MovedToWatchFolder" => "success",
            "New" => "primary", 
            "Stable" => "info",
            "CopyError" => "danger",
            _ => "secondary"
        };
        
        // Total size calculation helper
        public long FileSizeInBytes => FileSize ?? 0;
        
        private static string FormatFileSize(long bytes)
        {
            if (bytes <= 0) return "0 B";
            
            string[] sizes = { "B", "KB", "MB", "GB", "TB" };
            int order = 0;
            double len = bytes;
            
            while (len >= 1024 && order < sizes.Length - 1)
            {
                order++;
                len = len / 1024;
            }
            
            return $"{len:0.##} {sizes[order]}";
        }
        
        // Static method for total size formatting
        public static string FormatTotalSize(long totalBytes)
        {
            if (totalBytes <= 0) return "0 B";
            
            if (totalBytes >= 1073741824) // >= 1GB
                return $"{(totalBytes / 1073741824.0):F1} GB";
            else if (totalBytes >= 1048576) // >= 1MB
                return $"{(totalBytes / 1048576.0):F1} MB";
            else if (totalBytes >= 1024) // >= 1KB
                return $"{(totalBytes / 1024.0):F1} KB";
            else
                return $"{totalBytes} B";
        }
    }
} 