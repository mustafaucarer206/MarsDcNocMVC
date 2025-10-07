using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Data;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using ClosedXML.Excel;

namespace MarsDcNocMVC.Controllers
{
    [Authorize]
    public class DiskCapacityController : Controller
    {
        private readonly ApplicationDbContext _context;

        public DiskCapacityController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(string searchString)
        {
            var query = _context.LocationLmsDiscCapacity.AsQueryable();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!string.IsNullOrEmpty(userId))
            {
                var user = await _context.Users.FindAsync(int.Parse(userId));
                if (user != null)
                {
                    if (user.Role != "Admin")
                    {
                        query = query.Where(x => x.LocationName == user.LocationName);
                    }
                }
            }

            if (!string.IsNullOrEmpty(searchString))
            {
                query = query.Where(x => x.LocationName.Contains(searchString));
            }

            var diskCapacities = await query
                .OrderByDescending(x => x.CheckDate)
                .ToListAsync();

            ViewBag.SearchString = searchString;

            return View(diskCapacities);
        }

        [HttpGet]
        public async Task<IActionResult> GetDiskCapacityData()
        {
            try
            {
                var query = _context.LocationLmsDiscCapacity.AsQueryable();

                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!string.IsNullOrEmpty(userId))
                {
                    var user = await _context.Users.FindAsync(int.Parse(userId));
                    if (user != null)
                    {
                        if (user.Role != "Admin")
                        {
                            query = query.Where(x => x.LocationName == user.LocationName);
                        }
                    }
                }

                var diskCapacities = await query
                    .OrderByDescending(x => x.CheckDate)
                    .Select(x => new
                    {
                        locationName = x.LocationName,
                        totalSpace = x.TotalSpace,
                        freeSpace = x.FreeSpace,
                        usedSpace = x.UsedSpace,
                        usagePercentage = x.UsagePercentage,
                        checkDate = x.CheckDate
                    })
                    .ToListAsync();

                return Json(diskCapacities);
            }
            catch (Exception ex)
            {
                return Json(new { error = "Disk kapasitesi verileri yüklenirken bir hata oluştu: " + ex.Message });
            }
        }

        [HttpGet]
        public async Task<IActionResult> ExportExcel()
        {
            try
            {
                var query = _context.LocationLmsDiscCapacity.AsQueryable();

                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!string.IsNullOrEmpty(userId))
                {
                    var user = await _context.Users.FindAsync(int.Parse(userId));
                    if (user != null)
                    {
                        if (user.Role != "Admin")
                        {
                            query = query.Where(x => x.LocationName == user.LocationName);
                        }
                    }
                }

                var diskCapacities = await query
                    .OrderByDescending(x => x.CheckDate)
                    .ToListAsync();

                using (var workbook = new XLWorkbook())
                {
                    var worksheet = workbook.Worksheets.Add("Disk Kapasitesi");
                    
                    worksheet.Cell(1, 1).Value = "Lokasyon";
                    worksheet.Cell(1, 2).Value = "Toplam Alan (GB)";
                    worksheet.Cell(1, 3).Value = "Boş Alan (GB)";
                    worksheet.Cell(1, 4).Value = "Kullanılan Alan (GB)";
                    worksheet.Cell(1, 5).Value = "Kullanım Oranı";
                    worksheet.Cell(1, 6).Value = "Kontrol Tarihi";

                    for (int i = 0; i < diskCapacities.Count; i++)
                    {
                        worksheet.Cell(i + 2, 1).Value = diskCapacities[i].LocationName;
                        worksheet.Cell(i + 2, 2).Value = diskCapacities[i].TotalSpace.ToString("N2");
                        worksheet.Cell(i + 2, 3).Value = diskCapacities[i].FreeSpace.ToString("N2");
                        worksheet.Cell(i + 2, 4).Value = diskCapacities[i].UsedSpace.ToString("N2");
                        worksheet.Cell(i + 2, 5).Value = diskCapacities[i].UsagePercentage;
                        worksheet.Cell(i + 2, 6).Value = diskCapacities[i].CheckDate.ToString("dd.MM.yyyy HH:mm");
                    }

                    var range = worksheet.Range(1, 1, diskCapacities.Count + 1, 6);
                    range.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                    range.Style.Border.InsideBorder = XLBorderStyleValues.Thin;
                    worksheet.Columns().AdjustToContents();

                    using (var stream = new MemoryStream())
                    {
                        workbook.SaveAs(stream);
                        var content = stream.ToArray();
                        return File(content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
                            $"DiskKapasitesi_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx");
                    }
                }
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "Excel dosyası oluşturulurken bir hata oluştu: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        [HttpGet]
        public async Task<IActionResult> ExportPdf()
        {
            try
            {
                var query = _context.LocationLmsDiscCapacity.AsQueryable();

                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (!string.IsNullOrEmpty(userId))
                {
                    var user = await _context.Users.FindAsync(int.Parse(userId));
                    if (user != null)
                    {
                        if (user.Role != "Admin")
                        {
                            query = query.Where(x => x.LocationName == user.LocationName);
                        }
                    }
                }

                var diskCapacities = await query
                    .OrderByDescending(x => x.CheckDate)
                    .ToListAsync();

                var html = new StringBuilder();
                html.AppendLine("<!DOCTYPE html>");
                html.AppendLine("<html>");
                html.AppendLine("<head>");
                html.AppendLine("<meta charset='utf-8'>");
                html.AppendLine("<title>Disk Kapasitesi Raporu</title>");
                html.AppendLine("<style>");
                html.AppendLine("body { font-family: Arial, sans-serif; margin: 20px; }");
                html.AppendLine("h1 { color: #333; text-align: center; }");
                html.AppendLine("table { width: 100%; border-collapse: collapse; margin-top: 20px; }");
                html.AppendLine("th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }");
                html.AppendLine("th { background-color: #f2f2f2; font-weight: bold; }");
                html.AppendLine("tr:nth-child(even) { background-color: #f9f9f9; }");
                html.AppendLine(".header-info { text-align: center; margin-bottom: 20px; color: #666; }");
                html.AppendLine("</style>");
                html.AppendLine("</head>");
                html.AppendLine("<body>");
                html.AppendLine("<h1>Disk Kapasitesi Raporu</h1>");
                html.AppendLine($"<div class='header-info'>Rapor Tarihi: {DateTime.Now:dd.MM.yyyy HH:mm}</div>");
                html.AppendLine("<table>");
                html.AppendLine("<thead>");
                html.AppendLine("<tr>");
                html.AppendLine("<th>Lokasyon</th>");
                html.AppendLine("<th>Toplam Alan (GB)</th>");
                html.AppendLine("<th>Boş Alan (GB)</th>");
                html.AppendLine("<th>Kullanılan Alan (GB)</th>");
                html.AppendLine("<th>Kullanım Oranı</th>");
                html.AppendLine("<th>Kontrol Tarihi</th>");
                html.AppendLine("</tr>");
                html.AppendLine("</thead>");
                html.AppendLine("<tbody>");

                foreach (var item in diskCapacities)
                {
                    html.AppendLine("<tr>");
                    html.AppendLine($"<td>{item.LocationName}</td>");
                    html.AppendLine($"<td>{item.TotalSpace:N2}</td>");
                    html.AppendLine($"<td>{item.FreeSpace:N2}</td>");
                    html.AppendLine($"<td>{item.UsedSpace:N2}</td>");
                    html.AppendLine($"<td>{item.UsagePercentage}</td>");
                    html.AppendLine($"<td>{item.CheckDate:dd.MM.yyyy HH:mm}</td>");
                    html.AppendLine("</tr>");
                }

                html.AppendLine("</tbody>");
                html.AppendLine("</table>");
                html.AppendLine("</body>");
                html.AppendLine("</html>");

                var bytes = Encoding.UTF8.GetBytes(html.ToString());
                var fileName = $"DiskKapasitesi_{DateTime.Now:yyyyMMdd_HHmmss}.html";

                return File(bytes, "text/html", fileName);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "PDF dosyası oluşturulurken bir hata oluştu: " + ex.Message;
                return RedirectToAction("Index");
            }
        }
    }
} 