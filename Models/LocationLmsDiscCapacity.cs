using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarsDcNocMVC.Models
{
    public class LocationLmsDiscCapacity
    {
        [Key]
        public int ID { get; set; }

        [Required]
        [StringLength(255)]
        [Display(Name = "Lokasyon")]
        public string LocationName { get; set; }

        [Required]
        [Display(Name = "Toplam Alan (GB)")]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalSpace { get; set; }

        [Required]
        [Display(Name = "Boş Alan (GB)")]
        [Column(TypeName = "decimal(18,2)")]
        public decimal FreeSpace { get; set; }

        [Required]
        [Display(Name = "Kullanılan Alan (GB)")]
        [Column(TypeName = "decimal(18,2)")]
        public decimal UsedSpace { get; set; }

        [Required]
        [Display(Name = "Kontrol Tarihi")]
        public DateTime CheckDate { get; set; }

        [NotMapped]
        [Display(Name = "Kullanım Oranı")]
        public string UsagePercentage => $"{((UsedSpace / TotalSpace) * 100):N2}%";
    }
} 