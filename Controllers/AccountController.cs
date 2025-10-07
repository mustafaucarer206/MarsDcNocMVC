using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;

namespace MarsDcNocMVC.Controllers
{
    public class AccountController : Controller
    {
        private readonly ApplicationDbContext _context;

        public AccountController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Login()
        {
            if (User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginViewModel model)
        {
            if (ModelState.IsValid)
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Username == model.Username && u.Password == model.Password);

                if (user != null)
                {
                    var claims = new List<Claim>
                    {
                        new Claim(ClaimTypes.Name, user.Username),
                        new Claim(ClaimTypes.Role, user.Role),
                        new Claim(ClaimTypes.NameIdentifier, user.Id.ToString())
                    };

                    var identity = new ClaimsIdentity(claims, "Cookies");
                    var principal = new ClaimsPrincipal(identity);

                    await HttpContext.SignInAsync("Cookies", principal);

                    return RedirectToAction("Index", "Home");
                }

                ModelState.AddModelError("", "Geçersiz kullanıcı adı veya şifre");
            }

            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> Register()
        {
            if (User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index", "Home");
            }

            var locationList = await _context.Locations.ToListAsync();
            ViewBag.Locations = locationList.Select(l => new SelectListItem
            {
                Value = l.Name,
                Text = l.Name
            }).ToList();
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(RegisterViewModel model)
        {
            if (ModelState.IsValid)
            {
                if (await _context.Users.AnyAsync(u => u.Username == model.Username))
                {
                    ModelState.AddModelError("Username", "Bu kullanıcı adı zaten kullanılıyor");
                    var locationList = await _context.Locations.ToListAsync();
                    ViewBag.Locations = locationList.Select(l => new SelectListItem
                    {
                        Value = l.Name,
                        Text = l.Name
                    }).ToList();
                    return View(model);
                }

                var user = new User
                {
                    Username = model.Username,
                    Password = model.Password,
                    Role = "User",
                    LocationName = model.LocationName
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                return RedirectToAction("Login");
            }

            var locationList2 = await _context.Locations.ToListAsync();
            ViewBag.Locations = locationList2.Select(l => new SelectListItem
            {
                Value = l.Name,
                Text = l.Name
            }).ToList();
            return View(model);
        }

        [Authorize]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync("Cookies");
            return RedirectToAction("Login");
        }

        [HttpGet]
        [Authorize]
        public async Task<IActionResult> UpdateContact()
        {
            var username = User.Identity?.Name;
            if (string.IsNullOrEmpty(username))
                return RedirectToAction("Login");

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
            if (user == null)
                return NotFound();

            var location = await _context.Locations.FirstOrDefaultAsync(l => l.Name == user.LocationName);

            var model = new UpdateContactViewModel
            {
                Username = user.Username,
                LocationName = user.LocationName,
                PhoneNumber = user.PhoneNumber ?? string.Empty,
                Address = location?.Address ?? string.Empty // Lokasyondan adres bilgisini al, null ise boş string
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize]
        public async Task<IActionResult> UpdateContact(UpdateContactViewModel model)
        {
            if (ModelState.IsValid)
            {
                var username = User.Identity?.Name;
                if (string.IsNullOrEmpty(username))
                    return RedirectToAction("Login");

                var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
                if (user == null)
                    return NotFound();

                user.PhoneNumber = model.PhoneNumber;

                if (User.IsInRole("Admin") && !string.IsNullOrEmpty(model.Address))
                {
                    var location = await _context.Locations.FirstOrDefaultAsync(l => l.Name == user.LocationName);
                    if (location != null)
                    {
                        location.Address = model.Address;
                    }
                }

                await _context.SaveChangesAsync();
                TempData["Success"] = "İletişim bilgileri başarıyla güncellendi.";
                return RedirectToAction("UpdateContact");
            }

            return View(model);
        }

        [Authorize]
        public IActionResult ChangePassword()
        {
            return View();
        }

        [Authorize]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ChangePassword(ChangePasswordViewModel model)
        {
            if (ModelState.IsValid)
            {
                var username = User.Identity.Name;
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Username == username);

                if (user == null)
                {
                    return NotFound();
                }

                if (user.Password != model.CurrentPassword)
                {
                    ModelState.AddModelError("CurrentPassword", "Mevcut şifre yanlış");
                    return View(model);
                }

                user.Password = model.NewPassword;
                await _context.SaveChangesAsync();

                TempData["SuccessMessage"] = "Şifreniz başarıyla değiştirildi.";
                return RedirectToAction("Index", "Home");
            }

            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> AccessDenied(string returnUrl = null)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Login", "Account");
            }

            if (!string.IsNullOrEmpty(returnUrl) && returnUrl.Contains("/DiskCapacity"))
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!string.IsNullOrEmpty(userId))
                {
                    var user = await _context.Users.FindAsync(int.Parse(userId));
                    if (user != null)
                    {
                        return RedirectToAction("Index", "DiskCapacity");
                    }
                }
            }

            ViewBag.ReturnUrl = returnUrl;
            return View();
        }
    }
} 