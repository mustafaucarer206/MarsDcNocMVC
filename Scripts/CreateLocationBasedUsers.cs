using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;

namespace MarsDcNocMVC.Scripts
{
    /// <summary>
    /// Lokasyon bazlı kullanıcı oluşturma console application
    /// Her lokasyon için kullanıcı adı lokasyon adı, şifre Mars2025! olacak
    /// </summary>
    public class CreateLocationBasedUsers
    {
        private readonly ApplicationDbContext _context;
        private const string DefaultPassword = "Mars2025!";
        private const string DefaultRole = "User";

        public CreateLocationBasedUsers(ApplicationDbContext context)
        {
            _context = context;
        }

        public static async Task Main(string[] args)
        {
            Console.WriteLine("=========================================");
            Console.WriteLine("Lokasyon Bazlı Kullanıcı Oluşturma Tool");
            Console.WriteLine("=========================================");
            
            bool dryRun = args.Contains("--dry-run") || args.Contains("-d");
            
            if (dryRun)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("DRY RUN MODE - Hiçbir değişiklik yapılmayacak");
                Console.ResetColor();
            }

            // Configuration setup
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true)
                .Build();

            var connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? "Server=(local);Database=master;Integrated Security=True;";

            // Service setup
            var services = new ServiceCollection();
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(connectionString));

            var serviceProvider = services.BuildServiceProvider();

            try
            {
                using var scope = serviceProvider.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var userCreator = new CreateLocationBasedUsers(context);
                
                await userCreator.CreateUsersAsync(dryRun);
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Hata oluştu: {ex.Message}");
                Console.ResetColor();
                Environment.Exit(1);
            }
            finally
            {
                serviceProvider.Dispose();
            }

            Console.WriteLine("İşlem tamamlandı. Devam etmek için bir tuşa basın...");
            Console.ReadKey();
        }

        public async Task CreateUsersAsync(bool dryRun = false)
        {
            try
            {
                WriteColoredLine("Database bağlantısı kontrol ediliyor...", ConsoleColor.Cyan);
                
                // Database connection test
                if (!await TestDatabaseConnectionAsync())
                {
                    WriteColoredLine("Database bağlantısı başarısız!", ConsoleColor.Red);
                    return;
                }

                WriteColoredLine("Database bağlantısı başarılı", ConsoleColor.Green);

                // Get all locations except Merkez (admin is already there)
                var locations = await _context.Locations
                    .Where(l => l.Name != "Merkez")
                    .OrderBy(l => l.Name)
                    .ToListAsync();

                WriteColoredLine($"Toplam {locations.Count} lokasyon bulundu", ConsoleColor.Cyan);

                int createdCount = 0;
                int updatedCount = 0;
                int errorCount = 0;

                foreach (var location in locations)
                {
                    var username = location.Name;
                    Console.WriteLine($"İşleniyor: {location.Name}");

                    try
                    {
                        // Check if user already exists
                        var existingUser = await _context.Users
                            .FirstOrDefaultAsync(u => u.Username == username);

                        if (existingUser != null)
                        {
                            // Update existing user
                            if (!dryRun)
                            {
                                existingUser.Password = DefaultPassword;
                                existingUser.LocationName = location.Name;
                                existingUser.Role = DefaultRole; // Ensure role is set
                                await _context.SaveChangesAsync();
                            }

                            WriteColoredLine($"✓ Kullanıcı güncellendi: {username}", ConsoleColor.Green);
                            updatedCount++;
                        }
                        else
                        {
                            // Create new user
                            if (!dryRun)
                            {
                                var newUser = new User
                                {
                                    Username = username,
                                    Password = DefaultPassword,
                                    Role = DefaultRole,
                                    LocationName = location.Name,
                                    PhoneNumber = null
                                };

                                _context.Users.Add(newUser);
                                await _context.SaveChangesAsync();
                            }

                            WriteColoredLine($"✓ Kullanıcı oluşturuldu: {username}", ConsoleColor.Green);
                            createdCount++;
                        }
                    }
                    catch (Exception ex)
                    {
                        WriteColoredLine($"✗ Hata oluştu ({username}): {ex.Message}", ConsoleColor.Red);
                        errorCount++;
                    }
                }

                // Summary
                Console.WriteLine("\n================== İŞLEM ÖZETI ==================");
                WriteColoredLine($"Oluşturulan kullanıcılar: {createdCount}", ConsoleColor.Green);
                WriteColoredLine($"Güncellenen kullanıcılar: {updatedCount}", ConsoleColor.Yellow);
                WriteColoredLine($"Hata sayısı: {errorCount}", ConsoleColor.Red);

                if (!dryRun)
                {
                    await ShowUserStatisticsAsync();
                }

                WriteColoredLine($"\nTüm kullanıcıların şifresi: {DefaultPassword}", ConsoleColor.Magenta);
            }
            catch (Exception ex)
            {
                WriteColoredLine($"Genel hata: {ex.Message}", ConsoleColor.Red);
                throw;
            }
        }

        private async Task<bool> TestDatabaseConnectionAsync()
        {
            try
            {
                await _context.Database.CanConnectAsync();
                return true;
            }
            catch (Exception ex)
            {
                WriteColoredLine($"Database bağlantı hatası: {ex.Message}", ConsoleColor.Red);
                return false;
            }
        }

        private async Task ShowUserStatisticsAsync()
        {
            try
            {
                var totalUsers = await _context.Users.CountAsync();
                var adminUsers = await _context.Users.CountAsync(u => u.Role == "Admin");
                var regularUsers = await _context.Users.CountAsync(u => u.Role == "User");

                Console.WriteLine("\n================== KULLANICI İSTATİSTİKLERİ ==================");
                Console.WriteLine($"Toplam kullanıcı: {totalUsers}");
                Console.WriteLine($"Admin kullanıcı: {adminUsers}");
                Console.WriteLine($"Normal kullanıcı: {regularUsers}");
            }
            catch (Exception ex)
            {
                WriteColoredLine($"İstatistik hatası: {ex.Message}", ConsoleColor.Red);
            }
        }

        private static void WriteColoredLine(string message, ConsoleColor color)
        {
            var originalColor = Console.ForegroundColor;
            Console.ForegroundColor = color;
            Console.WriteLine(message);
            Console.ForegroundColor = originalColor;
        }

        /// <summary>
        /// Tüm lokasyonları listeler
        /// </summary>
        public async Task ListLocationsAsync()
        {
            var locations = await _context.Locations.OrderBy(l => l.Name).ToListAsync();
            
            Console.WriteLine("\n================== MEVCUT LOKASYONLAR ==================");
            foreach (var location in locations)
            {
                Console.WriteLine($"- {location.Name}");
            }
            Console.WriteLine($"Toplam: {locations.Count} lokasyon");
        }

        /// <summary>
        /// Mevcut kullanıcıları listeler
        /// </summary>
        public async Task ListUsersAsync()
        {
            var users = await _context.Users
                .OrderBy(u => u.LocationName)
                .ThenBy(u => u.Username)
                .ToListAsync();

            Console.WriteLine("\n================== MEVCUT KULLANICILAR ==================");
            foreach (var user in users)
            {
                Console.WriteLine($"- {user.Username} ({user.Role}) - {user.LocationName}");
            }
            Console.WriteLine($"Toplam: {users.Count} kullanıcı");
        }
    }
}

/*
Kullanım örnekleri:

1. Normal çalıştırma:
   dotnet run

2. Dry run (test modu):
   dotnet run -- --dry-run
   dotnet run -- -d

3. Program.cs'de bu sınıfı kullanma:
   var userCreator = new CreateLocationBasedUsers(context);
   await userCreator.CreateUsersAsync();
   await userCreator.ListLocationsAsync();
   await userCreator.ListUsersAsync();
*/ 