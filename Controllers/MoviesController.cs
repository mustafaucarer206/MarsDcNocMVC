using MarsDcNocMVC.Data;
using MarsDcNocMVC.Models;
using MarsDcNocMVC.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using ClosedXML.Excel;
using iTextSharp.text;
using iTextSharp.text.pdf;

namespace MarsDcNocMVC.Controllers
{
    [Authorize(Roles = "Admin")]
    public class MoviesController : Controller
    {
        private readonly ApplicationDbContext _context;

        public MoviesController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(string searchString, string lokasyon = null, string salon = "LMS", string icerikTuru = "feature", int page = 1)
        {
            const int pageSize = 100;

            // Sadece ilk GET isteginde (query string tamamen bossa) Cevahir'i varsayilan yap
            bool isInitialLoad = !Request.Query.ContainsKey("lokasyon") && 
                                !Request.Query.ContainsKey("searchString") && 
                                !Request.Query.ContainsKey("salon") && 
                                !Request.Query.ContainsKey("icerikTuru");

            if (isInitialLoad)
            {
                lokasyon = "Cevahir";
            }

            ViewBag.SearchString = searchString;
            ViewBag.Lokasyon = lokasyon ?? "";
            ViewBag.Salon = salon;
            ViewBag.IcerikTuru = icerikTuru;
            ViewBag.CurrentPage = page;

            var contentServers = new[] { "LMS", "DCP Online", "Qube Online", "DC FTP", "Watchfolder", "Ingest", "Content Server" };

            var moviesQuery = _context.Movies
                .Where(m => contentServers.Contains(m.SalonAdi))
                .AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
            {
                moviesQuery = moviesQuery.Where(m => m.FilmAdi.Contains(searchString));
            }

            if (!string.IsNullOrEmpty(lokasyon))
            {
                moviesQuery = moviesQuery.Where(m => m.Lokasyon == lokasyon);
            }

            if (!string.IsNullOrEmpty(salon))
            {
                moviesQuery = moviesQuery.Where(m => m.SalonAdi == salon);
            }

            if (!string.IsNullOrEmpty(icerikTuru))
            {
                moviesQuery = moviesQuery.Where(m => m.IcerikTuru == icerikTuru);
            }

            var totalRecords = await moviesQuery.CountAsync();
            ViewBag.TotalRecords = totalRecords;
            ViewBag.TotalPages = (int)Math.Ceiling(totalRecords / (double)pageSize);
            ViewBag.PageSize = pageSize;

            var movieDtos = await moviesQuery
                .OrderBy(m => m.FilmAdi)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new MovieDto
                {
                    FilmAdi = m.FilmAdi,
                    Sure_Dakika = m.Sure_Dakika,
                    SalonAdi = m.SalonAdi,
                    IcerikTuru = m.IcerikTuru,
                    Lokasyon = m.Lokasyon
                })
                .ToListAsync();

            ViewBag.Lokasyonlar = await _context.Movies
                .Select(m => m.Lokasyon)
                .Distinct()
                .OrderBy(l => l)
                .ToListAsync();

            ViewBag.Salonlar = await _context.Movies
                .Where(m => contentServers.Contains(m.SalonAdi))
                .Select(m => m.SalonAdi)
                .Distinct()
                .OrderBy(s => s)
                .ToListAsync();

            return View(movieDtos);
        }

