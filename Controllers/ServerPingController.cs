using System;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Models;
using MarsDcNocMVC.Data;

namespace MarsDcNocMVC.Controllers
{
    [Authorize(Roles = "Admin")]
    public class ServerPingController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ServerPingController(ApplicationDbContext context)
        {
            _context = context;
        }

        public IActionResult Index(string locationFilter = null, string searchString = null)
        {
            try
            {
                // Temel sorgu
                var query = _context.ServerPingStatus
                    .Where(s => s.LocationName != null && 
                               s.ServerName != null && 
                               s.IPAddress != null)
                    .AsQueryable();

                // Lokasyon filtresi
                if (!string.IsNullOrEmpty(locationFilter))
                {
                    query = query.Where(s => s.LocationName == locationFilter);
                }

                // Arama filtresi
                if (!string.IsNullOrEmpty(searchString))
                {
                    query = query.Where(s => 
                        (s.ServerName != null && s.ServerName.Contains(searchString)) || 
                        (s.IPAddress != null && s.IPAddress.Contains(searchString)) ||
                        (s.LocationName != null && s.LocationName.Contains(searchString))
                    );
                }

                var latestStatus = query
                    .OrderByDescending(s => s.LastPingTime)
                    .Select(s => new ServerPingStatus
                    {
                        ID = s.ID,
                        LocationName = s.LocationName ?? string.Empty,
                        ServerName = s.ServerName ?? string.Empty,
                        IPAddress = s.IPAddress ?? string.Empty,
                        IsOnline = s.IsOnline,
                        LastPingTime = s.LastPingTime,
                        ResponseTime = s.ResponseTime,
                        ErrorMessage = s.ErrorMessage ?? string.Empty
                    })
                    .ToList();

                // Lokasyon listesini ViewBag'e ekle
                ViewBag.Locations = _context.ServerPingStatus
                    .Where(s => s.LocationName != null)
                    .Select(s => s.LocationName)
                    .Distinct()
                    .OrderBy(l => l)
                    .ToList();

                // Filtreleri ViewBag'e ekle
                ViewBag.LocationFilter = locationFilter;
                ViewBag.SearchString = searchString;

                return View(latestStatus);
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veriler yüklenirken bir hata oluştu: " + ex.Message;
                return View(new List<ServerPingStatus>());
            }
        }

        public IActionResult TableView(string locationFilter = null, string searchString = null)
        {
            try
            {
                // Temel sorgu
                var query = _context.ServerPingStatus
                    .Where(s => s.LocationName != null && 
                               s.ServerName != null && 
                               s.IPAddress != null)
                    .AsQueryable();

                // Lokasyon filtresi
                if (!string.IsNullOrEmpty(locationFilter))
                {
                    query = query.Where(s => s.LocationName == locationFilter);
                }

                // Arama filtresi
                if (!string.IsNullOrEmpty(searchString))
                {
                    query = query.Where(s => 
                        (s.ServerName != null && s.ServerName.Contains(searchString)) || 
                        (s.IPAddress != null && s.IPAddress.Contains(searchString)) ||
                        (s.LocationName != null && s.LocationName.Contains(searchString))
                    );
                }

                var latestStatus = query
                    .OrderByDescending(s => s.LastPingTime)
                    .Select(s => new ServerPingStatus
                    {
                        ID = s.ID,
                        LocationName = s.LocationName ?? string.Empty,
                        ServerName = s.ServerName ?? string.Empty,
                        IPAddress = s.IPAddress ?? string.Empty,
                        IsOnline = s.IsOnline,
                        LastPingTime = s.LastPingTime,
                        ResponseTime = s.ResponseTime,
                        ErrorMessage = s.ErrorMessage ?? string.Empty
                    })
                    .ToList();

                // Lokasyon listesini ViewBag'e ekle
                ViewBag.Locations = _context.ServerPingStatus
                    .Where(s => s.LocationName != null)
                    .Select(s => s.LocationName)
                    .Distinct()
                    .OrderBy(l => l)
                    .ToList();

                // Filtreleri ViewBag'e ekle
                ViewBag.LocationFilter = locationFilter;
                ViewBag.SearchString = searchString;

                return View(latestStatus);
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veriler yüklenirken bir hata oluştu: " + ex.Message;
                return View(new List<ServerPingStatus>());
            }
        }

        [HttpGet]
        public IActionResult GetServerStatusData()
        {
            try
            {
                var latestStatus = _context.ServerPingStatus
                    .Where(s => s.LocationName != null && 
                               s.ServerName != null && 
                               s.IPAddress != null)
                    .OrderByDescending(s => s.LastPingTime)
                    .Select(s => new
                    {
                        locationName = s.LocationName ?? string.Empty,
                        serverName = s.ServerName ?? string.Empty,
                        ipAddress = s.IPAddress ?? string.Empty,
                        isOnline = s.IsOnline,
                        lastPingTime = s.LastPingTime,
                        responseTime = s.ResponseTime,
                        errorMessage = s.ErrorMessage ?? string.Empty
                    })
                    .ToList();

                return Json(latestStatus);
            }
            catch (Exception ex)
            {
                return Json(new { error = "Veriler yüklenirken bir hata oluştu: " + ex.Message });
            }
        }
    }
} 