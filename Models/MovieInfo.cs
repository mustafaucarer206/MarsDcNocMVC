using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MarsDcNocMVC.Models
{
    [Table("Movies")]
    public class MovieInfo
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(500)]
        [Display(Name = "Film Adı")]
        public string FilmAdi { get; set; }

        [Display(Name = "Süre (Dakika)")]
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Sure_Dakika { get; set; }

        [Display(Name = "Boyut (GB)")]
        [Column(TypeName = "decimal(10,2)")]
        public decimal? Boyut_GB { get; set; }

        [StringLength(100)]
        [Display(Name = "Lokasyon")]
        public string? Lokasyon { get; set; } = "Cevahir";

        [StringLength(200)]
        [Display(Name = "Salon Adı")]
        public string? SalonAdi { get; set; }

        [StringLength(50)]
        [Display(Name = "İçerik Türü")]
        public string? IcerikTuru { get; set; }

        [Display(Name = "Eklenme Tarihi")]
        public DateTime EklenmeTarihi { get; set; } = DateTime.Now;
    }
}

