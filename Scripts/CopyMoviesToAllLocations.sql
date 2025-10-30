USE [MarsDcNocMVC];
GO

PRINT '=== TUM LOKASYONLARA FILMLER KOPYALANIYOR ===';

-- Cevahir'deki film sayısını kontrol et
DECLARE @cevahirFilmCount INT;
SELECT @cevahirFilmCount = COUNT(*) FROM Movies WHERE Lokasyon = 'Cevahir';
PRINT 'Cevahir''de ' + CAST(@cevahirFilmCount AS VARCHAR(10)) + ' film var.';

-- Cevahir hariç lokasyon sayısını al
DECLARE @otherLocationCount INT;
SELECT @otherLocationCount = COUNT(DISTINCT Name) FROM Locations WHERE Name != 'Cevahir';
PRINT 'Diger lokasyon sayisi: ' + CAST(@otherLocationCount AS VARCHAR(10));

-- Toplam eklenecek kayıt sayısı
DECLARE @totalToInsert INT = @cevahirFilmCount * @otherLocationCount;
PRINT 'Toplam eklenecek kayit: ' + CAST(@totalToInsert AS VARCHAR(10));
PRINT '';
PRINT 'Kopyalama basliyor...';
PRINT '';

-- Cevahir'deki filmleri diğer tüm lokasyonlara kopyala
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru, EklenmeTarihi)
SELECT 
    m.FilmAdi,
    m.Sure_Dakika,
    m.Boyut_GB,
    l.Name AS Lokasyon,
    m.SalonAdi,
    m.IcerikTuru,
    GETDATE() AS EklenmeTarihi
FROM 
    Movies m
    CROSS JOIN (SELECT DISTINCT Name FROM Locations WHERE Name != 'Cevahir') l
WHERE 
    m.Lokasyon = 'Cevahir';

PRINT '';
PRINT '=== KOPYALAMA TAMAMLANDI ===';
PRINT '';

-- Sonuçları kontrol et
PRINT 'Lokasyon bazinda film dagilimi:';
SELECT 
    Lokasyon,
    COUNT(*) AS FilmSayisi
FROM Movies
GROUP BY Lokasyon
ORDER BY Lokasyon;

PRINT '';
PRINT 'Genel ozet:';
SELECT 
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT Lokasyon) AS LokasyonSayisi,
    COUNT(DISTINCT SalonAdi) AS ContentServerSayisi
FROM Movies;

PRINT '';
PRINT 'Content Server bazinda dagilim:';
SELECT 
    SalonAdi,
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT Lokasyon) AS LokasyonSayisi
FROM Movies
GROUP BY SalonAdi
ORDER BY ToplamFilm DESC;

PRINT '';
PRINT '=== TAMAMLANDI ===';
PRINT 'Her lokasyonda ' + CAST(@cevahirFilmCount AS VARCHAR(10)) + ' film var!';

