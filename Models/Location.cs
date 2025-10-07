using System.ComponentModel.DataAnnotations;

namespace MarsDcNocMVC.Models
{
    public class Location
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Address { get; set; }

        [Display(Name = "Telefon")]
        public string? PhoneNumber { get; set; }
    }
} 