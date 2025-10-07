using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarsDcNocMVC.Models
{
    public class DcpOnlineFolderTracking
    {
        [Key]
        public int ID { get; set; }

        [Required]
        [StringLength(255)]
        public string FolderName { get; set; }

        [Required]
        public DateTime FirstSeenDate { get; set; }

        [Required]
        public DateTime LastCheckDate { get; set; }

        public DateTime? LastProcessedDate { get; set; }

        public int ProcessCount { get; set; }

        public double? FileSize { get; set; }

        [StringLength(50)]
        public string? Status { get; set; }

        [Required]
        public bool IsProcessed { get; set; }

        [StringLength(255)]
        public string? LocationName { get; set; }
    }
} 