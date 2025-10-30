# PostgreSQL'den film verilerini cek ve MSSQL Movies tablosuna "Cevahir" lokasyonu ile ekle
param(
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432,
    [string]$PgUser = "postgres",
    [string]$PgPassword = "postgres",
    [string]$PgDatabase = "moviesbackup",
    [string]$MssqlServer = "(local)",
    [string]$MssqlDatabase = "MarsDcNocMVC",
    [string]$PgBinPath = "C:\Users\mustafa.ucarer\Downloads\postgresql-18.0-1-windows-x64-binaries\pgsql\bin",
    [int]$MaxFilms = 1000
)

$env:PGPASSWORD = $PgPassword
$psql = Join-Path $PgBinPath "psql.exe"

Write-Host "`n=== FILMLER AKTARILIYOR ===" -ForegroundColor Magenta
Write-Host "Lokasyon: Cevahir`n" -ForegroundColor Cyan

# PostgreSQL'den film, cihaz ve salon bilgilerini birlestirerek al
$query = @"
SELECT 
    c.content_title AS film_adi,
    c.duration_in_seconds::numeric / 60.0 AS sure_dakika,
    CASE 
        WHEN c.duration_in_seconds IS NOT NULL THEN (c.duration_in_seconds::numeric * 0.5 / 1024.0 / 1024.0 / 1024.0)
        ELSE NULL
    END AS boyut_gb_tahmini,
    c.resolution,
    c.rating AS siniflandirma,
    c.encrypted,
    c.audio_language,
    c.subtitle_language,
    c.aspect_ratio,
    COALESCE(c.edit_rate_a || '/' || c.edit_rate_b, '') AS frame_rate,
    c.content_kind AS icerik_turu,
    d.name AS cihaz_adi,
    s.name AS salon_adi
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid
    LEFT JOIN device d ON cv.device_uuid = d.uuid
    LEFT JOIN screen s ON d.screen_uuid = s.uuid
WHERE 
    c.content_title IS NOT NULL 
    AND c.content_title != ''
ORDER BY 
    c.content_title
LIMIT $MaxFilms;
"@

Write-Host "Film verileri PostgreSQL'den cekiliyİor..." -ForegroundColor Gray

$filmData = & "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -t -A -F '|' -c $query 2>&1

$insertCount = 0
$errorCount = 0
$batchSize = 20
$batch = @()

foreach ($row in $filmData) {
    if ($row -is [string] -and $row -match '\|') {
        try {
            $fields = $row -split '\|'
            
            $filmAdi = ($fields[0] -replace "'", "''").Trim()
            $sure = if($fields[1]){[decimal]$fields[1]}else{0}
            $boyut = if($fields[2]){[decimal]$fields[2]}else{0}
            $cozunurluk = if($fields[3]){($fields[3] -replace "'", "''")}else{''}
            $sinif = if($fields[4]){($fields[4] -replace "'", "''")}else{''}
            $sifreli = if($fields[5] -eq 't'){1}else{0}
            $sesDili = if($fields[6]){($fields[6] -replace "'", "''")}else{''}
            $altyazi = if($fields[7]){($fields[7] -replace "'", "''")}else{''}
            $enBoy = if($fields[8]){($fields[8] -replace "'", "''")}else{''}
            $frameRate = if($fields[9]){($fields[9] -replace "'", "''")}else{''}
            $tur = if($fields[10]){($fields[10] -replace "'", "''")}else{'feature'}
            $cihaz = if($fields[11]){($fields[11] -replace "'", "''")}else{''}
            $salon = if($fields[12]){($fields[12] -replace "'", "''")}else{''}
            
            if ($filmAdi) {
                $values = @"
(N'$filmAdi', $sure, $boyut, $(if($cozunurluk){"N'$cozunurluk'"}else{'NULL'}), $(if($sinif){"N'$sinif'"}else{'NULL'}), N'Cevahir', $(if($cihaz){"N'$cihaz'"}else{'NULL'}), $(if($salon){"N'$salon'"}else{'NULL'}), $sifreli, $(if($sesDili){"N'$sesDili'"}else{'NULL'}), $(if($altyazi){"N'$altyazi'"}else{'NULL'}), $(if($enBoy){"N'$enBoy'"}else{'NULL'}), $(if($frameRate){"N'$frameRate'"}else{'NULL'}), $(if($tur){"N'$tur'"}else{'NULL'}))
"@
                $batch += $values
            }
            
            if ($batch.Count -ge $batchSize) {
                $insertSql = @"
USE [$MssqlDatabase];
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Cozunurluk, Siniflandirma, Lokasyon, CihazAdi, SalonAdi, Sifreli, SesDili, AltyaziDili, EnBoyOrani, FrameRate, IcerikTuru)
VALUES $($batch -join ',');
"@
                sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { 
                    $insertCount += $batch.Count 
                } else {
                    $errorCount += $batch.Count
                }
                $batch = @()
                Write-Host "`rAktariliyor: $insertCount film..." -NoNewline -ForegroundColor Green
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
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Cozunurluk, Siniflandirma, Lokasyon, CihazAdi, SalonAdi, Sifreli, SesDili, AltyaziDili, EnBoyOrani, FrameRate, IcerikTuru)
VALUES $($batch -join ',');
"@
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $insertCount += $batch.Count }
}

Write-Host "`r`n"
Write-Host "=== AKTARIM TAMAMLANDI ===" -ForegroundColor Green
Write-Host "  Basarili: $insertCount film" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "  Hata: $errorCount film" -ForegroundColor Yellow
}

# Ozet bilgi
Write-Host "`n=== MOVIES TABLOSU OZET ===" -ForegroundColor Cyan

$summarySql = @"
USE [$MssqlDatabase];

SELECT 
    Lokasyon,
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT SalonAdi) AS SalonSayisi,
    COUNT(DISTINCT CihazAdi) AS CihazSayisi,
    SUM(CASE WHEN Sifreli = 1 THEN 1 ELSE 0 END) AS SifreliFilmler,
    AVG(Sure_Dakika) AS OrtalamaSure,
    SUM(Boyut_GB) AS ToplamBoyut_GB
FROM Movies
GROUP BY Lokasyon;

PRINT '';
PRINT 'Ilk 10 Film:';
SELECT TOP 10 
    FilmAdi, 
    Sure_Dakika, 
    CAST(Boyut_GB AS DECIMAL(10,2)) AS Boyut_GB,
    Cozunurluk,
    Lokasyon,
    SalonAdi,
    CihazAdi
FROM Movies 
ORDER BY FilmAdi;
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

$env:PGPASSWORD = $null

Write-Host "`n=== KULLANIMA HAZIR ===" -ForegroundColor Green
Write-Host "Movies tablosu Cevahir lokasyonu ile dolduruldu!" -ForegroundColor Cyan
Write-Host "`nSonraki adim: Web arayuzu ekle" -ForegroundColor Yellow
Write-Host "  Controller: MoviesController.cs" -ForegroundColor Gray
Write-Host "  View: Views/Movies/Index.cshtml" -ForegroundColor Gray