        [HttpGet]
        public async Task<IActionResult> ExportExcel(string searchString, string lokasyon, string salon, string icerikTuru)
        {
            var contentServers = new[] { "LMS", "DCP Online", "Qube Online", "DC FTP", "Watchfolder", "Ingest", "Content Server" };

            var moviesQuery = _context.Movies
                .Where(m => contentServers.Contains(m.SalonAdi))
                .AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
            {
                moviesQuery = moviesQuery.Where(m => m.FilmAdi.Contains(searchString));
            }

            if (!string.IsNullOrEmpty(lokasyon))
            {
                moviesQuery = moviesQuery.Where(m => m.Lokasyon == lokasyon);
            }

            if (!string.IsNullOrEmpty(salon))
            {
                moviesQuery = moviesQuery.Where(m => m.SalonAdi == salon);
            }

            if (!string.IsNullOrEmpty(icerikTuru))
            {
                moviesQuery = moviesQuery.Where(m => m.IcerikTuru == icerikTuru);
            }

            var movies = await moviesQuery.OrderBy(m => m.FilmAdi).ToListAsync();

            using (var workbook = new XLWorkbook())
            {
                var worksheet = workbook.Worksheets.Add("Filmler");

                worksheet.Cell(1, 1).Value = "Film Adı";
                worksheet.Cell(1, 2).Value = "Süre (dk)";
                worksheet.Cell(1, 3).Value = "Content Server";
                worksheet.Cell(1, 4).Value = "İçerik Türü";
                worksheet.Cell(1, 5).Value = "Lokasyon";

                worksheet.Range(1, 1, 1, 5).Style.Font.Bold = true;
                worksheet.Range(1, 1, 1, 5).Style.Fill.BackgroundColor = XLColor.LightGray;

                int row = 2;
                foreach (var movie in movies)
                {
                    worksheet.Cell(row, 1).Value = movie.FilmAdi;
                    worksheet.Cell(row, 2).Value = movie.Sure_Dakika?.ToString("N2") ?? "-";
                    worksheet.Cell(row, 3).Value = movie.SalonAdi ?? "-";
                    worksheet.Cell(row, 4).Value = movie.IcerikTuru ?? "-";
                    worksheet.Cell(row, 5).Value = movie.Lokasyon ?? "-";
                    row++;
                }

                worksheet.Columns().AdjustToContents();

                using (var stream = new MemoryStream())
                {
                    workbook.SaveAs(stream);
                    var content = stream.ToArray();
                    return File(content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"Filmler_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx");
                }
            }
        }

        [HttpGet]
        public async Task<IActionResult> ExportPdf(string searchString, string lokasyon, string salon, string icerikTuru)
        {
            var contentServers = new[] { "LMS", "DCP Online", "Qube Online", "DC FTP", "Watchfolder", "Ingest", "Content Server" };

            var moviesQuery = _context.Movies
                .Where(m => contentServers.Contains(m.SalonAdi))
                .AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
            {
                moviesQuery = moviesQuery.Where(m => m.FilmAdi.Contains(searchString));
            }

            if (!string.IsNullOrEmpty(lokasyon))
            {
                moviesQuery = moviesQuery.Where(m => m.Lokasyon == lokasyon);
            }

            if (!string.IsNullOrEmpty(salon))
            {
                moviesQuery = moviesQuery.Where(m => m.SalonAdi == salon);
            }

            if (!string.IsNullOrEmpty(icerikTuru))
            {
                moviesQuery = moviesQuery.Where(m => m.IcerikTuru == icerikTuru);
            }

            var movies = await moviesQuery.OrderBy(m => m.FilmAdi).ToListAsync();

            using (var ms = new MemoryStream())
            {
                var document = new iTextSharp.text.Document(PageSize.A4.Rotate(), 25, 25, 30, 30);
                PdfWriter.GetInstance(document, ms);
                document.Open();

                var titleFont = FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 18);
                var normalFont = FontFactory.GetFont(FontFactory.HELVETICA, 10);
                
                document.Add(new Paragraph("Filmler Listesi", titleFont));
                document.Add(new Paragraph($"Oluşturulma Tarihi: {DateTime.Now:dd.MM.yyyy HH:mm}", normalFont));
                document.Add(new Paragraph($"Toplam Film: {movies.Count}", normalFont));
                document.Add(new Paragraph(" "));

                PdfPTable table = new PdfPTable(5);
                table.WidthPercentage = 100;
                table.SetWidths(new float[] { 40f, 10f, 15f, 15f, 20f });

                string[] headers = { "Film Adı", "Süre (dk)", "Content Server", "İçerik Türü", "Lokasyon" };
                foreach (string header in headers)
                {
                    table.AddCell(new PdfPCell(new Phrase(header)) { BackgroundColor = BaseColor.LightGray });
                }

                foreach (var movie in movies)
                {
                    table.AddCell(movie.FilmAdi ?? "-");
                    table.AddCell(movie.Sure_Dakika?.ToString("N0") ?? "-");
                    table.AddCell(movie.SalonAdi ?? "-");
                    table.AddCell(movie.IcerikTuru ?? "-");
                    table.AddCell(movie.Lokasyon ?? "-");
                }

                document.Add(table);
                document.Close();

                return File(ms.ToArray(), "application/pdf", $"Filmler_{DateTime.Now:yyyyMMdd_HHmmss}.pdf");
            }
        }
    }
}

