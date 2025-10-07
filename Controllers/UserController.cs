using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MarsDcNocMVC.Controllers
{
    [Authorize(Roles = "Admin")]
    public class UserController : Controller
    {
        private readonly ApplicationDbContext _context;
        private const int PageSize = 10;

        public UserController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(string searchString, string locationFilter, string roleFilter, int pageNumber = 1)
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

            // Rol filtresi
            if (!string.IsNullOrEmpty(roleFilter))
            {
                users = users.Where(u => u.Role == roleFilter);
            }

            var totalCount = await users.CountAsync();
            var totalPages = (int)Math.Ceiling(totalCount / (double)PageSize);

            // Sayfalama
            var pagedUsers = await users
                .Skip((pageNumber - 1) * PageSize)
                .Take(PageSize)
                .ToListAsync();

            var totalUsers = await _context.Users.CountAsync();
            var totalAdmins = await _context.Users.CountAsync(u => u.Role == "Admin");
            var totalRegularUsers = await _context.Users.CountAsync(u => u.Role == "User");
            var totalLocations = await _context.Users.Select(u => u.LocationName).Distinct().CountAsync();

            // ViewBag'e gerekli bilgileri ekle
            ViewBag.Locations = await _context.Locations.Select(l => l.Name).ToListAsync();
            ViewBag.Roles = new List<string> { "Admin", "User" };
            ViewBag.CurrentSearch = searchString;
            ViewBag.CurrentLocation = locationFilter;
            ViewBag.CurrentRole = roleFilter;
            ViewBag.CurrentPage = pageNumber;
            ViewBag.TotalPages = totalPages;
            ViewBag.HasPreviousPage = pageNumber > 1;
            ViewBag.HasNextPage = pageNumber < totalPages;
            
            ViewBag.TotalUsers = totalUsers;
            ViewBag.TotalAdmins = totalAdmins;
            ViewBag.TotalRegularUsers = totalRegularUsers;
            ViewBag.TotalLocations = totalLocations;

            var model = new PagedList<User>
            {
                Items = pagedUsers,
                PageNumber = pageNumber,
                PageSize = PageSize,
                TotalCount = totalCount,
                TotalPages = totalPages
            };

            return View(model);
        }

        public async Task<IActionResult> Create()
        {
            ViewBag.Locations = await _context.Locations.OrderBy(l => l.Name).ToListAsync();
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(User user)
        {
            if (ModelState.IsValid)
            {
                _context.Add(user);
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Kullanıcı başarıyla oluşturuldu.";
                return RedirectToAction(nameof(Index));
            }
            
            ViewBag.Locations = await _context.Locations.OrderBy(l => l.Name).ToListAsync();
            return View(user);
        }

        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound();
            }
            
            ViewBag.Locations = await _context.Locations.OrderBy(l => l.Name).ToListAsync();
            return View(user);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, User user)
        {
            if (id != user.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    _context.Update(user);
                    await _context.SaveChangesAsync();
                    TempData["SuccessMessage"] = "Kullanıcı başarıyla güncellendi.";
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!UserExists(user.Id))
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
            
            ViewBag.Locations = await _context.Locations.OrderBy(l => l.Name).ToListAsync();
            return View(user);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user != null)
            {
                _context.Users.Remove(user);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }

        private bool UserExists(int id)
        {
            return _context.Users.Any(e => e.Id == id);
        }

        [HttpGet]
        public async Task<IActionResult> GetUserData(string searchString, string locationFilter, string roleFilter, int pageNumber = 1)
        {
            try
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

                // Rol filtresi
                if (!string.IsNullOrEmpty(roleFilter))
                {
                    users = users.Where(u => u.Role == roleFilter);
                }

                var totalCount = await users.CountAsync();
                var totalPages = (int)Math.Ceiling(totalCount / (double)PageSize);

                // Sayfalama
                var pagedUsers = await users
                    .Skip((pageNumber - 1) * PageSize)
                    .Take(PageSize)
                    .Select(u => new
                    {
                        id = u.Id,
                        username = u.Username,
                        role = u.Role,
                        locationName = u.LocationName
                    })
                    .ToListAsync();

                var totalUsers = await _context.Users.CountAsync();
                var totalAdmins = await _context.Users.CountAsync(u => u.Role == "Admin");
                var totalRegularUsers = await _context.Users.CountAsync(u => u.Role == "User");
                var totalLocations = await _context.Users.Select(u => u.LocationName).Distinct().CountAsync();

                return Json(new
                {
                    users = pagedUsers,
                    statistics = new
                    {
                        totalUsers = totalUsers,
                        totalAdmins = totalAdmins,
                        totalRegularUsers = totalRegularUsers,
                        totalLocations = totalLocations
                    },
                    pagination = new
                    {
                        currentPage = pageNumber,
                        totalPages = totalPages,
                        totalCount = totalCount,
                        hasNext = pageNumber < totalPages,
                        hasPrevious = pageNumber > 1
                    }
                });
            }
            catch (Exception ex)
            {
                return Json(new { error = "Kullanıcı verileri yüklenirken bir hata oluştu: " + ex.Message });
            }
        }
    }
} 