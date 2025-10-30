-- CPL ve CPL_VALIDATION tablolarından detaylı film bilgilerini gosteren VIEW
USE [MarsDcNocMVC];
GO

-- Eski view varsa sil
IF OBJECT_ID('dbo.vw_FilmDetayListesi', 'V') IS NOT NULL
    DROP VIEW dbo.vw_FilmDetayListesi;
GO

-- Detayli film listesi VIEW
CREATE VIEW dbo.vw_FilmDetayListesi AS
SELECT 
    -- Film Temel Bilgileri
    c.uuid AS film_uuid,
    c.content_title AS film_adi,
    c.content_kind AS icerik_turu,
    c.nick_name AS kisa_ad,
    
    -- Sure Bilgileri
    c.duration_in_frames AS sure_frame,
    c.duration_in_seconds AS sure_saniye,
    CAST(c.duration_in_seconds / 60.0 AS DECIMAL(10,2)) AS sure_dakika,
    CAST(c.duration_in_seconds / 3600.0 AS DECIMAL(10,2)) AS sure_saat,
    
    -- Teknik Bilgiler
    c.resolution AS cozunurluk,
    c.aspect_ratio AS en_boy_orani,
    c.edit_rate_a + '/' + c.edit_rate_b AS frame_rate,
    c.video_encoding AS video_kodlama,
    c.audio_type AS ses_tipi,
    c.package_type AS paket_tipi,
    
    -- Icerik Bilgileri
    c.rating AS siniflandirma,
    c.encrypted AS sifreli,
    c.subtitled AS altyazili,
    c.audio_language AS ses_dili,
    c.subtitle_language AS altyazi_dili,
    c.territory AS bolge,
    
    -- Uretim Bilgileri
    c.studio AS studyo,
    c.facility AS tesis,
    c.source AS kaynak,
    c.create_date AS olusturma_tarihi,
    c.last_updated AS son_guncelleme,
    
    -- Ozel Ozellikler
    c.four_d_motion_start_cue AS d4_baslangic,
    c.four_d_motion_end_cue AS d4_bitis,
    c.ghostbusting AS hayalet_onleme,
    c.motion_simulator_format AS hareket_simulatoru,
    
    -- Hata ve Durum Bilgiler
    c.error_message AS hata_mesaji,
    c.partial AS kismi,
    
    -- Validation Bilgileri (CPL_VALIDATION tablosundan)
    cv.device_uuid AS dogrulama_cihaz_uuid,
    cv.validated AS dogrulandi,
    cv.validation_type AS dogrulama_tipi,
    cv.validation_message AS dogrulama_mesaji,
    cv.validation_date AS dogrulama_tarihi,
    
    -- Device Bilgileri (varsa)
    d.name AS cihaz_adi,
    d.category AS cihaz_kategorisi,
    d.type AS cihaz_tipi,
    d.model AS cihaz_modeli,
    d.ip AS cihaz_ip,
    
    -- Screen Bilgileri (varsa)
    s.name AS salon_adi
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid
    LEFT JOIN device d ON cv.device_uuid = d.uuid
    LEFT JOIN screen s ON d.screen_uuid = s.uuid
WHERE
    c.content_title IS NOT NULL
    AND c.content_title != '';
GO

PRINT 'VIEW basariyla olusturuldu!';
PRINT '';
PRINT '=== KULLANIM ORNEKLERI ===';
PRINT '';
PRINT '1. Tum filmleri gormek:';
PRINT '   SELECT film_adi, sure_dakika, cozunurluk, siniflandirma FROM vw_FilmDetayListesi ORDER BY film_adi;';
PRINT '';
PRINT '2. Sifreli filmleri gormek:';
PRINT '   SELECT film_adi, sifreli, dogrulandi FROM vw_FilmDetayListesi WHERE sifreli = ''t'';';
PRINT '';
PRINT '3. 4K filmleri gormek:';
PRINT '   SELECT film_adi, cozunurluk, en_boy_orani FROM vw_FilmDetayListesi WHERE cozunurluk LIKE ''%4096%'';';
PRINT '';
PRINT '4. Dogrulanmis filmleri gormek:';
PRINT '   SELECT film_adi, cihaz_adi, salon_adi, dogrulama_tarihi FROM vw_FilmDetayListesi WHERE dogrulandi = ''t'';';
PRINT '';
PRINT '5. 4D film ozelliklerine sahip filmleri gormek:';
PRINT '   SELECT film_adi, d4_baslangic, d4_bitis FROM vw_FilmDetayListesi WHERE d4_baslangic IS NOT NULL;';
GO

-- Ornek istatistikler
PRINT '';
PRINT '=== ORNEK ISTATISTIKLER ===';
PRINT '';

-- Cozunurluk dagılımı
PRINT 'Cozunurluk Dagilimi:';
SELECT 
    ISNULL(cozunurluk, 'Belirtilmemis') AS cozunurluk,
    COUNT(*) AS film_sayisi
FROM 
    vw_FilmDetayListesi
GROUP BY 
    cozunurluk
ORDER BY 
    film_sayisi DESC;
GO

-- Siniflandirma dagilimi
PRINT '';
PRINT 'Siniflandirma Dagilimi:';
SELECT 
    ISNULL(siniflandirma, 'Belirtilmemis') AS siniflandirma,
    COUNT(*) AS film_sayisi
FROM 
    vw_FilmDetayListesi
GROUP BY 
    siniflandirma
ORDER BY 
    film_sayisi DESC;
GO

-- Sifrelenme durumu
PRINT '';
PRINT 'Sifreleme Durumu:';
SELECT 
    CASE sifreli 
        WHEN 't' THEN 'Sifreli'
        WHEN 'f' THEN 'Sifresiz'
        ELSE 'Bilinmiyor'
    END AS durum,
    COUNT(*) AS film_sayisi
FROM 
    vw_FilmDetayListesi
GROUP BY 
    sifreli
ORDER BY 
    film_sayisi DESC;
GO
