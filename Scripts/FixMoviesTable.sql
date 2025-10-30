-- Movies tablosunu guncelle: gereksiz sutunlari kaldir ve yapıyı düzelt
USE [MarsDcNocMVC];
GO

-- Mevcut verileri yedekle
SELECT * INTO Movies_Backup FROM Movies;
GO

-- Eski tabloyu sil
DROP TABLE IF EXISTS Movies;
GO

-- Yeni temiz tablo olustur
CREATE TABLE Movies (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FilmAdi NVARCHAR(500) NOT NULL,
    Sure_Dakika DECIMAL(10,2),
    Boyut_GB DECIMAL(10,2),
    Lokasyon NVARCHAR(100) DEFAULT 'Cevahir',
    CihazAdi NVARCHAR(200),
    SalonAdi NVARCHAR(200),
    IcerikTuru NVARCHAR(50) DEFAULT 'Feature',
    EklenmeTarihi DATETIME2 DEFAULT GETDATE(),
    
    INDEX IX_Movies_FilmAdi (FilmAdi),
    INDEX IX_Movies_Lokasyon (Lokasyon),
    INDEX IX_Movies_CihazAdi (CihazAdi),
    INDEX IX_Movies_SalonAdi (SalonAdi)
);
GO

PRINT 'Yeni Movies tablosu olusturuldu.';
PRINT 'Eski veriler Movies_Backup tablosunda saklanıyor.';
GO

-- Mevcut verileri kopyala (sadece gerekli sutunlar)
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, CihazAdi, SalonAdi, IcerikTuru)
SELECT 
    FilmAdi,
    Sure_Dakika,
    Boyut_GB,
    COALESCE(Lokasyon, 'Cevahir'),
    CihazAdi,
    SalonAdi,
    COALESCE(IcerikTuru, 'Feature')
FROM Movies_Backup;
GO

PRINT 'Veriler aktarıldı.';
GO

SELECT 
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT CihazAdi) AS FarkliCihazSayisi,
    COUNT(DISTINCT SalonAdi) AS FarkliSalonSayisi,
    SUM(CASE WHEN CihazAdi IS NULL THEN 1 ELSE 0 END) AS BosCihaz,
    SUM(CASE WHEN SalonAdi IS NULL THEN 1 ELSE 0 END) AS BosSalon
FROM Movies;
GO
