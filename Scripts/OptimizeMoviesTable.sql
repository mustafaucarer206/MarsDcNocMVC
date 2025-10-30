USE [MarsDcNocMVC];
GO

PRINT '=== MOVIES TABLOSU OPTIMIZASYONU ===';

-- Mevcut indexleri kontrol et
PRINT 'Mevcut indexler:';
SELECT 
    i.name AS IndexName,
    c.name AS ColumnName,
    i.type_desc AS IndexType
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('Movies')
ORDER BY i.index_id, ic.index_column_id;

PRINT '';
PRINT 'Index''ler olusturuluyor...';

-- Lokasyon için index (en çok kullanılacak filtre)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Movies_Lokasyon' AND object_id = OBJECT_ID('Movies'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Movies_Lokasyon ON Movies(Lokasyon) INCLUDE (FilmAdi, Sure_Dakika, SalonAdi, IcerikTuru);
    PRINT 'OK: IX_Movies_Lokasyon olusturuldu';
END
ELSE
    PRINT 'SKIP: IX_Movies_Lokasyon zaten var';

-- SalonAdi için index
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Movies_SalonAdi' AND object_id = OBJECT_ID('Movies'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Movies_SalonAdi ON Movies(SalonAdi) INCLUDE (FilmAdi, Lokasyon);
    PRINT 'OK: IX_Movies_SalonAdi olusturuldu';
END
ELSE
    PRINT 'SKIP: IX_Movies_SalonAdi zaten var';

-- IcerikTuru için index
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Movies_IcerikTuru' AND object_id = OBJECT_ID('Movies'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Movies_IcerikTuru ON Movies(IcerikTuru);
    PRINT 'OK: IX_Movies_IcerikTuru olusturuldu';
END
ELSE
    PRINT 'SKIP: IX_Movies_IcerikTuru zaten var';

-- Composite index (Lokasyon + SalonAdi + IcerikTuru) - en hızlı sorgu için
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Movies_Composite' AND object_id = OBJECT_ID('Movies'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Movies_Composite ON Movies(Lokasyon, SalonAdi, IcerikTuru) INCLUDE (FilmAdi, Sure_Dakika);
    PRINT 'OK: IX_Movies_Composite olusturuldu';
END
ELSE
    PRINT 'SKIP: IX_Movies_Composite zaten var';

-- FilmAdi için full-text index (arama için)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Movies_FilmAdi' AND object_id = OBJECT_ID('Movies'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Movies_FilmAdi ON Movies(FilmAdi);
    PRINT 'OK: IX_Movies_FilmAdi olusturuldu';
END
ELSE
    PRINT 'SKIP: IX_Movies_FilmAdi zaten var';

PRINT '';
PRINT '=== OPTIMIZASYON TAMAMLANDI ===';

-- İstatistikleri güncelle
UPDATE STATISTICS Movies;
PRINT 'Istatistikler guncellendi';

PRINT '';
PRINT 'Test sorgusu (Lokasyon filtreli):';
SET STATISTICS TIME ON;
SELECT COUNT(*) FROM Movies WHERE Lokasyon = 'Cevahir' AND SalonAdi = 'LMS' AND IcerikTuru = 'feature';
SET STATISTICS TIME OFF;

