# PostgreSQL'den tum feature filmleri uzun DCP adlariyla cek ve MSSQL'e aktar
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

Write-Host "`n=== TUM FEATURE FILMLER UZUN DCP ADLARIYLA AKTARILIYOR ===" -ForegroundColor Magenta
Write-Host "Hedef: 2,162 feature film + 30 cihaz bilgisi`n" -ForegroundColor Cyan

# Mevcut tabloyu temizle
Write-Host "Mevcut Movies tablosu temizleniyor..." -ForegroundColor Gray
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b 2>&1 | Out-Null

# PostgreSQL'den tum feature filmleri uzun adlarla al
$query = @"
SELECT 
    COALESCE(c.content_title_text, c.content_title) as uzun_film_adi,
    c.content_title as kisa_film_adi,
    ROUND((c.duration_in_seconds / 60.0)::numeric, 2) as sure_dakika,
    ROUND((c.duration_in_seconds * 0.5 / 1024.0 / 1024.0 / 1024.0)::numeric, 2) as boyut_gb,
    COALESCE(c.content_kind, 'feature') as icerik_turu,
    COALESCE(d.name, 'Belirtilmemiş') as cihaz_adi,
    COALESCE(s.title, 'Belirtilmemiş') as salon_adi_ham,
    CASE 
        WHEN d.name = 'LMS' THEN 'DcpOnline'
        WHEN s.title LIKE '%Solaria%SR1000%' OR s.title LIKE '%SR1000%' THEN 'Salon 1'
        WHEN s.title LIKE '%Solaria%IMB%' OR s.title LIKE '%IMB%' THEN 'Salon 2'
        WHEN s.title LIKE '%CP2230U%' THEN 'Salon 3'
        WHEN s.title LIKE '%CP2210%' THEN 'Salon 4'
        WHEN s.title LIKE '%CP2220%' THEN 'Salon 5'
        WHEN s.title LIKE '%CP2230%' THEN 'Salon 6'
        WHEN d.name = 'LMS' THEN 'DcpOnline'
        WHEN d.category = 'projector' THEN 'Salon 7'
        WHEN d.category = 'content' THEN 'DcpOnline'
        ELSE 'Salon 8'
    END as salon_adi
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
    c.content_title_text;
"@

Write-Host "PostgreSQL'den feature filmler cekiliyor..." -ForegroundColor Gray
$filmData = & "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -t -A -F '|' -c $query 2>&1

$insertCount = 0
$errorCount = 0
$batchSize = 50
$batch = @()
$totalExpected = 2162

foreach ($row in $filmData) {
    if ($row -is [string] -and $row -match '\|') {
        try {
            $fields = $row -split '\|'
            
            $uzunFilmAdi = ($fields[0] -replace "'", "''").Trim()
            $kisaFilmAdi = ($fields[1] -replace "'", "''").Trim()
            $sure = if($fields[2] -and $fields[2] -ne '' -and $fields[2] -ne 'NULL'){[decimal]$fields[2]}else{0}
            $boyut = if($fields[3] -and $fields[3] -ne '' -and $fields[3] -ne 'NULL'){[decimal]$fields[3]}else{0}
            $tur = if($fields[4]){($fields[4] -replace "'", "''")}else{'feature'}
            $cihaz = if($fields[5]){($fields[5] -replace "'", "''")}else{'Belirtilmemiş'}
            $salonHam = if($fields[6]){($fields[6] -replace "'", "''")}else{'Belirtilmemiş'}
            $salon = if($fields[7]){($fields[7] -replace "'", "''")}else{'Salon 8'}
            
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
                $progress = [math]::Round(($insertCount / $totalExpected) * 100, 1)
                Write-Host "`r$insertCount/$totalExpected film eklendi (%$progress)..." -NoNewline -ForegroundColor Green
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

# Final istatistikler
$summarySql = @"
USE [$MssqlDatabase];

PRINT '=== UZUN DCP ADLARIYLA MOVIES TABLOSU ===';
PRINT '';

SELECT 
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT SalonAdi) AS FarkliSalon,
    AVG(Sure_Dakika) AS OrtSure,
    SUM(Boyut_GB) AS TopBoyut
FROM Movies;

PRINT '';
PRINT 'Salonlara Gore Dagilim:';
SELECT 
    SalonAdi, 
    COUNT(*) AS FilmSayisi,
    CAST(AVG(Sure_Dakika) AS DECIMAL(10,1)) AS OrtSure
FROM Movies 
GROUP BY SalonAdi 
ORDER BY FilmSayisi DESC;

PRINT '';
PRINT 'Uzun DCP Adlari Ornekleri:';
SELECT TOP 10 
    LEFT(FilmAdi, 80) + '...' AS FilmAdi_Ornek,
    Sure_Dakika, 
    SalonAdi
FROM Movies 
WHERE LEN(FilmAdi) > 50
ORDER BY LEN(FilmAdi) DESC;

PRINT '';
PRINT 'En Uzun Film Adlari:';
SELECT TOP 5
    LEN(FilmAdi) AS AdUzunlugu,
    LEFT(FilmAdi, 100) AS FilmAdi
FROM Movies
ORDER BY LEN(FilmAdi) DESC;
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

$env:PGPASSWORD = $null

Write-Host "`n=== TAMAMLANDI ===" -ForegroundColor Green
Write-Host "$insertCount film uzun DCP adlariyla aktarildi!" -ForegroundColor Cyan
Write-Host "Ornek: 488-15954-DS-DAMAT-BABALAR-GUNU_ADV-1-2D_F_TR-XX_20_2K_20250611_MARS_OV" -ForegroundColor Yellow
Write-Host "http://localhost:5032/Movies adresinden kontrol edebilirsiniz!" -ForegroundColor Yellow
