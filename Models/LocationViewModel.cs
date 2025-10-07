using System.ComponentModel.DataAnnotations;

namespace MarsDcNocMVC.Models
{
    public class LocationViewModel
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Lokasyon adı zorunludur.")]
        [Display(Name = "Lokasyon Adı")]
        public string Name { get; set; }

        [Required(ErrorMessage = "Adres bilgisi zorunludur.")]
        [Display(Name = "Adres")]
        public string Address { get; set; }
    }
} 