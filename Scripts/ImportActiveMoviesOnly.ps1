# Sadece aktif (son 3 ay içinde güncellenen) filmleri aktar
param(
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432,
    [string]$PgUser = "postgres",
    [string]$PgPassword = "postgres",
    [string]$PgDatabase = "moviesbackup",
    [string]$MssqlServer = "(local)",
    [string]$MssqlDatabase = "MarsDcNocMVC",
    [string]$PgBinPath = "C:\Users\mustafa.ucarer\Downloads\postgresql-18.0-1-windows-x64-binaries\pgsql\bin",
    [int]$ActiveDaysThreshold = 90
)

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    Write-Host $Message -ForegroundColor $color
}

$env:PGPASSWORD = $PgPassword
$psql = Join-Path $PgBinPath "psql.exe"

try {
    Write-Log "`n=== SADECE AKTIF CONTENT SERVER FILMLERI AKTARILIYOR ===" "INFO"
    Write-Log "Son $ActiveDaysThreshold gun icinde guncellenen filmler..." "INFO"
    
    # Threshold timestamp hesapla (Unix timestamp)
    $thresholdDate = (Get-Date).AddDays(-$ActiveDaysThreshold)
    $thresholdTimestamp = [int][double]::Parse((Get-Date -Date $thresholdDate -UFormat %s))
    
    Write-Log "Threshold Tarih: $($thresholdDate.ToString('dd.MM.yyyy HH:mm'))" "INFO"
    Write-Log "Threshold Timestamp: $thresholdTimestamp`n" "INFO"
    
    # Mevcut tabloyu temizle
    Write-Log "Mevcut Movies tablosu temizleniyor..." "INFO"
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b 2>&1 | Out-Null
    Write-Log "OK: Movies tablosu temizlendi.`n" "SUCCESS"
    
    Write-Log "PostgreSQL'den aktif filmler cekiliyor..." "INFO"
    
    # Sadece aktif (son güncellenmiş) feature filmleri çek
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
    END as salon_adi,
    c.last_updated
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid
    LEFT JOIN device d ON cv.device_uuid = d.uuid
WHERE 
    c.content_kind = 'feature'
    AND c.content_title_text IS NOT NULL
    AND c.content_title_text != ''
    AND c.last_updated >= $thresholdTimestamp
    AND (
        d.name IN ('LMS', 'DCP Online', 'Qube Online', 'DC_FTP', 'Watchfolder', 'ingest')
        OR d.category IN ('content', 'lms')
    )
ORDER BY 
    c.last_updated DESC, c.content_title_text;
"@
    
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
                $lastUpdated = if($fields[4]){$fields[4]}else{0}
                
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
    
    Write-Log "`r`n=== AKTARIM TAMAMLANDI ===" "SUCCESS"
    Write-Log "  Basarili: $insertCount aktif film`n" "SUCCESS"
    
    # Duplicate temizle
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "USE [$MssqlDatabase]; WITH DuplicateMovies AS (SELECT Id, ROW_NUMBER() OVER (PARTITION BY FilmAdi, SalonAdi ORDER BY Id) as rn FROM Movies) DELETE FROM Movies WHERE Id IN (SELECT Id FROM DuplicateMovies WHERE rn > 1);" -b 2>&1 | Out-Null
    
    # Tüm lokasyonlara kopyala
    Write-Log "Diger lokasyonlara kopyalaniyor..." "INFO"
    $copySql = @"
USE [$MssqlDatabase];
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru, EklenmeTarihi)
SELECT 
    m.FilmAdi,
    m.Sure_Dakika,
    m.Boyut_GB,
    l.Name AS Lokasyon,
    m.SalonAdi,
    m.IcerikTuru,
    GETDATE() AS EklenmeTarihi
FROM 
    Movies m
    CROSS JOIN (SELECT DISTINCT Name FROM Locations WHERE Name != 'Cevahir') l
WHERE 
    m.Lokasyon = 'Cevahir';
"@
    
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $copySql -b 2>&1 | Out-Null
    Write-Log "OK: Tum lokasyonlara kopyalandi.`n" "SUCCESS"
    
    # Sonuç
    $summarySql = @"
USE [$MssqlDatabase];
SELECT 
    COUNT(*) AS ToplamFilm, 
    COUNT(DISTINCT FilmAdi) AS BenzersizFilm,
    COUNT(DISTINCT SalonAdi) AS ContentServerSayisi,
    COUNT(DISTINCT Lokasyon) AS LokasyonSayisi
FROM Movies;
SELECT SalonAdi, COUNT(DISTINCT FilmAdi) AS BenzersizFilm FROM Movies WHERE Lokasyon = 'Cevahir' GROUP BY SalonAdi ORDER BY BenzersizFilm DESC;
"@
    
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W
    
    $env:PGPASSWORD = $null
    Write-Log "`n=== TAMAMLANDI ===" "SUCCESS"
    Write-Log "Sadece aktif (son $ActiveDaysThreshold gun icinde guncellenen) filmler yuklendi!" "INFO"
    Write-Log "http://localhost:5032/Movies adresinden kontrol edebilirsiniz!" "INFO"
    
} catch {
    Write-Log "HATA: $_" "ERROR"
    exit 1
}

