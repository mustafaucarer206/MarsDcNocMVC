using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Scripts;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Models;

namespace MarsDcNocMVC.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private readonly ApplicationDbContext _context;

        public AdminController(ApplicationDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            return View();
        }

        public async Task<IActionResult> Locations()
        {
            var locations = await _context.Locations.ToListAsync();
            return View(locations);
        }

        public async Task<IActionResult> EditLocation(int id)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location == null)
            {
                return NotFound();
            }

            var viewModel = new LocationViewModel
            {
                Id = location.Id,
                Name = location.Name,
                Address = location.Address
            };

            return View(viewModel);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditLocation(LocationViewModel model)
        {
            if (ModelState.IsValid)
            {
                var location = await _context.Locations.FindAsync(model.Id);
                if (location == null)
                {
                    return NotFound();
                }

                location.Name = model.Name;
                location.Address = model.Address;

                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Lokasyon başarıyla güncellendi.";
                return RedirectToAction(nameof(Locations));
            }

            return View(model);
        }

        public async Task<IActionResult> Users(string searchString, string locationFilter)
        {
            var users = _context.Users.AsQueryable();

            // Arama filtresi
            if (!string.IsNullOrEmpty(searchString))
            {
                users = users.Where(u => u.Username.Contains(searchString) || 
                                       u.LocationName.Contains(searchString));
            }

            // Lokasyon filtresi
            if (!string.IsNullOrEmpty(locationFilter))
            {
                users = users.Where(u => u.LocationName == locationFilter);
            }

            // Lokasyon listesini ViewBag'e ekle
            ViewBag.Locations = await _context.Locations.Select(l => l.Name).ToListAsync();

            return View(await users.ToListAsync());
        }

        public async Task<IActionResult> CleanupUsernames()
        {
            var users = await _context.Users.ToListAsync();
            var updatedCount = 0;

            foreach (var user in users)
            {
                if (user.Username.StartsWith("mars", StringComparison.OrdinalIgnoreCase))
                {
                    var oldUsername = user.Username;
                    user.Username = user.Username.Substring(4); // "mars" ifadesini kaldır
                    updatedCount++;
                }
            }

            if (updatedCount > 0)
            {
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = $"{updatedCount} kullanıcı adı başarıyla düzenlendi.";
            }
            else
            {
                TempData["InfoMessage"] = "Düzenlenecek kullanıcı adı bulunamadı.";
            }

            return RedirectToAction(nameof(Users));
        }

        public async Task<IActionResult> AddLocationsAndUsers()
        {
            var script = new AddLocationsAndUsers(_context);
            await script.AddLocationsAndUsersAsync();

            TempData["SuccessMessage"] = "Lokasyonlar ve kullanıcılar başarıyla eklendi.";
            return RedirectToAction("Index", "Home");
        }

        public async Task<IActionResult> UpdateContact()
        {
            var username = User.Identity.Name;
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
            
            if (user == null)
            {
                return NotFound();
            }

            var model = new UpdateContactViewModel
            {
                PhoneNumber = user.PhoneNumber
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateContact(UpdateContactViewModel model)
        {
            if (ModelState.IsValid)
            {
                var username = User.Identity.Name;
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
                
                if (user == null)
                {
                    return NotFound();
                }

                user.PhoneNumber = model.PhoneNumber;

                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "İletişim bilgileriniz başarıyla güncellendi.";
                return RedirectToAction("Index");
            }

            return View(model);
        }
    }
} 