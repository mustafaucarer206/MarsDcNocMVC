# PostgreSQL'den tum cihaz ve salon kombinasyonlariyla filmleri aktar
param(
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432,
    [string]$PgUser = "postgres",
    [string]$PgPassword = "postgres",
    [string]$PgDatabase = "moviesbackup",
    [string]$MssqlServer = "(local)",
    [string]$MssqlDatabase = "MarsDcNocMVC",
    [string]$PgBinPath = "C:\Users\mustafa.ucarer\Downloads\postgresql-18.0-1-windows-x64-binaries\pgsql\bin"
)

$env:PGPASSWORD = $PgPassword
$psql = Join-Path $PgBinPath "psql.exe"

Write-Host "`n=== TUM CIHAZ VE SALONLARLA FILMLER AKTARILIYOR ===" -ForegroundColor Magenta
Write-Host "Tum device ve screen kombinasyonlari dahil`n" -ForegroundColor Cyan

# Mevcut tabloyu temizle
Write-Host "Mevcut Movies tablosu temizleniyor..." -ForegroundColor Gray
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b 2>&1 | Out-Null

# PostgreSQL'den gelismis sorgu - tum cihaz ve salon kombinasyonlari
$query = @"
SELECT 
    COALESCE(c.content_title_text, c.content_title) as uzun_film_adi,
    c.content_title as kisa_film_adi,
    ROUND((c.duration_in_seconds / 60.0)::numeric, 2) as sure_dakika,
    ROUND((c.duration_in_seconds * 0.5 / 1024.0 / 1024.0 / 1024.0)::numeric, 2) as boyut_gb,
    COALESCE(c.content_kind, 'feature') as icerik_turu,
    COALESCE(d.name, 'Bilinmeyen') as cihaz_adi,
    COALESCE(d.category, 'unknown') as cihaz_kategori,
    COALESCE(s.title, 'Bilinmeyen') as salon_adi_ham,
    CASE 
        -- Content cihazlari
        WHEN d.name = 'LMS' THEN 'LMS Server'
        WHEN d.name = 'DCP Online' THEN 'DCP Online'
        WHEN d.name = 'Qube Online' THEN 'Qube Online'
        WHEN d.name = 'DC_FTP' THEN 'DC FTP'
        WHEN d.name = 'Watchfolder' THEN 'Watchfolder'
        WHEN d.name = 'ingest' THEN 'Ingest Server'
        WHEN d.name = 'N:\' THEN 'Network Drive'
        WHEN d.category = 'content' THEN 'Content Server'
        WHEN d.category = 'lms' THEN 'LMS Server'
        WHEN d.category = 'external' THEN 'External Storage'
        WHEN d.category = 'pos' THEN 'POS System'
        -- Projector ve SMS salonlari
        WHEN s.title LIKE '%Solaria%SR1000%' OR s.title LIKE '%SR1000%' THEN 'Salon 1 (SR1000)'
        WHEN s.title LIKE '%Solaria%IMB%' OR s.title LIKE '%IMB-S2%' THEN 'Salon 2 (IMB-S2)'
        WHEN s.title LIKE '%CP2230U%' THEN 'Salon 3 (CP2230U)'
        WHEN s.title LIKE '%CP2210%' THEN 'Salon 4 (CP2210)'
        WHEN s.title LIKE '%CP2220%' THEN 'Salon 5 (CP2220)'
        WHEN s.title LIKE '%CP2230%' THEN 'Salon 6 (CP2230)'
        WHEN d.category = 'projector' THEN 'Projektor Salonu'
        WHEN d.category = 'sms' THEN 'SMS Salonu'
        ELSE 'Diger Salon'
    END as salon_adi_temiz
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid
    LEFT JOIN device d ON cv.device_uuid = d.uuid
    LEFT JOIN screen s ON d.screen_uuid = s.uuid
WHERE 
    c.content_kind = 'feature'
    AND c.content_title_text IS NOT NULL
    AND c.content_title_text != ''
ORDER BY 
    c.content_title_text, d.name, s.title;
"@

Write-Host "PostgreSQL'den tum cihaz-salon kombinasyonlariyla filmler cekiliyor..." -ForegroundColor Gray
$filmData = & "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -t -A -F '|' -c $query 2>&1

$insertCount = 0
$errorCount = 0
$batchSize = 50
$batch = @()
$totalExpected = 5000

