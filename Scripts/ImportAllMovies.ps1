# PostgreSQL'den tum feature filmleri cek ve MSSQL'e aktar
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

Write-Host "`n=== TUM FEATURE FILMLER AKTARILIYOR ===" -ForegroundColor Magenta
Write-Host "Hedef: 2,162 film`n" -ForegroundColor Cyan

# Mevcut tabloyu temizle
Write-Host "Mevcut Movies tablosu temizleniyor..." -ForegroundColor Gray
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b 2>&1 | Out-Null

# PostgreSQL'den tum feature filmleri al
$query = @"
SELECT 
    c.content_title,
    ROUND((c.duration_in_seconds / 60.0)::numeric, 2) as sure_dakika,
    ROUND((c.duration_in_seconds * 0.5 / 1024.0 / 1024.0 / 1024.0)::numeric, 2) as boyut_gb,
    COALESCE(c.content_kind, 'feature') as icerik_turu,
    CASE 
        WHEN d.name = 'LMS' THEN 'DcpOnline'
        WHEN s.title LIKE '%Solaria%SR1000%' OR s.title LIKE '%SR1000%' THEN 'Salon 1'
        WHEN s.title LIKE '%Solaria%IMB%' OR s.title LIKE '%IMB%' THEN 'Salon 2'
        WHEN s.title LIKE '%CP2230U%' THEN 'Salon 3'
        WHEN s.title LIKE '%CP2210%' THEN 'Salon 4'
        WHEN s.title LIKE '%CP2220%' THEN 'Salon 5'
        ELSE 'Salon 6'
    END as salon_adi
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid
    LEFT JOIN device d ON cv.device_uuid = d.uuid
    LEFT JOIN screen s ON d.screen_uuid = s.uuid
WHERE 
    c.content_title IS NOT NULL 
    AND c.content_title != ''
    AND c.content_kind = 'feature'
ORDER BY 
    c.content_title;
"@

Write-Host "PostgreSQL'den 2,162 film cekiliyor..." -ForegroundColor Gray
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
            
            $filmAdi = ($fields[0] -replace "'", "''").Trim()
            $sure = if($fields[1] -and $fields[1] -ne '' -and $fields[1] -ne 'NULL'){[decimal]$fields[1]}else{0}
            $boyut = if($fields[2] -and $fields[2] -ne '' -and $fields[2] -ne 'NULL'){[decimal]$fields[2]}else{0}
            $tur = if($fields[3]){($fields[3] -replace "'", "''")}else{'feature'}
            $salon = if($fields[4]){($fields[4] -replace "'", "''")}else{'Salon 6'}
            
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

PRINT '=== FINAL MOVIES TABLOSU OZET ===';
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
    CAST(AVG(Sure_Dakika) AS DECIMAL(10,1)) AS OrtSure,
    CAST(SUM(Boyut_GB) AS DECIMAL(10,2)) AS TopBoyut
FROM Movies 
GROUP BY SalonAdi 
ORDER BY FilmSayisi DESC;

PRINT '';
PRINT 'En Uzun Filmler:';
SELECT TOP 10 
    FilmAdi, 
    Sure_Dakika, 
    SalonAdi
FROM Movies 
WHERE Sure_Dakika > 0
ORDER BY Sure_Dakika DESC;
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

$env:PGPASSWORD = $null

Write-Host "`n=== TAMAMLANDI ===" -ForegroundColor Green
Write-Host "$insertCount film basariyla aktarildi!" -ForegroundColor Cyan
Write-Host "http://localhost:5032/Movies adresinden kontrol edebilirsiniz!" -ForegroundColor Yellow
