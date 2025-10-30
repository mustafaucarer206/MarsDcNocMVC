-- Duplicate filmleri temizle - sadece benzersiz film-salon kombinasyonlarini tut
USE [MarsDcNocMVC];
GO

PRINT '=== DUPLICATE FILMLER TEMIZLENIYOR ===';
PRINT '';

-- Onceki durum
SELECT 
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT CONCAT(FilmAdi, '|', SalonAdi)) AS BenzersizFilmSalon
FROM Movies;

PRINT '';
PRINT 'Duplicate ornekleri:';
SELECT TOP 10 
    FilmAdi, 
    SalonAdi, 
    COUNT(*) AS Tekrar 
FROM Movies 
GROUP BY FilmAdi, SalonAdi 
HAVING COUNT(*) > 1 
ORDER BY COUNT(*) DESC;

-- Yedek tablo olustur
SELECT * INTO Movies_WithDuplicates FROM Movies;
PRINT '';
PRINT 'Yedek tablo olusturuldu: Movies_WithDuplicates';

-- Duplicate'lari sil - her film-salon kombinasyonundan sadece birini tut
WITH DuplicateMovies AS (
    SELECT 
        Id,
        ROW_NUMBER() OVER (
            PARTITION BY FilmAdi, SalonAdi 
            ORDER BY Id
        ) as rn
    FROM Movies
)
DELETE FROM Movies 
WHERE Id IN (
    SELECT Id 
    FROM DuplicateMovies 
    WHERE rn > 1
);

PRINT '';
PRINT '=== TEMIZLEME TAMAMLANDI ===';
PRINT '';

-- Sonraki durum
SELECT 
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT CONCAT(FilmAdi, '|', SalonAdi)) AS BenzersizFilmSalon,
    COUNT(DISTINCT FilmAdi) AS BenzersizFilm,
    COUNT(DISTINCT SalonAdi) AS BenzersizSalon
FROM Movies;

PRINT '';
PRINT 'Salonlara Gore Dagilim (Temizlenmis):';
SELECT 
    SalonAdi, 
    COUNT(*) AS FilmSayisi,
    CAST(AVG(Sure_Dakika) AS DECIMAL(10,1)) AS OrtSure
FROM Movies 
GROUP BY SalonAdi 
ORDER BY FilmSayisi DESC;

PRINT '';
PRINT 'Artik duplicate yok - kontrol:';
SELECT 
    FilmAdi, 
    SalonAdi, 
    COUNT(*) AS Tekrar 
FROM Movies 
GROUP BY FilmAdi, SalonAdi 
HAVING COUNT(*) > 1;

PRINT '';
PRINT 'Ilk 10 Film (Temizlenmis):';
SELECT TOP 10 
    LEFT(FilmAdi, 60) + '...' AS FilmAdi_Kisaltilmis,
    Sure_Dakika, 
    SalonAdi,
    IcerikTuru
FROM Movies 
ORDER BY FilmAdi;

GO