foreach ($row in $filmData) {
    if ($row -is [string] -and $row -match '\|') {
        try {
            $fields = $row -split '\|'
            
            $uzunFilmAdi = ($fields[0] -replace "'", "''").Trim()
            $kisaFilmAdi = ($fields[1] -replace "'", "''").Trim()
            $sure = if($fields[2] -and $fields[2] -ne '' -and $fields[2] -ne 'NULL'){[decimal]$fields[2]}else{0}
            $boyut = if($fields[3] -and $fields[3] -ne '' -and $fields[3] -ne 'NULL'){[decimal]$fields[3]}else{0}
            $tur = if($fields[4]){($fields[4] -replace "'", "''")}else{'feature'}
            $cihaz = if($fields[5]){($fields[5] -replace "'", "''")}else{'Bilinmeyen'}
            $kategori = if($fields[6]){($fields[6] -replace "'", "''")}else{'unknown'}
            $salonHam = if($fields[7]){($fields[7] -replace "'", "''")}else{'Bilinmeyen'}
            $salon = if($fields[8]){($fields[8] -replace "'", "''")}else{'Diger Salon'}
            
            # Uzun film adini kullan, yoksa kisa adi kullan
            $filmAdi = if($uzunFilmAdi -and $uzunFilmAdi.Length -gt 10) {$uzunFilmAdi} else {$kisaFilmAdi}
            
            if ($filmAdi -and $filmAdi.Length -gt 0) {
                $values = "(N'$filmAdi', $sure, $boyut, N'Cevahir', N'$salon', N'$tur')"
                $batch += $values
            }
            
            if ($batch.Count -ge $batchSize) {
                $insertSql = @"
USE [$MssqlDatabase];
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru)
VALUES $($batch -join ',');
"@
                try {
                    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) { 
                        $insertCount += $batch.Count 
                    } else {
                        $errorCount += $batch.Count
                    }
                } catch {
                    $errorCount += $batch.Count
                }
                $batch = @()
                Write-Host "`r$insertCount film eklendi..." -NoNewline -ForegroundColor Green
            }
        } catch {
            $errorCount++
        }
    }
}

# Son batch'i ekle
if ($batch.Count -gt 0) {
    $insertSql = @"
USE [$MssqlDatabase];
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru)
VALUES $($batch -join ',');
"@
    try {
        sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $insertCount += $batch.Count }
    } catch {
        $errorCount += $batch.Count
    }
}

Write-Host "`r`n"
Write-Host "=== AKTARIM TAMAMLANDI ===" -ForegroundColor Green
Write-Host "  Basarili: $insertCount film" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "  Hata: $errorCount film" -ForegroundColor Yellow
}

# Duplicate'lari temizle
Write-Host "`nDuplicate'lar temizleniyor..." -ForegroundColor Gray
$cleanupSql = @"
USE [$MssqlDatabase];

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
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $cleanupSql -b 2>&1 | Out-Null

# Final istatistikler
$summarySql = @"
USE [$MssqlDatabase];

PRINT '=== TUM CIHAZ VE SALONLARLA MOVIES TABLOSU ===';
PRINT '';

SELECT 
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT SalonAdi) AS FarkliSalon,
    COUNT(DISTINCT FilmAdi) AS FarkliFilm,
    AVG(Sure_Dakika) AS OrtSure
FROM Movies;

PRINT '';
PRINT 'Salonlara Gore Dagilim (Tum Cihazlar):';
SELECT 
    SalonAdi, 
    COUNT(*) AS FilmSayisi,
    CAST(AVG(Sure_Dakika) AS DECIMAL(10,1)) AS OrtSure
FROM Movies 
GROUP BY SalonAdi 
ORDER BY FilmSayisi DESC;

PRINT '';
PRINT 'Yeni Salon Ornekleri:';
SELECT TOP 15
    LEFT(FilmAdi, 50) + '...' AS FilmAdi_Ornek,
    SalonAdi
FROM Movies 
WHERE SalonAdi NOT IN ('Salon 1', 'Salon 2', 'Salon 8', 'DcpOnline')
ORDER BY SalonAdi, FilmAdi;
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

$env:PGPASSWORD = $null

Write-Host "`n=== TAMAMLANDI ===" -ForegroundColor Green
Write-Host "$insertCount film tum cihaz ve salonlarla aktarildi!" -ForegroundColor Cyan
Write-Host "Artik LMS Server, DCP Online, Qube Online, Projektor Salonlari vs. gorunecek!" -ForegroundColor Yellow
Write-Host "http://localhost:5032/Movies adresinden kontrol edebilirsiniz!" -ForegroundColor Yellow
