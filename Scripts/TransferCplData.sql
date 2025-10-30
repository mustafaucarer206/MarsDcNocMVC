-- CPL tablosundan MSSQL'e veri aktarimi icin yardimci script
-- PostgreSQL'den manuel CSV export alip MSSQL'e import

USE [MarsDcNocMVC];
GO

-- Ornek CPL kayitlarini gormek icin
SELECT TOP 10
    uuid,
    content_title,
    content_kind,
    duration_in_seconds,
    rating,
    resolution,
    aspect_ratio,
    encrypted
FROM cpl
ORDER BY content_title;
GO

-- CPL_VALIDATION ile birlestirerek detayli bilgi
SELECT TOP 10
    c.uuid AS cpl_uuid,
    c.content_title AS film_adi,
    c.duration_in_seconds / 60.0 AS sure_dakika,
    c.rating AS siniflandirma,
    c.resolution AS cozunurluk,
    cv.device_uuid,
    cv.validated,
    cv.validation_type,
    cv.validation_message
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid
WHERE
    c.content_title IS NOT NULL
ORDER BY 
    c.content_title;
GO
