using System;
using System.ComponentModel.DataAnnotations;

namespace MarsDcNocMVC.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;

        [Required]
        public string Role { get; set; } = string.Empty;

        [Required]
        public string LocationName { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }
    }
} 