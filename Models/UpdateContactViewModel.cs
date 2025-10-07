using System.ComponentModel.DataAnnotations;

namespace MarsDcNocMVC.Models
{
    public class UpdateContactViewModel
    {
        [Required(ErrorMessage = "Kullanıcı adı zorunludur.")]
        [Display(Name = "Kullanıcı Adı")]
        public string Username { get; set; }

        [Required(ErrorMessage = "Lokasyon seçimi zorunludur.")]
        [Display(Name = "Lokasyon")]
        public string LocationName { get; set; }

        [Display(Name = "Telefon Numarası")]
        [Phone(ErrorMessage = "Geçerli bir telefon numarası giriniz")]
        public string? PhoneNumber { get; set; }

        [Display(Name = "Adres Bilgisi")]
        public string? Address { get; set; }
    }
} 