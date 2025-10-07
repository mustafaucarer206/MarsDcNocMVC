using System;
using System.ComponentModel.DataAnnotations;

namespace MarsDcNocMVC.Models
{
    public class ServerPingStatus
    {
        public int ID { get; set; }

        [Display(Name = "Lokasyon")]
        public string LocationName { get; set; }

        [Display(Name = "Sunucu")]
        public string ServerName { get; set; }

        [Display(Name = "IP Adresi")]
        public string IPAddress { get; set; }

        [Display(Name = "Durum")]
        public bool IsOnline { get; set; }

        [Display(Name = "Son Kontrol")]
        public DateTime LastPingTime { get; set; }

        [Display(Name = "Yanıt Süresi (ms)")]
        public int? ResponseTime { get; set; }

        [Display(Name = "Hata Mesajı")]
        public string ErrorMessage { get; set; }
    }
} 