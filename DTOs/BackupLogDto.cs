using System;

namespace MarsDcNocMVC.DTOs
{
    public class BackupLogDto
    {
        public int ID { get; set; }
        public string FolderName { get; set; }
        public string Action { get; set; }
        public DateTime Timestamp { get; set; }
        public bool IsSuccess { get; set; }
        public string Status => IsSuccess ? "Başarılı" : "Başarısız";
        public string LocationName { get; set; }
        public string Duration { get; set; }
        public string FileSize { get; set; }
        public string AverageSpeed { get; set; }
        public string DownloadSpeed { get; set; }
        public string TotalFileSize { get; set; }
        
        // Computed properties
        public string FormattedTimestamp => Timestamp.ToString("dd.MM.yyyy HH:mm:ss");
        public string ActionIcon => Action?.Contains("Indirme") == true ? "download" : "upload";
    }
} 