# PostgreSQL'den tum salonlari dogru sekilde ayirarak aktar
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

Write-Host "`n=== TUM SALONLARI DOGRU SEKILDE AYIRARAK AKTARILIYOR ===" -ForegroundColor Magenta

# Mevcut tabloyu temizle
Write-Host "Mevcut Movies tablosu temizleniyor..." -ForegroundColor Gray
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b 2>&1 | Out-Null

# Gelismis sorgu - cihaz adi olmasa bile salon bilgisini al
$query = @"
SELECT 
    COALESCE(c.content_title_text, c.content_title) as uzun_film_adi,
    c.content_title as kisa_film_adi,
    ROUND((c.duration_in_seconds / 60.0)::numeric, 2) as sure_dakika,
    ROUND((c.duration_in_seconds * 0.5 / 1024.0 / 1024.0 / 1024.0)::numeric, 2) as boyut_gb,
    COALESCE(c.content_kind, 'feature') as icerik_turu,
    COALESCE(d.name, '') as cihaz_adi,
    COALESCE(d.category, '') as cihaz_kategori,
    COALESCE(s.title, '') as salon_adi_ham,
    CASE 
        -- LMS ve Content cihazlari
        WHEN d.name = 'LMS' THEN 'LMS'
        WHEN d.name = 'DCP Online' THEN 'DCP Online'
        WHEN d.name = 'Qube Online' THEN 'Qube Online'
        WHEN d.name = 'DC_FTP' THEN 'DC FTP'
        WHEN d.name = 'Watchfolder' THEN 'Watchfolder'
        WHEN d.name = 'ingest' THEN 'Ingest'
        WHEN d.name = 'N:\' THEN 'Network Drive'
        WHEN d.category = 'content' THEN 'Content Server'
        WHEN d.category = 'lms' THEN 'LMS'
        WHEN d.category = 'external' THEN 'External Storage'
        WHEN d.category = 'pos' THEN 'POS System'
        
        -- Projector salonlari (cihaz adi var)
        WHEN d.name IS NOT NULL AND d.name != '' AND d.category = 'projector' AND s.title LIKE '%Solaria%SR1000%' THEN 'Projektor - Solaria SR1000'
        WHEN d.name IS NOT NULL AND d.name != '' AND d.category = 'projector' AND s.title LIKE '%Solaria%IMB%' THEN 'Projektor - Solaria IMB-S2'
        WHEN d.name IS NOT NULL AND d.name != '' AND d.category = 'projector' AND s.title LIKE '%CP2230U%' THEN 'Projektor - CP2230U IMB-S2'
        WHEN d.name IS NOT NULL AND d.name != '' AND d.category = 'projector' AND s.title LIKE '%CP2210%' THEN 'Projektor - CP2210 SR1000'
        WHEN d.name IS NOT NULL AND d.name != '' AND d.category = 'projector' AND s.title LIKE '%CP2220%' THEN 'Projektor - CP2220 SR1000'
        WHEN d.name IS NOT NULL AND d.name != '' AND d.category = 'projector' AND s.title LIKE '%CP2230%' THEN 'Projektor - CP2230 SR1000'
        WHEN d.name IS NOT NULL AND d.name != '' AND d.category = 'projector' THEN 'Projektor - Diger'
        
        -- SMS salonlari (cihaz adi YOK ama salon var)
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' AND s.title LIKE '%Solaria%IMB%' THEN 'SMS - Solaria IMB-S2'
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' AND s.title LIKE '%Solaria%SR1000%' THEN 'SMS - Solaria SR1000'
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' AND s.title LIKE '%Solaria/%SR1000%' THEN 'SMS - Solaria SR1000'
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' AND s.title LIKE '%CP2230U%' THEN 'SMS - CP2230U IMB-S2'
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' AND s.title LIKE '%CP2220%' THEN 'SMS - CP2220 SR1000'
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' AND s.title LIKE '%CP2210%' THEN 'SMS - CP2210 SR1000'
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' AND s.title LIKE '%CP2230%' THEN 'SMS - CP2230 SR1000'
        WHEN (d.name IS NULL OR d.name = '') AND d.category = 'sms' THEN 'SMS - Diger'
        
        -- Bilinmeyen
        ELSE 'Tanimsiz'
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
    c.content_title_text;
"@

Write-Host "PostgreSQL'den tum salon bilgileriyle filmler cekiliyor..." -ForegroundColor Gray
$filmData = & "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -t -A -F '|' -c $query 2>&1

$insertCount = 0
$batchSize = 50
$batch = @()

foreach ($row in $filmData) {
    if ($row -is [string] -and $row -match '\|') {
        try {
            $fields = $row -split '\|'
            
            $uzunFilmAdi = ($fields[0] -replace "'", "''").Trim()
            $kisaFilmAdi = ($fields[1] -replace "'", "''").Trim()
            $sure = if($fields[2] -and $fields[2] -ne '' -and $fields[2] -ne 'NULL'){[decimal]$fields[2]}else{0}
            $boyut = if($fields[3] -and $fields[3] -ne '' -and $fields[3] -ne 'NULL'){[decimal]$fields[3]}else{0}
            $tur = if($fields[4]){($fields[4] -replace "'", "''")}else{'feature'}
            $salon = if($fields[8]){($fields[8] -replace "'", "''")}else{'Tanimsiz'}
            
            $filmAdi = if($uzunFilmAdi -and $uzunFilmAdi.Length -gt 10) {$uzunFilmAdi} else {$kisaFilmAdi}
            
            if ($filmAdi -and $filmAdi.Length -gt 0) {
                $values = "(N'$filmAdi', $sure, $boyut, N'Cevahir', N'$salon', N'$tur')"
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
PRINT '=== TUM SALONLAR AYRILMIS HALDE ===';
SELECT SalonAdi, COUNT(*) AS FilmSayisi FROM Movies GROUP BY SalonAdi ORDER BY FilmSayisi DESC;
PRINT ''; PRINT 'Toplam:';
SELECT COUNT(*) AS ToplamFilm, COUNT(DISTINCT SalonAdi) AS ToplamSalon FROM Movies;
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

$env:PGPASSWORD = $null
Write-Host "`n=== TAMAMLANDI ===" -ForegroundColor Green
Write-Host "Artik SMS salonlari ayri ayri gorunuyor!" -ForegroundColor Cyan
