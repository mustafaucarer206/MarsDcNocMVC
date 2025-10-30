-- Salon adlarini duzelt ve cihaz sutununu kaldir
USE [MarsDcNocMVC];
GO

-- Mevcut verileri yedekle
SELECT * INTO Movies_Backup2 FROM Movies;
GO

-- Salon adlarini duzelt
UPDATE Movies 
SET SalonAdi = CASE 
    WHEN SalonAdi LIKE '%Solaria%SR1000%' OR SalonAdi LIKE '%SR1000%' THEN 'Salon 1'
    WHEN SalonAdi LIKE '%Solaria%IMB%' OR SalonAdi LIKE '%IMB%' THEN 'Salon 2'
    WHEN SalonAdi LIKE '%CP2230U%' THEN 'Salon 3'
    WHEN SalonAdi LIKE '%CP2210%' THEN 'Salon 4'
    WHEN SalonAdi LIKE '%CP2220%' THEN 'Salon 5'
    WHEN CihazAdi = 'LMS' THEN 'DcpOnline'
    WHEN SalonAdi = 'Belirtilmemiş' AND CihazAdi = 'LMS' THEN 'DcpOnline'
    WHEN SalonAdi = 'Belirtilmemiş' THEN 'Salon 6'
    ELSE SalonAdi
END;
GO

-- Yeni temiz tablo olustur (cihaz sutunu olmadan)
CREATE TABLE Movies_New (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FilmAdi NVARCHAR(500) NOT NULL,
    Sure_Dakika DECIMAL(10,2),
    Boyut_GB DECIMAL(10,2),
    Lokasyon NVARCHAR(100) DEFAULT 'Cevahir',
    SalonAdi NVARCHAR(200),
    IcerikTuru NVARCHAR(50) DEFAULT 'Feature',
    EklenmeTarihi DATETIME2 DEFAULT GETDATE(),
    
    INDEX IX_Movies_FilmAdi (FilmAdi),
    INDEX IX_Movies_Lokasyon (Lokasyon),
    INDEX IX_Movies_SalonAdi (SalonAdi)
);
GO

-- Verileri yeni tabloya aktar (cihaz sutunu olmadan)
INSERT INTO Movies_New (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru)
SELECT 
    FilmAdi,
    Sure_Dakika,
    Boyut_GB,
    Lokasyon,
    SalonAdi,
    IcerikTuru
FROM Movies;
GO

-- Eski tabloyu sil ve yenisini yeniden adlandir
DROP TABLE Movies;
GO

EXEC sp_rename 'Movies_New', 'Movies';
GO

PRINT 'Salon adlari duzeltildi ve cihaz sutunu kaldirildi.';
GO

-- Sonuclari kontrol et
SELECT 
    SalonAdi,
    COUNT(*) AS FilmSayisi
FROM Movies
GROUP BY SalonAdi
ORDER BY FilmSayisi DESC;
GO

PRINT '';
PRINT 'Ilk 10 Film:';
SELECT TOP 10 
    FilmAdi, 
    Sure_Dakika, 
    CAST(Boyut_GB AS DECIMAL(10,2)) AS Boyut_GB,
    SalonAdi,
    Lokasyon,
    IcerikTuru
FROM Movies 
ORDER BY FilmAdi;
GO
