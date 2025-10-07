using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace MarsDcNocMVC.Controllers
{
    [Authorize]
    public class LocationController : Controller
    {
        private readonly ApplicationDbContext _context;
        private const int PageSize = 10; // Her sayfada gösterilecek kayıt sayısı

        public LocationController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(string searchString, int page = 1)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Login", "Account");
            }

            var locations = _context.Locations.AsQueryable();

            // Arama filtresi
            if (!string.IsNullOrEmpty(searchString))
            {
                locations = locations.Where(l => l.Name.Contains(searchString) || 
                                               l.Address.Contains(searchString));
            }

            // Filtreleme sonuçlarını ViewBag'e ekle
            ViewBag.CurrentSearch = searchString;

            // Toplam kayıt sayısını al
            var totalRecords = await locations.CountAsync();
            var totalPages = (int)Math.Ceiling(totalRecords / (double)PageSize);

            // Sayfalama için kayıtları al
            var result = await locations
                .OrderBy(l => l.Name)
                .Skip((page - 1) * PageSize)
                .Take(PageSize)
                .ToListAsync();

            // ViewBag'e gerekli verileri ekle
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = totalPages;

            return View(result);
        }

        // GET: Location/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var location = await _context.Locations
                .FirstOrDefaultAsync(m => m.Id == id);
            if (location == null)
            {
                return NotFound();
            }

            // Get users in this location
            var users = await _context.Users
                .Where(u => u.LocationName == location.Name)
                .ToListAsync();

            ViewBag.Users = users;

            return View(location);
        }

        [Authorize(Roles = "Admin")]
        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Location location)
        {
            if (ModelState.IsValid)
            {
                _context.Add(location);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            return View(location);
        }

        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var location = await _context.Locations.FindAsync(id);
            if (location == null)
            {
                return NotFound();
            }
            return View(location);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Location location)
        {
            if (id != location.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    _context.Update(location);
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!LocationExists(location.Id))
                    {
                        return NotFound();
                    }
                    else
                    {
                        throw;
                    }
                }
                return RedirectToAction(nameof(Index));
            }
            return View(location);
        }

        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var location = await _context.Locations
                .FirstOrDefaultAsync(m => m.Id == id);
            if (location == null)
            {
                return NotFound();
            }

            return View(location);
        }

        [HttpPost, ActionName("Delete")]
        [Authorize(Roles = "Admin")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location != null)
            {
                _context.Locations.Remove(location);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }

        private bool LocationExists(int id)
        {
            return _context.Locations.Any(e => e.Id == id);
        }

        [HttpGet]
        public async Task<IActionResult> GetLocationData(string searchString)
        {
            try
            {
                var locations = _context.Locations.AsQueryable();

                // Arama filtresi
                if (!string.IsNullOrEmpty(searchString))
                {
                    locations = locations.Where(l => l.Name.Contains(searchString) || 
                                                   l.Address.Contains(searchString));
                }

                var result = await locations
                    .OrderBy(l => l.Name)
                    .Select(l => new
                    {
                        id = l.Id,
                        name = l.Name,
                        address = l.Address,
                        phoneNumber = l.PhoneNumber
                    })
                    .ToListAsync();

                return Json(result);
            }
            catch (Exception ex)
            {
                return Json(new { error = "Lokasyon verileri yüklenirken bir hata oluştu: " + ex.Message });
            }
        }

        // Merkez lokasyonunu oluşturan metod
        public async Task<IActionResult> CreateMerkezLocation()
        {
            // Merkez lokasyonu var mı kontrol et
            var merkezLocation = await _context.Locations.FirstOrDefaultAsync(l => l.Name == "Merkez");
            
            if (merkezLocation == null)
            {
                // Merkez lokasyonu yoksa oluştur
                var newLocation = new Location
                {
                    Name = "Merkez",
                    Address = "Merkez Ofis"
                };

                _context.Locations.Add(newLocation);
                await _context.SaveChangesAsync();

                // Admin kullanıcısını bul ve lokasyonunu güncelle
                var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == "Admin");
                if (adminUser != null)
                {
                    adminUser.LocationName = "Merkez";
                    await _context.SaveChangesAsync();
                }

                TempData["SuccessMessage"] = "Merkez lokasyonu başarıyla oluşturuldu ve admin kullanıcısına atandı.";
            }
            else
            {
                TempData["InfoMessage"] = "Merkez lokasyonu zaten mevcut.";
            }

            return RedirectToAction(nameof(Index));
        }
    }
} 