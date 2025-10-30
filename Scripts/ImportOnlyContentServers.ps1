# Sadece Content Server'lari (LMS, DCP Online, Qube Online, DC FTP) aktar
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

Write-Host "`n=== SADECE CONTENT SERVER'LARI AKTARILIYOR ===" -ForegroundColor Magenta
Write-Host "LMS, DCP Online, Qube Online, DC FTP`n" -ForegroundColor Cyan

# Mevcut tabloyu temizle
Write-Host "Mevcut Movies tablosu temizleniyor..." -ForegroundColor Gray
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b 2>&1 | Out-Null

# Sadece content server'lari cek
$query = @"
SELECT 
    COALESCE(c.content_title_text, c.content_title) as film_adi,
    ROUND((c.duration_in_seconds / 60.0)::numeric, 2) as sure_dakika,
    COALESCE(c.content_kind, 'feature') as icerik_turu,
    CASE 
        WHEN d.name = 'LMS' THEN 'LMS'
        WHEN d.name = 'DCP Online' THEN 'DCP Online'
        WHEN d.name = 'Qube Online' THEN 'Qube Online'
        WHEN d.name = 'DC_FTP' THEN 'DC FTP'
        WHEN d.name = 'Watchfolder' THEN 'Watchfolder'
        WHEN d.name = 'ingest' THEN 'Ingest'
        WHEN d.category = 'content' THEN 'Content Server'
        WHEN d.category = 'lms' THEN 'LMS'
        ELSE NULL
    END as salon_adi
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid
    LEFT JOIN device d ON cv.device_uuid = d.uuid
WHERE 
    c.content_kind = 'feature'
    AND c.content_title_text IS NOT NULL
    AND c.content_title_text != ''
    AND (
        d.name IN ('LMS', 'DCP Online', 'Qube Online', 'DC_FTP', 'Watchfolder', 'ingest')
        OR d.category IN ('content', 'lms')
    )
ORDER BY 
    c.content_title_text;
"@

Write-Host "PostgreSQL'den sadece content server'lardaki filmler cekiliyor..." -ForegroundColor Gray
$filmData = & "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -t -A -F '|' -c $query 2>&1

$insertCount = 0
$batchSize = 50
$batch = @()

foreach ($row in $filmData) {
    if ($row -is [string] -and $row -match '\|') {
        try {
            $fields = $row -split '\|'
            
            $filmAdi = ($fields[0] -replace "'", "''").Trim()
            $sure = if($fields[1] -and $fields[1] -ne '' -and $fields[1] -ne 'NULL'){[decimal]$fields[1]}else{0}
            $tur = if($fields[2]){($fields[2] -replace "'", "''")}else{'feature'}
            $salon = if($fields[3]){($fields[3] -replace "'", "''")}else{$null}
            
            if ($filmAdi -and $filmAdi.Length -gt 0 -and $salon) {
                $values = "(N'$filmAdi', $sure, 0, N'Cevahir', N'$salon', N'$tur')"
                $batch += $values
            }
            
            if ($batch.Count -ge $batchSize) {
                $insertSql = "USE [$MssqlDatabase]; INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru) VALUES $($batch -join ',');"
                sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $insertCount += $batch.Count }
                $batch = @()
                Write-Host "`r$insertCount film eklendi..." -NoNewline -ForegroundColor Green
            }
        } catch { }
    }
}

# Son batch
if ($batch.Count -gt 0) {
    $insertSql = "USE [$MssqlDatabase]; INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru) VALUES $($batch -join ',');"
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $insertCount += $batch.Count }
}

Write-Host "`r`n=== AKTARIM TAMAMLANDI ===" -ForegroundColor Green
Write-Host "  Basarili: $insertCount film`n" -ForegroundColor Green

# Duplicate temizle
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "USE [$MssqlDatabase]; WITH DuplicateMovies AS (SELECT Id, ROW_NUMBER() OVER (PARTITION BY FilmAdi, SalonAdi ORDER BY Id) as rn FROM Movies) DELETE FROM Movies WHERE Id IN (SELECT Id FROM DuplicateMovies WHERE rn > 1);" -b 2>&1 | Out-Null

# Sonuc
$summarySql = @"
USE [$MssqlDatabase];
PRINT '=== SADECE CONTENT SERVER'LAR ===';
SELECT SalonAdi, COUNT(*) AS FilmSayisi FROM Movies GROUP BY SalonAdi ORDER BY FilmSayisi DESC;
PRINT ''; PRINT 'Toplam:';
SELECT COUNT(*) AS ToplamFilm, COUNT(DISTINCT SalonAdi) AS ToplamSalon FROM Movies;
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

$env:PGPASSWORD = $null
Write-Host "`n=== TAMAMLANDI ===" -ForegroundColor Green
Write-Host "Sadece LMS, DCP Online, Qube Online, DC FTP server'lardaki filmler yuklendi!" -ForegroundColor Cyan
