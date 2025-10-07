using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace MarsDcNocMVC.Controllers
{
    [Authorize]
    public class BackupLogController : Controller
    {
        private readonly ApplicationDbContext _context;
        private const int PageSize = 10; // Her sayfada gösterilecek kayıt sayısı

        public BackupLogController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(string searchString, string locationFilter, string actionFilter, int page = 1)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Login", "Account");
            }

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _context.Users.FindAsync(int.Parse(userId));

            if (user == null)
            {
                return NotFound();
            }

            var logs = _context.BackupLogs.AsQueryable();

            // Status = 0 olan kayıtları filtrele
            logs = logs.Where(l => l.Status == 0);

            // Admin kullanıcısı için tüm lokasyonları göster
            if (User.IsInRole("Admin"))
            {
                ViewBag.Locations = await _context.Locations.Select(l => l.Name).ToListAsync();
            }
            else
            {
                // Normal kullanıcı için sadece kendi lokasyonunu göster
                ViewBag.Locations = new List<string> { user.LocationName };
                logs = logs.Where(l => l.LocationName == user.LocationName);
            }

            // Arama filtresi
            if (!string.IsNullOrEmpty(searchString))
            {
                logs = logs.Where(l => l.FolderName.Contains(searchString) || 
                                     l.Action.Contains(searchString));
            }

            // Lokasyon filtresi
            if (!string.IsNullOrEmpty(locationFilter))
            {
                logs = logs.Where(l => l.LocationName == locationFilter);
            }

            // İşlem filtresi
            if (!string.IsNullOrEmpty(actionFilter))
            {
                logs = logs.Where(l => l.Action == actionFilter);
            }

            // Filtreleme sonuçlarını ViewBag'e ekle
            ViewBag.CurrentSearch = searchString;
            ViewBag.CurrentLocation = locationFilter;
            ViewBag.CurrentAction = actionFilter;

            // Toplam kayıt sayısını al
            var totalRecords = await logs.CountAsync();
            var totalPages = (int)Math.Ceiling(totalRecords / (double)PageSize);

            // Sayfalama için kayıtları al
            var result = await logs
                .OrderByDescending(l => l.Timestamp)
                .Skip((page - 1) * PageSize)
                .Take(PageSize)
                .ToListAsync();

            // ViewBag'e gerekli verileri ekle
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = totalPages;
            ViewBag.IsAdmin = User.IsInRole("Admin");

            return View(result);
        }
    }
} 