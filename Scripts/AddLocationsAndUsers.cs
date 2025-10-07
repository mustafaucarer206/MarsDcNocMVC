using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;

namespace MarsDcNocMVC.Scripts
{
    public class AddLocationsAndUsers
    {
        private readonly ApplicationDbContext _context;
        private readonly List<string> _locations = new()
        {
            "Mars Ankara",
            "Mars İstanbul",
            "Mars İzmir",
            "Mars Antalya",
            "Mars Bursa",
            "Mars Konya",
            "Mars Adana",
            "Mars Gaziantep",
            "Mars Kayseri",
            "Mars Mersin",
            "Mars Diyarbakır",
            "Mars Eskişehir",
            "Mars Samsun",
            "Mars Denizli",
            "Mars Şanlıurfa",
            "Mars Malatya",
            "Mars Kahramanmaraş",
            "Mars Erzurum",
            "Mars Van",
            "Mars Sakarya",
            "Mars Trabzon",
            "Mars Ordu",
            "Mars Balıkesir",
            "Mars Manisa",
            "Mars Hatay",
            "Mars Aydın",
            "Mars Tekirdağ",
            "Mars Kocaeli",
            "Mars Muğla",
            "Mars Elazığ",
            "Mars Afyonkarahisar",
            "Mars Sivas",
            "Mars Tokat",
            "Mars Zonguldak",
            "Mars Kütahya",
            "Mars Isparta",
            "Mars Yozgat",
            "Mars Çanakkale",
            "Mars Osmaniye",
            "Mars Çorum",
            "Mars Düzce",
            "Mars Karabük",
            "Mars Aksaray",
            "Mars Niğde",
            "Mars Nevşehir",
            "Mars Kırıkkale",
            "Mars Batman",
            "Mars Şırnak",
            "Mars Bartın",
            "Mars Ardahan",
            "Mars Iğdır",
            "Mars Yalova",
            "Mars Karaman",
            "Mars Kırşehir",
            "Mars Bitlis",
            "Mars Siirt",
            "Mars Hakkari",
            "Mars Muş",
            "Mars Bingöl",
            "Mars Tunceli",
            "Mars Artvin",
            "Mars Rize",
            "Mars Bayburt",
            "Mars Gümüşhane",
            "Mars Kilis",
            "Mars Amasya",
            "Mars Giresun",
            "Mars Kastamonu",
            "Mars Sinop",
            "Mars Çankırı",
            "Mars Bolu",
            "Mars Bilecik",
            "Mars Uşak",
            "Mars Burdur"
        };

        public AddLocationsAndUsers(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task AddLocationsAndUsersAsync()
        {
            foreach (var locationName in _locations)
            {
                // Lokasyon zaten var mı kontrol et
                var existingLocation = await _context.Locations
                    .FirstOrDefaultAsync(l => l.Name == locationName);

                if (existingLocation == null)
                {
                    // Yeni lokasyon ekle
                    var location = new Location { Name = locationName };
                    _context.Locations.Add(location);
                    await _context.SaveChangesAsync();

                    // Kullanıcı adını oluştur (boşlukları kaldır ve küçük harfe çevir)
                    var username = locationName.Replace(" ", "").ToLower();

                    // Kullanıcı zaten var mı kontrol et
                    var existingUser = await _context.Users
                        .FirstOrDefaultAsync(u => u.Username == username);

                    if (existingUser == null)
                    {
                        // Yeni kullanıcı ekle
                        var user = new User
                        {
                            Username = username,
                            Password = "Mars2025.", // Varsayılan şifre
                            Role = "User",
                            LocationName = locationName
                        };
                        _context.Users.Add(user);
                        await _context.SaveChangesAsync();
                    }
                }
            }
        }
    }
} 