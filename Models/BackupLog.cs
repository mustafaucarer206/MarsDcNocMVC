using System;
using System.ComponentModel.DataAnnotations;

namespace MarsDcNocMVC.Models
{
    public class BackupLog
    {
        [Key]
        public int ID { get; set; }
        
        [Required]
        [StringLength(255)]
        public string FolderName { get; set; }
        
        [Required]
        [StringLength(255)]
        public string Action { get; set; }
        
        [Required]
        public DateTime Timestamp { get; set; }
        
        [Required]
        public int Status { get; set; }
        
        [StringLength(255)]
        public string? LocationName { get; set; }
        
        [StringLength(50)]
        public string? Duration { get; set; }
        
        [StringLength(50)]
        public string? FileSize { get; set; }
        
        [StringLength(50)]
        public string? AverageSpeed { get; set; }
        
        [StringLength(50)]
        public string? DownloadSpeed { get; set; }
        
        [StringLength(50)]
        public string? TotalFileSize { get; set; }
    }
} 